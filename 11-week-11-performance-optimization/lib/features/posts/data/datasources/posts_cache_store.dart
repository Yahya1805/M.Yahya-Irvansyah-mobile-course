import '../../domain/entities/post.dart';

class PostsCacheMeta {
  const PostsCacheMeta({this.etag, this.lastSyncedAt});

  final String? etag;
  final DateTime? lastSyncedAt;
}

abstract class PostsCacheStore {
  Future<List<Post>> readPosts();

  Future<void> writePosts(List<Post> posts);

  Future<PostsCacheMeta> readMeta();

  Future<void> writeMeta({String? etag, required DateTime syncedAt});
}
