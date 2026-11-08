import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/posts/data/datasources/posts_api.dart';
import 'package:my_app/features/posts/data/datasources/posts_cache_store.dart';
import 'package:my_app/features/posts/data/repositories/posts_repository_impl.dart';
import 'package:my_app/features/posts/domain/entities/post.dart';
import 'package:my_app/features/posts/domain/entities/posts_result.dart';
import 'package:my_app/features/posts/domain/failures/posts_failure.dart';

void main() {
  const cachedPost = Post(
    id: 1,
    userId: 1,
    title: 'Cache lama',
    body: 'Isi cache',
  );
  const freshPost = Post(
    id: 2,
    userId: 1,
    title: 'Data baru',
    body: 'Isi baru',
  );

  group('PostsRepositoryImpl', () {
    test('cache-only tidak memanggil API', () async {
      final cache = _FakeCacheStore()
        ..posts = [cachedPost]
        ..etag = 'v1'
        ..lastSyncedAt = DateTime(2026, 1, 1);
      final api = _FakePostsApi();
      final repository = PostsRepositoryImpl(api, cache);

      final result = await repository.loadPosts(policy: CachePolicy.cacheOnly);

      expect(result.posts, [cachedPost]);
      expect(result.source, PostsSource.cache);
      expect(result.etag, 'v1');
      expect(api.calls, 0);
    });

    test('cache-first memakai cache tanpa request jaringan', () async {
      final cache = _FakeCacheStore()..posts = [cachedPost];
      final api = _FakePostsApi();
      final repository = PostsRepositoryImpl(api, cache);

      final result = await repository.loadPosts(policy: CachePolicy.cacheFirst);

      expect(result.posts, [cachedPost]);
      expect(result.source, PostsSource.cache);
      expect(api.calls, 0);
    });

    test('cache-first mengambil API dan mengisi cache saat kosong', () async {
      final cache = _FakeCacheStore();
      final api = _FakePostsApi(
        response: const PostsResponse(posts: [freshPost], etag: 'etag-baru'),
      );
      final repository = PostsRepositoryImpl(api, cache);

      final result = await repository.loadPosts(policy: CachePolicy.cacheFirst);

      expect(result.posts, [freshPost]);
      expect(result.source, PostsSource.network);
      expect(api.calls, 1);
      expect(cache.posts, [freshPost]);
      expect(cache.etag, 'etag-baru');
      expect(cache.writePostsCalls, 1);
    });

    test('network-first memakai fallback cache saat API gagal', () async {
      final cache = _FakeCacheStore()..posts = [cachedPost];
      final api = _FakePostsApi(error: const PostsFailure('offline'));
      final repository = PostsRepositoryImpl(api, cache);

      final result = await repository.loadPosts(
        policy: CachePolicy.networkFirst,
      );

      expect(result.posts, [cachedPost]);
      expect(result.source, PostsSource.fallback);
      expect(result.message, isNotNull);
      expect(api.calls, 1);
    });

    test('network-first melempar error bila cache kosong', () async {
      final cache = _FakeCacheStore();
      final api = _FakePostsApi(error: const PostsFailure('offline'));
      final repository = PostsRepositoryImpl(api, cache);

      await expectLater(
        repository.loadPosts(policy: CachePolicy.networkFirst),
        throwsA(isA<PostsFailure>()),
      );
    });

    test(
      'stale-while-revalidate mengirim cache dulu lalu data segar',
      () async {
        final cache = _FakeCacheStore()..posts = [cachedPost];
        final api = _FakePostsApi(
          response: const PostsResponse(posts: [freshPost], etag: 'v2'),
        );
        final repository = PostsRepositoryImpl(api, cache);

        final emitted = <PostsResult>[];
        final result = await repository.loadPosts(
          policy: CachePolicy.staleWhileRevalidate,
          onCache: emitted.add,
        );

        expect(emitted, hasLength(1));
        expect(emitted.single.posts, [cachedPost]);
        expect(emitted.single.source, PostsSource.cache);
        expect(result.posts, [freshPost]);
        expect(result.source, PostsSource.network);
        expect(cache.posts, [freshPost]);
        expect(cache.etag, 'v2');
      },
    );

    test(
      'ETag dikirim dan 304 memakai cache tanpa menulis ulang posts',
      () async {
        final lastSync = DateTime(2026, 1, 1);
        final cache = _FakeCacheStore()
          ..posts = [cachedPost]
          ..etag = 'etag-lama'
          ..lastSyncedAt = lastSync;
        final api = _FakePostsApi(
          response: const PostsResponse(
            posts: [],
            etag: 'etag-lama',
            notModified: true,
          ),
        );
        final repository = PostsRepositoryImpl(api, cache);

        final result = await repository.loadPosts(
          policy: CachePolicy.networkFirst,
        );

        expect(api.lastEtag, 'etag-lama');
        expect(result.posts, [cachedPost]);
        expect(result.source, PostsSource.network);
        expect(result.notModified, isTrue);
        expect(cache.writePostsCalls, 0);
        expect(cache.lastSyncedAt, isNot(lastSync));
      },
    );
  });
}

class _FakePostsApi implements PostsApi {
  _FakePostsApi({this.response, this.error});

  final PostsResponse? response;
  final Object? error;
  int calls = 0;
  String? lastEtag;

  @override
  Future<PostsResponse> fetchPosts({String? etag, int limit = 30}) async {
    calls++;
    lastEtag = etag;
    final failure = error;
    if (failure != null) throw failure;
    return response ?? const PostsResponse(posts: <Post>[], etag: null);
  }
}

class _FakeCacheStore implements PostsCacheStore {
  List<Post> posts = <Post>[];
  String? etag;
  DateTime? lastSyncedAt;
  int writePostsCalls = 0;

  @override
  Future<List<Post>> readPosts() async => List<Post>.of(posts);

  @override
  Future<void> writePosts(List<Post> posts) async {
    this.posts = List<Post>.of(posts);
    writePostsCalls++;
  }

  @override
  Future<PostsCacheMeta> readMeta() async {
    return PostsCacheMeta(etag: etag, lastSyncedAt: lastSyncedAt);
  }

  @override
  Future<void> writeMeta({String? etag, required DateTime syncedAt}) async {
    this.etag = etag;
    lastSyncedAt = syncedAt;
  }
}
