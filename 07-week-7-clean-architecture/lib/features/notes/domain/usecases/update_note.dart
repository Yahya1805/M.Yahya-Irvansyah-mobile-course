import '../failures/failure.dart';
import '../repositories/note_repository.dart';

class UpdateNote {
  const UpdateNote(this._repository);
  final NoteRepository _repository;

  Future<Failure?> call({
    required int id,
    required String title,
    required String body,
  }) => _repository.updateNote(id: id, title: title, body: body);
}
