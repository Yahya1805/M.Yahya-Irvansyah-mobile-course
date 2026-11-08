import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/notes_db.dart';

import '../../data/repositories/note_repository_impl.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/update_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/entities/note.dart';

/// Jumlah catatan yang dimuat per halaman.
const notesPageSize = 20;

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openNotesDb);
});

final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

final updateNoteProvider = Provider<UpdateNote>((ref) {
  return UpdateNote(ref.watch(noteRepositoryProvider));
});

final deleteNoteProvider = Provider<DeleteNote>((ref) {
  return DeleteNote(ref.watch(noteRepositoryProvider));
});

/// State daftar catatan yang mendukung pagination dan pencarian.
class NotesListState {
  const NotesListState({
    required this.notes,
    required this.query,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<Note> notes;
  final String query;
  final bool hasMore;
  final bool isLoadingMore;

  NotesListState copyWith({
    List<Note>? notes,
    String? query,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotesListState(
      notes: notes ?? this.notes,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Notifier yang memuat catatan per halaman (lazy loading).
///
/// Perubahan query hanya memuat ulang halaman pertama, bukan seluruh isi
/// database. Halaman berikutnya dimuat saat pengguna mendekati ujung list.
class NotesListNotifier extends AsyncNotifier<NotesListState> {
  int _requestToken = 0;

  @override
  Future<NotesListState> build() => _fetchPage(query: '', offset: 0);

  Future<NotesListState> _fetchPage({
    required String query,
    required int offset,
  }) async {
    final result = await ref
        .read(getNotesProvider)
        .call(
          limit: notesPageSize,
          offset: offset,
          query: query.isEmpty ? null : query,
        );
    if (result.failure != null) throw result.failure!;
    return NotesListState(
      notes: result.notes,
      query: query,
      hasMore: result.notes.length == notesPageSize,
    );
  }

  Future<void> setQuery(String rawQuery) async {
    final query = rawQuery.trim();
    final current = state.value;
    if (current != null && current.query == query) return;

    final token = ++_requestToken;
    if (current != null) {
      // Pertahankan daftar lama selama query baru diproses agar layar tidak
      // berkedip ke loading state.
      state = AsyncData(current.copyWith(query: query, isLoadingMore: true));
    }

    try {
      final next = await _fetchPage(query: query, offset: 0);
      if (token != _requestToken) return;
      state = AsyncData(next);
    } catch (error, stackTrace) {
      if (token != _requestToken) return;
      state = AsyncError<NotesListState>(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await ref
          .read(getNotesProvider)
          .call(
            limit: notesPageSize,
            offset: current.notes.length,
            query: current.query.isEmpty ? null : current.query,
          );
      if (result.failure != null) throw result.failure!;

      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          notes: [...latest.notes, ...result.notes],
          hasMore: result.notes.length == notesPageSize,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(isLoadingMore: false));
      rethrow;
    }
  }
}

final notesProvider = AsyncNotifierProvider<NotesListNotifier, NotesListState>(
  NotesListNotifier.new,
);
