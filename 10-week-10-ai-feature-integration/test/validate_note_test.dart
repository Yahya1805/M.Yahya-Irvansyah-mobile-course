import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/notes/domain/entities/note.dart';
import 'package:my_app/features/notes/domain/failures/failure.dart';
import 'package:my_app/features/notes/domain/repositories/note_repository.dart';
import 'package:my_app/features/notes/domain/usecases/add_note.dart';
import 'package:my_app/features/notes/domain/usecases/update_note.dart';

class MockNoteRepository implements NoteRepository {
  final List<Note> notes = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    return (notes: notes, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      createdAt: DateTime.now(),
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
    final index = notes.indexWhere((n) => n.id == id);
    if (index == -1) {
      return const LocalFailure('Catatan tidak ditemukan');
    }
    final old = notes[index];
    notes[index] = Note(
      id: old.id,
      title: title,
      body: body,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    return null;
  }

  @override
  Future<Failure?> deleteNote(int id) async {
    notes.removeWhere((n) => n.id == id);
    return null;
  }
}

void main() {
  group('AddNote Validation Tests', () {
    late MockNoteRepository repository;
    late AddNote addNote;

    setUp(() {
      repository = MockNoteRepository();
      addNote = AddNote(repository);
    });

    test('gagal saat menambahkan catatan dengan judul string kosong', () async {
      final result = await addNote.call(title: '', body: 'Catatan konten');

      expect(result.note, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, 'Judul catatan tidak boleh kosong');
      expect(repository.notes, isEmpty);
    });

    test(
      'gagal saat menambahkan catatan dengan judul hanya spasi (whitespace)',
      () async {
        final result = await addNote.call(
          title: '    ',
          body: 'Catatan konten',
        );

        expect(result.note, isNull);
        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure?.message, 'Judul catatan tidak boleh kosong');
        expect(repository.notes, isEmpty);
      },
    );

    test(
      'sukses saat menambahkan catatan dengan judul valid dan melakukan trim',
      () async {
        final result = await addNote.call(
          title: '  Belajar Flutter Clean Architecture  ',
          body: '  Isi materi minggu 8  ',
        );

        expect(result.failure, isNull);
        expect(result.note, isNotNull);
        expect(result.note!.title, 'Belajar Flutter Clean Architecture');
        expect(result.note!.body, 'Isi materi minggu 8');
        expect(repository.notes.length, 1);
      },
    );
  });

  group('UpdateNote Validation Tests', () {
    late MockNoteRepository repository;
    late UpdateNote updateNote;

    setUp(() async {
      repository = MockNoteRepository();
      await repository.addNote(title: 'Judul Awal', body: 'Isi Awal');
      updateNote = UpdateNote(repository);
    });

    test('gagal memperbarui saat judul baru kosong atau hanya spasi', () async {
      final failureEmpty = await updateNote.call(id: 1, title: '', body: 'Isi');
      expect(failureEmpty, isA<ValidationFailure>());

      final failureWhitespace = await updateNote.call(
        id: 1,
        title: '   ',
        body: 'Isi',
      );
      expect(failureWhitespace, isA<ValidationFailure>());
    });

    test('sukses memperbarui saat judul valid', () async {
      final failure = await updateNote.call(
        id: 1,
        title: '  Judul Baru Terupdate  ',
        body: 'Konten terupdate',
      );

      expect(failure, isNull);
      expect(repository.notes.first.title, 'Judul Baru Terupdate');
    });
  });
}
