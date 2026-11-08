import '../../domain/entities/post.dart';
import '../../domain/entities/posts_result.dart';
import '../../domain/failures/posts_failure.dart';
import '../../domain/repositories/posts_repository.dart';
import '../datasources/posts_api.dart';
import '../datasources/posts_cache_store.dart';

/// Implementasi keempat strategi cache dari codelab:
///
/// | Policy | Perilaku |
/// | :--- | :--- |
/// | cache-first | cache → API bila cache kosong |
/// | network-first | API → cache bila API gagal |
/// | stale-while-revalidate | emit cache → API → update cache |
/// | cache-only | hanya cache |
class PostsRepositoryImpl implements PostsRepository {
  PostsRepositoryImpl(this._api, this._cache, {this.pageLimit = 30});

  final PostsApi _api;
  final PostsCacheStore _cache;

  /// Jumlah postingan per request. Parameter `_limit` memperkecil payload.
  final int pageLimit;

  @override
  Future<PostsResult?> readCachedPosts() async {
    final posts = await _cache.readPosts();
    if (posts.isEmpty) return null;

    final meta = await _cache.readMeta();
    return PostsResult(
      posts: posts,
      source: PostsSource.cache,
      etag: meta.etag,
      lastSyncedAt: meta.lastSyncedAt,
    );
  }

  @override
  Future<PostsResult> loadPosts({
    required CachePolicy policy,
    PostsEmit? onCache,
  }) async {
    switch (policy) {
      case CachePolicy.cacheOnly:
        final cached = await readCachedPosts();
        return cached ??
            const PostsResult(
              posts: <Post>[],
              source: PostsSource.cache,
              message:
                  'Cache masih kosong. Muat data saat online terlebih dahulu.',
            );

      case CachePolicy.cacheFirst:
        final cached = await readCachedPosts();
        if (cached != null) return cached;
        return _fetchFromNetwork();

      case CachePolicy.networkFirst:
        final cached = await readCachedPosts();
        try {
          return await _fetchFromNetwork(cached: cached);
        } catch (_) {
          if (cached != null) return _asFallback(cached);
          rethrow;
        }

      case CachePolicy.staleWhileRevalidate:
        final cached = await readCachedPosts();
        if (cached == null) return _fetchFromNetwork();

        // Tampilkan isi cache lebih dulu agar layar tidak kosong...
        onCache?.call(cached);
        try {
          // ...lalu perbarui dari jaringan di belakangnya.
          return await _fetchFromNetwork(cached: cached);
        } catch (_) {
          return _asFallback(cached);
        }
    }
  }

  Future<PostsResult> _fetchFromNetwork({PostsResult? cached}) async {
    final meta = await _cache.readMeta();
    final etag = cached?.etag ?? meta.etag;
    final response = await _api.fetchPosts(etag: etag, limit: pageLimit);
    final syncedAt = DateTime.now();

    if (response.notModified) {
      final posts = cached?.posts ?? await _cache.readPosts();
      if (posts.isEmpty) {
        // 304 tanpa salinan lokal tidak berguna; jangan tampilkan layar kosong.
        throw const PostsFailure(
          'Server menyatakan data tidak berubah, tetapi cache lokal kosong.',
        );
      }

      final nextEtag = response.etag ?? etag;
      await _cache.writeMeta(etag: nextEtag, syncedAt: syncedAt);
      return PostsResult(
        posts: posts,
        source: PostsSource.network,
        etag: nextEtag,
        lastSyncedAt: syncedAt,
        notModified: true,
      );
    }

    await _cache.writePosts(response.posts);
    await _cache.writeMeta(etag: response.etag, syncedAt: syncedAt);

    return PostsResult(
      posts: response.posts,
      source: PostsSource.network,
      etag: response.etag,
      lastSyncedAt: syncedAt,
    );
  }

  PostsResult _asFallback(PostsResult cached) {
    return PostsResult(
      posts: cached.posts,
      source: PostsSource.fallback,
      etag: cached.etag,
      lastSyncedAt: cached.lastSyncedAt,
      message: 'Gagal menghubungi server. Menampilkan cache terakhir.',
    );
  }
}
