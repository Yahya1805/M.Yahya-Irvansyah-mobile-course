import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/notes/domain/entities/note.dart';
import 'package:my_app/features/notes/domain/failures/failure.dart';
import 'package:my_app/features/notes/domain/repositories/note_repository.dart';
import 'package:my_app/features/notes/presentation/pages/notes_page.dart';
import 'package:my_app/features/notes/presentation/providers/notes_providers.dart';

void main() {
  testWidgets('scroll near bottom memuat halaman catatan berikutnya', (
    tester,
  ) async {
    final repository = _ScrollNoteRepository(
      List<Note>.generate(
        45,
        (index) => Note(
          id: index + 1,
          title: 'Catatan ${index + 1}',
          body: 'Isi ${index + 1}',
          updatedAt: DateTime(2026).add(Duration(minutes: index)),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Halaman pertama dimuat dengan offset 0 dan hanya 20 item.
    expect(repository.requestedOffsets, [0]);

    await tester.fling(find.byType(ListView), const Offset(0, -2000), 1200);
    await tester.pumpAndSettle();

    // Infinite scroll meminta halaman berikutnya pada offset 20.
    expect(repository.requestedOffsets, contains(20));
  });
}

class _ScrollNoteRepository implements NoteRepository {
  _ScrollNoteRepository(this.notes);

  final List<Note> notes;
  final List<int> requestedOffsets = <int>[];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes({
    int? limit,
    int? offset,
    String? query,
  }) async {
    requestedOffsets.add(offset ?? 0);
    var result = List<Note>.of(notes);
    final trimmed = query?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      final lower = trimmed.toLowerCase();
      result = result
          .where((note) => note.title.toLowerCase().contains(lower))
          .toList();
    }
    if (offset != null) result = result.skip(offset).toList();
    if (limit != null) result = result.take(limit).toList();
    return (notes: result, failure: null);
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
