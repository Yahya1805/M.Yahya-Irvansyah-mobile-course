import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/post.dart';
import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/posts_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(),
);

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => PostsRepository(),
);

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

final postsProvider = AsyncNotifierProvider<PostsNotifier, List<Post>>(
  PostsNotifier.new,
);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOffline(bool value) => state = value;
}

class NotesNotifier extends AsyncNotifier<List<Note>> {
  NoteRepository get _repository => ref.read(noteRepositoryProvider);

  @override
  Future<List<Note>> build() {
    return _repository.fetchNotes();
  }

  Future<void> addNote({required String title, String body = ''}) async {
    await _repository.addNote(title: title, body: body);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteNote(int id) async {
    await _repository.deleteNote(id);
    ref.invalidateSelf();
    await future;
  }
}

class PostsNotifier extends AsyncNotifier<List<Post>> {
  PostsRepository get _repository => ref.read(postsRepositoryProvider);
  bool _backgroundRefreshStarted = false;

  @override
  Future<List<Post>> build() async {
    final forceOffline = ref.watch(forceOfflineProvider);
    final cached = await _repository.readCachedPosts();
    if (forceOffline) {
      _backgroundRefreshStarted = false;
    } else if (!_backgroundRefreshStarted) {
      _backgroundRefreshStarted = true;
      unawaited(_refreshInBackground());
    }
    return cached;
  }

  Future<void> refresh() async {
    await _repository.refreshPosts();
    ref.invalidateSelf();
    await future;
  }

  Future<void> _refreshInBackground() async {
    await _repository.refreshPosts();
    ref.invalidateSelf();
  }
}
