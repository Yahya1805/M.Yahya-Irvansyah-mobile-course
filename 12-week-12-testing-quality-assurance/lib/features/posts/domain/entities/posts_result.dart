import 'post.dart';

/// Strategi cache yang dapat dipilih pengguna.
enum CachePolicy {
  /// Baca cache; hanya memanggil API bila cache kosong.
  cacheFirst,

  /// Panggil API; jika gagal, pakai cache sebagai fallback.
  networkFirst,

  /// Tampilkan cache lebih dulu, lalu perbarui dari API di latar belakang.
  staleWhileRevalidate,

  /// Hanya membaca cache, tanpa request jaringan.
  cacheOnly,
}

/// Asal data yang ditampilkan ke pengguna.
enum PostsSource {
  /// Data baru dari API (atau divalidasi dengan ETag/304).
  network,

  /// Data dari cache lokal.
  cache,

  /// Data cache karena request jaringan gagal.
  fallback,
}

class PostsResult {
  const PostsResult({
    required this.posts,
    required this.source,
    this.etag,
    this.lastSyncedAt,
    this.notModified = false,
    this.message,
  });

  final List<Post> posts;
  final PostsSource source;
  final String? etag;
  final DateTime? lastSyncedAt;

  /// True bila server menjawab 304 Not Modified.
  final bool notModified;

  /// Pesan tambahan untuk pengguna (mis. alasan memakai fallback).
  final String? message;
}
