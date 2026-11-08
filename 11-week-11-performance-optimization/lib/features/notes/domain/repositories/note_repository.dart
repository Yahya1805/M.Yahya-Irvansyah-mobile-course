import '../failures/failure.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  /// Mengambil catatan dengan pagination opsional.
  ///
  /// [limit] dan [offset] dipakai untuk lazy loading sehingga aplikasi tidak
  /// memuat seluruh isi database sekaligus. [query] memfilter judul di level
  /// database agar pencarian tetap benar meskipun baru sebagian halaman termuat.
  Future<({List<Note> notes, Failure? failure})> fetchNotes({
    int? limit,
    int? offset,
    String? query,
  });

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
