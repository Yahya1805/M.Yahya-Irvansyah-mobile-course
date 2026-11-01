import '../failures/failure.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Future<({List<Note> notes, Failure? failure})> fetchNotes();

  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  });

  Future<Failure?> updateNote({
    required int id,
    required String title,
    required String body,
  });

  Future<Failure?> deleteNote(int id);
}
