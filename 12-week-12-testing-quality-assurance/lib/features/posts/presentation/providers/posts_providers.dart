import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/notes_db.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/posts_api.dart';
import '../../data/datasources/posts_cache_store.dart';
import '../../data/datasources/sqflite_posts_cache_store.dart';
import '../../data/repositories/posts_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/posts_result.dart';
import '../../domain/repositories/posts_repository.dart';

/// Satu [Dio] dipakai bersama agar connection pool tidak dibuat ulang untuk
/// setiap halaman dan interceptor retry/logging hanya terpasang sekali.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = createApiClient();
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final postsApiProvider = Provider<PostsApi>((ref) {
  return DioPostsApi(ref.watch(apiClientProvider));
});

final postsCacheStoreProvider = Provider<PostsCacheStore>((ref) {
  return SqflitePostsCacheStore(openNotesDb);
});

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepositoryImpl(
    ref.watch(postsApiProvider),
    ref.watch(postsCacheStoreProvider),
  );
});

class PostsState {
  const PostsState({
    required this.posts,
    required this.policy,
    required this.source,
    this.lastSyncedAt,
    this.notModified = false,
    this.isRefreshing = false,
    this.message,
  });

  final List<Post> posts;
  final CachePolicy policy;
  final PostsSource source;
  final DateTime? lastSyncedAt;
  final bool notModified;
  final bool isRefreshing;
  final String? message;

  PostsState copyWith({
    List<Post>? posts,
    CachePolicy? policy,
    PostsSource? source,
    DateTime? lastSyncedAt,
    bool? notModified,
    bool? isRefreshing,
    String? message,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      policy: policy ?? this.policy,
      source: source ?? this.source,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      notModified: notModified ?? this.notModified,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      message: message,
    );
  }
}

/// Notifier feed postingan dengan pemilihan strategi cache.
///
/// Stale-while-revalidate menampilkan cache lebih dulu (jika ada), lalu
/// menjalankan revalidasi jaringan di latar belakang.
class PostsNotifier extends AsyncNotifier<PostsState> {
  CachePolicy _policy = CachePolicy.staleWhileRevalidate;

  @override
  Future<PostsState> build() async {
    return _load(_policy, scheduleRevalidate: true);
  }

  Future<PostsState> _load(
    CachePolicy policy, {
    bool scheduleRevalidate = false,
  }) async {
    final repository = ref.read(postsRepositoryProvider);

    if (policy == CachePolicy.staleWhileRevalidate) {
      final cached = await repository.readCachedPosts();
      if (cached != null) {
        if (scheduleRevalidate) {
          // Jadwalkan setelah build selesai agar state cache sempat tampil.
          Future<void>.delayed(Duration.zero, _revalidate);
        }
        return _toState(cached, policy, isRefreshing: true);
      }
    }

    final result = await repository.loadPosts(policy: policy);
    return _toState(result, policy);
  }

  /// Memperbarui data di latar belakang untuk stale-while-revalidate.
  Future<void> _revalidate() async {
    if (!ref.mounted) return;

    try {
      final result = await ref
          .read(postsRepositoryProvider)
          .loadPosts(policy: CachePolicy.networkFirst);
      if (!ref.mounted) return;
      state = AsyncData(_toState(result, _policy));
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      final current = state.value;
      if (current == null) {
        state = AsyncError<PostsState>(error, stackTrace);
        return;
      }
      // Cache sudah tampil; cukup hentikan indikator dan beri keterangan.
      state = AsyncData(
        current.copyWith(
          isRefreshing: false,
          message: 'Gagal menyegarkan data. Menampilkan cache terakhir.',
        ),
      );
    }
  }

  Future<void> setPolicy(CachePolicy policy) async {
    if (_policy == policy) return;

    _policy = policy;
    state = const AsyncLoading<PostsState>();

    try {
      final next = await _load(policy, scheduleRevalidate: true);
      if (!ref.mounted) return;
      state = AsyncData(next);
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      state = AsyncError<PostsState>(error, stackTrace);
    }
  }

  /// Refresh manual selalu mencoba jaringan (kecuali mode cache-only).
  Future<void> refresh() async {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isRefreshing: true, message: null));
    }

    try {
      final policy = _policy == CachePolicy.cacheOnly
          ? CachePolicy.cacheOnly
          : CachePolicy.networkFirst;
      final result = await ref
          .read(postsRepositoryProvider)
          .loadPosts(policy: policy);
      if (!ref.mounted) return;
      state = AsyncData(_toState(result, _policy));
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      final fallback = state.value;
      if (fallback == null) {
        state = AsyncError<PostsState>(error, stackTrace);
        return;
      }
      state = AsyncData(
        fallback.copyWith(
          isRefreshing: false,
          message: 'Gagal menyegarkan data.',
        ),
      );
    }
  }

  PostsState _toState(
    PostsResult result,
    CachePolicy policy, {
    bool isRefreshing = false,
  }) {
    return PostsState(
      posts: result.posts,
      policy: policy,
      source: result.source,
      lastSyncedAt: result.lastSyncedAt,
      notModified: result.notModified,
      isRefreshing: isRefreshing,
      message: result.message,
    );
  }
}

final postsProvider = AsyncNotifierProvider<PostsNotifier, PostsState>(
  PostsNotifier.new,
);
