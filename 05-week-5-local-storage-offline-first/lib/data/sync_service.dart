import 'repositories/note_repository.dart';

Future<int> syncNotes(NoteRepository repository) async {
  final dirtyCount = await repository.countDirty();
  if (dirtyCount == 0) return 0;

  await Future<void>.delayed(const Duration(seconds: 1));
  await repository.markAllSynced();
  return dirtyCount;
}
