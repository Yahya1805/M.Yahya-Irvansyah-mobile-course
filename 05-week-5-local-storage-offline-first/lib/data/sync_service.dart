import 'package:dio/dio.dart';

import 'repositories/note_repository.dart';

class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<int> syncNotes(NoteRepository repository, {Dio? dio}) async {
  final dirtyNotes = await repository.fetchDirtyNotes();
  if (dirtyNotes.isEmpty) return 0;

  final client = dio ?? Dio();
  var syncedCount = 0;
  try {
    for (final note in dirtyNotes) {
      final response = await client.post<Map<String, dynamic>>(
        'https://jsonplaceholder.typicode.com/posts',
        data: {
          'id': note.id,
          'title': note.title,
          'body': note.body,
          'updated_at': note.updatedAt.toIso8601String(),
        },
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        await repository.markSynced(note.id!);
        syncedCount++;
      }
    }
  } on DioException catch (error) {
    throw SyncException('Sinkronisasi gagal: ${error.message ?? 'offline'}');
  }
  return syncedCount;
}
