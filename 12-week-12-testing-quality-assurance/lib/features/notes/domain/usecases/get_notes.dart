import '../failures/failure.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  const GetNotes(this._repository);
  final NoteRepository _repository;

  Future<({List<Note> notes, Failure? failure})> call({
    int? limit,
    int? offset,
    String? query,
  }) {
    return _repository.fetchNotes(limit: limit, offset: offset, query: query);
  }
}
