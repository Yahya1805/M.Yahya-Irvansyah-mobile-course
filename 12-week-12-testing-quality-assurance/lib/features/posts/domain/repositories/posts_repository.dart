import '../entities/posts_result.dart';

/// Callback untuk hasil cache yang bisa ditampilkan lebih awal
/// (dipakai oleh stale-while-revalidate).
typedef PostsEmit = void Function(PostsResult result);

abstract class PostsRepository {
  /// Membaca cache tanpa menyentuh jaringan. Null bila cache kosong.
  Future<PostsResult?> readCachedPosts();

  /// Memuat postingan sesuai [policy].
  ///
  /// Untuk [CachePolicy.staleWhileRevalidate], [onCache] dipanggil lebih dulu
  /// dengan data cache (bila ada), lalu method ini mengembalikan data segar
  /// dari jaringan atau fallback cache bila jaringan gagal.
  Future<PostsResult> loadPosts({
    required CachePolicy policy,
    PostsEmit? onCache,
  });
}
