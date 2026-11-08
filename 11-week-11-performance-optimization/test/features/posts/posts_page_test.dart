import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/posts/domain/entities/post.dart';
import 'package:my_app/features/posts/domain/entities/posts_result.dart';
import 'package:my_app/features/posts/domain/repositories/posts_repository.dart';
import 'package:my_app/features/posts/presentation/pages/posts_page.dart';
import 'package:my_app/features/posts/presentation/providers/posts_providers.dart';

void main() {
  const networkPost = Post(
    id: 7,
    userId: 1,
    title: 'Judul dari API',
    body: 'Isi dari API',
  );
  const cachedPost = Post(
    id: 8,
    userId: 1,
    title: 'Judul dari cache',
    body: 'Isi dari cache',
  );

  testWidgets('menampilkan postingan, sumber data, dan waktu sinkron', (
    tester,
  ) async {
    final repository = _FakePostsRepository(
      networkResult: PostsResult(
        posts: const [networkPost],
        source: PostsSource.network,
        lastSyncedAt: DateTime(2026, 1, 2, 3, 4),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [postsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PostsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Postingan'), findsOneWidget);
    expect(find.text('Judul dari API'), findsOneWidget);
    expect(find.text('Dari jaringan'), findsOneWidget);
    expect(find.textContaining('Sinkron terakhir:'), findsOneWidget);
    expect(repository.lastPolicy, CachePolicy.staleWhileRevalidate);
  });

  testWidgets('memilih cache-only memakai data cache', (tester) async {
    final repository = _FakePostsRepository(
      networkResult: PostsResult(
        posts: const [networkPost],
        source: PostsSource.network,
        lastSyncedAt: DateTime(2026, 1, 2),
      ),
      cacheResult: PostsResult(
        posts: const [cachedPost],
        source: PostsSource.cache,
        lastSyncedAt: DateTime(2026, 1, 1),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [postsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PostsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('postsPolicySelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cache only').last);
    await tester.pumpAndSettle();

    expect(repository.lastPolicy, CachePolicy.cacheOnly);
    expect(find.text('Judul dari cache'), findsOneWidget);
    expect(find.text('Dari cache'), findsOneWidget);
  });
}

class _FakePostsRepository implements PostsRepository {
  _FakePostsRepository({required this.networkResult, this.cacheResult});

  final PostsResult networkResult;
  final PostsResult? cacheResult;
  CachePolicy? lastPolicy;
  int loadCalls = 0;

  @override
  Future<PostsResult?> readCachedPosts() async => null;

  @override
  Future<PostsResult> loadPosts({
    required CachePolicy policy,
    PostsEmit? onCache,
  }) async {
    lastPolicy = policy;
    loadCalls++;
    if (policy == CachePolicy.cacheOnly && cacheResult != null) {
      return cacheResult!;
    }
    return networkResult;
  }
}
