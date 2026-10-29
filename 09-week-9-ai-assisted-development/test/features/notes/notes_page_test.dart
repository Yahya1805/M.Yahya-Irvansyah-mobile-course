import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/notes/domain/entities/note.dart';
import 'package:my_app/features/notes/domain/failures/failure.dart';
import 'package:my_app/features/notes/domain/repositories/note_repository.dart';
import 'package:my_app/features/notes/presentation/pages/notes_page.dart';
import 'package:my_app/features/notes/presentation/providers/notes_providers.dart';

void main() {
  testWidgets('reads notes and completes the Notes CRUD flow', (tester) async {
    final repository = _FakeNoteRepository()
      ..notes.add(
        Note(
          id: 1,
          title: 'Catatan awal',
          body: 'Isi awal',
          updatedAt: DateTime(2026),
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catatan awal'), findsOneWidget);
    expect(find.text('Isi awal'), findsOneWidget);

    await tester.tap(find.byTooltip('Tambah catatan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Catatan baru');
    await tester.enterText(find.byType(TextFormField).at(1), 'Isi baru');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan baru'), findsOneWidget);
    expect(find.text('Isi baru'), findsOneWidget);
    expect(repository.notes, hasLength(2));

    await tester.tap(find.byTooltip('Aksi Catatan baru'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Catatan edit');
    await tester.enterText(find.byType(TextFormField).at(1), 'Isi edit');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan edit'), findsOneWidget);
    expect(find.text('Isi edit'), findsOneWidget);

    await tester.tap(find.byTooltip('Aksi Catatan edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    expect(find.text('Catatan edit'), findsNothing);
    expect(repository.notes, hasLength(1));
  });
}

class _FakeNoteRepository implements NoteRepository {
  final List<Note> notes = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: List<Note>.of(notes), failure: null);

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    notes.add(note);
    return (note: note, failure: null);
  }

  @override
  Future<Failure?> updateNote({
    required int id,
    required String title,
    required String body,
  }) async {
    final index = notes.indexWhere((note) => note.id == id);
    if (index < 0) return const LocalFailure('Catatan tidak ditemukan.');
    final previous = notes[index];
    notes[index] = Note(
      id: id,
      title: title,
      body: body,
      createdAt: previous.createdAt,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    return null;
  }

  @override
  Future<Failure?> deleteNote(int id) async {
    notes.removeWhere((note) => note.id == id);
    return null;
  }
}
