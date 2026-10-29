import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/notes/domain/entities/note.dart';
import 'package:my_app/features/notes/domain/failures/failure.dart';
import 'package:my_app/features/notes/domain/repositories/note_repository.dart';
import 'package:my_app/features/notes/domain/usecases/get_notes.dart';
import 'package:my_app/features/notes/data/models/note_model.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.fail = false});

  final List<Note> items;
  final bool fail;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (fail) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('db locked (simulasi)'),
      );
    }
    return (notes: items, failure: null);
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
  }) => Future.value(null);

  @override
  Future<Failure?> deleteNote(int id) => Future.value(null);
}

void main() {
  test('NoteModel mempertahankan tanggal dibuat saat mapping', () {
    final createdAt = DateTime(2026, 9, 1);
    final updatedAt = DateTime(2026, 9, 3);
    final model = NoteModel(
      title: 'Model',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    final mapped = NoteModel.fromMap(model.toMap());
    expect(mapped.createdAt, createdAt);
    expect(mapped.updatedAt, updatedAt);
  });

  test('GetNotes meneruskan daftar dari repository', () async {
    final repo = FakeNoteRepository(
      items: [Note(title: 'A', updatedAt: DateTime(2026, 9, 27))],
    );
    final result = await GetNotes(repo).call();
    expect(result.failure, isNull);
    expect(result.notes.length, 1);
    expect(result.notes.first.title, 'A');
  });

  test('GetNotes meneruskan failure tanpa melempar', () async {
    final repo = FakeNoteRepository(fail: true);
    final result = await GetNotes(repo).call();
    expect(result.failure, isA<LocalFailure>());
    expect(result.notes, isEmpty);
  });
}
