import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/local/post.dart';
import '../data/sync_service.dart';
import '../providers/note_providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final posts = ref.watch(postsProvider);
    final offline = ref.watch(forceOfflineProvider);
    final noteItems = notes.value ?? const <Note>[];
    final dirtyCount = noteItems.where((note) => note.dirty).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('Belum tersinkron: $dirtyCount')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(postsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Force Offline'),
              subtitle: Text(
                offline
                    ? 'Request jaringan dinonaktifkan.'
                    : 'Cache dibaca, lalu jaringan di-refresh di background.',
              ),
              value: offline,
              onChanged: (value) => ref
                  .read(forceOfflineProvider.notifier)
                  .setOffline(value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Catatan Saya',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _syncing ? null : _syncNotes,
                  icon: _syncing
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Sync'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            notes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Gagal membaca catatan: $error'),
              data: (items) => _NotesList(items: items),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Posts Cache-First',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(postsProvider.notifier).refresh(),
                  tooltip: 'Refresh posts',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            posts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Gagal membaca cache: $error'),
              data: (items) => _PostsList(items: items),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNotes() async {
    if (ref.read(forceOfflineProvider)) {
      _showMessage('Matikan Force Offline untuk menjalankan sync.');
      return;
    }

    setState(() => _syncing = true);
    final count = await syncNotes(ref.read(noteRepositoryProvider));
    ref.invalidate(notesProvider);
    if (!mounted) return;
    setState(() => _syncing = false);
    _showMessage(
      count == 0
          ? 'Tidak ada catatan yang perlu disinkronkan.'
          : '$count catatan berhasil disinkronkan.',
    );
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (_) => const _AddNoteDialog(),
    );
    if (result == null || result.$1.trim().isEmpty) return;

    await ref.read(notesProvider.notifier).addNote(
          title: result.$1.trim(),
          body: result.$2.trim(),
        );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NotesList extends ConsumerWidget {
  const _NotesList({required this.items});

  final List<Note> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Text('Belum ada catatan. Ketuk Tambah untuk mulai.');
    }

    return Column(
      children: items
          .map(
            (note) => Card(
              child: ListTile(
                title: Text(note.title),
                subtitle: Text(note.body.isEmpty ? 'Tanpa isi' : note.body),
                leading: Icon(
                  note.dirty
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                ),
                trailing: IconButton(
                  onPressed: note.id == null
                      ? null
                      : () => ref
                          .read(notesProvider.notifier)
                          .deleteNote(note.id!),
                  tooltip: 'Hapus catatan',
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({required this.items});

  final List<Post> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('Belum ada data offline.');
    }

    return Column(
      children: items
          .take(10)
          .map(
            (post) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(post.title),
              subtitle: Text(post.body),
            ),
          )
          .toList(),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog();

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catatan baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Judul'),
          ),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(labelText: 'Isi'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (_titleController.text, _bodyController.text),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
