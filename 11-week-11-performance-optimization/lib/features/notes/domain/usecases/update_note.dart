import '../failures/failure.dart';
import '../repositories/note_repository.dart';

class UpdateNote {
  const UpdateNote(this._repository);
  final NoteRepository _repository;

  Future<Failure?> call({
    required int id,
    required String title,
    required String body,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return const ValidationFailure('Judul catatan tidak boleh kosong');
    }
    return _repository.updateNote(
      id: id,
      title: trimmedTitle,
      body: body.trim(),
    );
  }
}
