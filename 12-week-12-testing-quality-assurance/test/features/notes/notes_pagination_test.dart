import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/notes/domain/entities/note.dart';
import 'package:my_app/features/notes/domain/failures/failure.dart';
import 'package:my_app/features/notes/domain/repositories/note_repository.dart';
import 'package:my_app/features/notes/domain/usecases/get_notes.dart';
import 'package:my_app/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _PagedNoteRepository implements NoteRepository {
  _PagedNoteRepository(this.items);

  final List<Note> items;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes({
    int? limit,
    int? offset,
    String? query,
  }) async {
    var result = List<Note>.of(items);
    final trimmed = query?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      final lower = trimmed.toLowerCase();
      result = result
          .where((note) => note.title.toLowerCase().contains(lower))
          .toList();
    }
    var start = offset ?? 0;
    if (start > result.length) start = result.length;
    var end = limit == null ? result.length : start + limit;
    if (end > result.length) end = result.length;
    return (notes: result.sublist(start, end), failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Failure?> updateNote({
    required int id,
    required String title,
    required String body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Failure?> deleteNote(int id) {
    throw UnimplementedError();
  }
}

void main() {
  List<Note> buildNotes(int count) {
    return List<Note>.generate(
      count,
      (index) => Note(
        id: index + 1,
        title: 'Catatan ${index + 1}',
        body: '',
        updatedAt: DateTime(2026, 1, 1).add(Duration(minutes: index)),
      ),
    );
  }

  test(
    'memuat 20 catatan pertama lalu halaman berikutnya saat loadMore',
    () async {
      final repository = _PagedNoteRepository(buildNotes(25));
      final container = ProviderContainer(
        overrides: [getNotesProvider.overrideWithValue(GetNotes(repository))],
      );
      addTearDown(container.dispose);

      final firstPage = await container.read(notesProvider.future);
      expect(firstPage.notes, hasLength(notesPageSize));
      expect(firstPage.hasMore, isTrue);

      await container.read(notesProvider.notifier).loadMore();

      final secondPage = container.read(notesProvider).value!;
      expect(secondPage.notes, hasLength(25));
      expect(secondPage.hasMore, isFalse);
    },
  );

  test('pencarian hanya mengambil halaman pertama yang cocok', () async {
    final repository = _PagedNoteRepository(buildNotes(25));
    final container = ProviderContainer(
      overrides: [getNotesProvider.overrideWithValue(GetNotes(repository))],
    );
    addTearDown(container.dispose);

    await container.read(notesProvider.future);
    await container.read(notesProvider.notifier).setQuery('Catatan 2');

    final state = container.read(notesProvider).value!;
    expect(state.query, 'Catatan 2');
    expect(
      state.notes.every((note) => note.title.contains('Catatan 2')),
      isTrue,
    );
    // Catatan 2, 20-25 -> 7 hasil, semua termuat dalam satu halaman.
    expect(state.notes, hasLength(7));
    expect(state.hasMore, isFalse);
  });
}
