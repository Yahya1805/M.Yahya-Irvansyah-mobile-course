import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../domain/entities/note.dart';
import '../../domain/failures/failure.dart';
import '../providers/notes_providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final input = await showDialog<({String title, String body})>(
      context: context,
      builder: (context) => const _NoteDialog(),
    );
    if (input == null || !context.mounted) return;

    final result = await ref
        .read(addNoteProvider)
        .call(title: input.title, body: input.body);
    if (!context.mounted) return;

    if (result.failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.failure!.message)));
      return;
    }
    ref.invalidate(notesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan')),
      // Body memakai widget const. Saat state berubah, Flutter tidak perlu
      // membangun ulang subtree body dari awal; hanya panel daftar yang
      // mendengarkan provider lewat select.
      body: const _NotesBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref),
        tooltip: 'Tambah catatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NotesBody extends ConsumerWidget {
  const _NotesBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(
        message: err is Failure
            ? err.message
            : 'Gagal memuat catatan. Silakan coba lagi.',
        onRetry: () => ref.invalidate(notesProvider),
      ),
      // Subtree ini const sehingga rebuild dari perubahan state tidak
      // membangun ulang search bar maupun panel daftar.
      data: (_) => const Column(
        children: [
          _SearchBar(),
          Expanded(child: _NotesListPanel()),
        ],
      ),
    );
  }
}

/// Panel daftar catatan yang hanya mendengarkan bagian state yang dipakai.
///
/// Dengan `select`, perubahan `isLoadingMore` atau field lain tidak memicu
/// rebuild panel selama daftar catatan, query, dan `hasMore` tidak berubah.
class _NotesListPanel extends ConsumerStatefulWidget {
  const _NotesListPanel();

  @override
  ConsumerState<_NotesListPanel> createState() => _NotesListPanelState();
}

class _NotesListPanelState extends ConsumerState<_NotesListPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _requestedNextPage = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Infinite scroll: muat halaman berikutnya saat pengguna berada ~200 px
  /// dari dasar list, bukan menunggu item terakhir benar-benar terlihat.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _requestNextPage();
    }
  }

  Future<void> _loadMore() async {
    try {
      await ref.read(notesProvider.notifier).loadMore();
    } catch (error) {
      if (!mounted) return;
      final message = error is Failure
          ? error.message
          : 'Gagal memuat catatan berikutnya.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _editNote(Note note) async {
    final input = await showDialog<({String title, String body})>(
      context: context,
      builder: (context) => _NoteDialog(note: note),
    );
    if (input == null || !mounted || note.id == null) return;

    final failure = await ref
        .read(updateNoteProvider)
        .call(id: note.id!, title: input.title, body: input.body);
    if (!mounted) return;

    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    ref.invalidate(notesProvider);
  }

  Future<void> _deleteNote(Note note) async {
    if (note.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(title: note.title),
    );
    if (confirmed != true || !mounted) return;

    final failure = await ref.read(deleteNoteProvider).call(note.id!);
    if (!mounted) return;

    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    ref.invalidate(notesProvider);
  }

  void _requestNextPage() {
    if (_requestedNextPage) return;
    _requestedNextPage = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(
      notesProvider.select((state) => state.value?.notes),
    );
    final query = ref.watch(
      notesProvider.select((state) => state.value?.query ?? ''),
    );
    final hasMore = ref.watch(
      notesProvider.select((state) => state.value?.hasMore ?? false),
    );

    // Daftar diganti (query berubah / refresh), izinkan request halaman lagi.
    ref.listen<List<Note>?>(
      notesProvider.select((state) => state.value?.notes),
      (previous, next) {
        if (!identical(previous, next)) _requestedNextPage = false;
      },
    );

    if (notes == null) return const SizedBox.shrink();
    if (notes.isEmpty) {
      return query.isEmpty
          ? const Center(child: Text('Belum ada catatan.'))
          : _EmptySearchState(query: query);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: notes.length + (hasMore ? 1 : 0),
      // Keep-alive tidak diperlukan untuk daftar pendek; mematikan fitur ini
      // mengurangi jumlah widget yang disimpan di memori saat scroll.
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index) {
        if (index >= notes.length) {
          // Fallback untuk layar tinggi: jika isi belum memenuhi viewport,
          // listener scroll tidak akan pernah terpicu.
          _requestNextPage();
          return const _LoadMoreIndicator();
        }

        final note = notes[index];
        return _NoteListItem(
          key: ValueKey(note.id),
          note: note,
          onEdit: _editNote,
          onDelete: _deleteNote,
        );
      },
    );
  }
}

/// Search bar dengan debounce.
///
/// Sebelumnya setiap ketikan langsung mengubah provider sehingga seluruh
/// halaman ikut rebuild dan daftar difilter ulang. Dengan debounce 300 ms,
/// query hanya dikirim setelah pengguna berhenti mengetik.
class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _text = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _text = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(notesProvider.notifier).setQuery(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _text = '');
    ref.read(notesProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary memisahkan layer search bar dari daftar. Kedipan cursor
    // dan perubahan teks tidak memaksa area list ikut di-repaint.
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          key: const Key('searchNotesField'),
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Cari catatan...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: _clear)
                : null,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _onChanged,
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 56, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'Tidak ada catatan yang cocok dengan "$query"',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus catatan?'),
      content: Text('Catatan "$title" akan dihapus.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Item catatan dipisah menjadi widget sendiri agar menu dan callback-nya
/// tidak dibangun ulang setiap kali daftar induk berubah.
class _NoteListItem extends StatelessWidget {
  const _NoteListItem({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final Note note;
  final ValueChanged<Note> onEdit;
  final ValueChanged<Note> onDelete;

  /// Tear-off statis: instance menu yang sama dipakai ulang, bukan closure
  /// baru yang dibuat setiap build.
  static List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    return const [
      PopupMenuItem(value: 'edit', child: Text('Edit')),
      PopupMenuItem(value: 'delete', child: Text('Hapus')),
    ];
  }

  void _handleAction(String action) {
    if (action == 'edit') onEdit(note);
    if (action == 'delete') onDelete(note);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(note.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.body.isNotEmpty) Text(note.body),
          Text(formatDate(note.updatedAt)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        tooltip: 'Aksi ${note.title}',
        onSelected: _handleAction,
        itemBuilder: _buildMenuItems,
        icon: const Icon(Icons.more_vert),
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({this.note});

  final Note? note;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note?.title ?? '';
    _bodyController.text = widget.note?.body ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Tambah catatan' : 'Edit catatan'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Judul wajib diisi'
                  : null,
            ),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Isi catatan'),
              minLines: 1,
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}
