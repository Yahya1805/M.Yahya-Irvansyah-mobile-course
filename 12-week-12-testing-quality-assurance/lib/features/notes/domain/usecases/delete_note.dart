import '../failures/failure.dart';
import '../repositories/note_repository.dart';

class DeleteNote {
  const DeleteNote(this._repository);
  final NoteRepository _repository;

  Future<Failure?> call(int id) => _repository.deleteNote(id);
}
