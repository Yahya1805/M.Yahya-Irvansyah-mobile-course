import 'package:dio/dio.dart';

import '../../domain/entities/post.dart';
import '../../domain/failures/posts_failure.dart';
import '../models/post_model.dart';

class PostsResponse {
  const PostsResponse({
    required this.posts,
    this.etag,
    this.notModified = false,
  });

  final List<Post> posts;
  final String? etag;
  final bool notModified;
}

abstract class PostsApi {
  /// Mengambil daftar postingan.
  ///
  /// Bila [etag] dikirim, server dapat menjawab 304 Not Modified sehingga
  /// body tidak perlu diunduh ulang.
  Future<PostsResponse> fetchPosts({String? etag, int limit = 30});
}

class DioPostsApi implements PostsApi {
  DioPostsApi(this._dio);

  final Dio _dio;

  @override
  Future<PostsResponse> fetchPosts({String? etag, int limit = 30}) async {
    final headers = <String, dynamic>{};
    if (etag != null) {
      headers['If-None-Match'] = etag;
      // Minta server memvalidasi ETag, bukan memakai salinan basi dari proxy
      // perantara.
      headers['Cache-Control'] = 'no-cache';
    }

    try {
      final response = await _dio.get<dynamic>(
        '/posts',
        // _limit memperkecil payload: hanya 30 postingan yang diminta,
        // bukan seluruh isi endpoint.
        queryParameters: {'_limit': limit},
        options: Options(
          headers: headers,
          validateStatus: (status) =>
              status == 304 ||
              (status != null && status >= 200 && status < 300),
        ),
      );

      if (response.statusCode == 304) {
        return PostsResponse(
          posts: const <Post>[],
          etag: etag,
          notModified: true,
        );
      }

      final data = response.data;
      if (data is! List) {
        throw const PostsFailure('Format respons postingan tidak dikenali.');
      }

      final posts = data
          .whereType<Map<dynamic, dynamic>>()
          .map<Post>(
            (json) =>
                PostModel.fromJson(Map<String, dynamic>.from(json)).toEntity(),
          )
          .toList();

      return PostsResponse(posts: posts, etag: response.headers.value('etag'));
    } on PostsFailure {
      rethrow;
    } on DioException catch (error) {
      throw PostsFailure(_messageFor(error));
    } catch (_) {
      throw const PostsFailure(
        'Postingan tidak dapat dimuat. Silakan coba lagi.',
      );
    }
  }

  String _messageFor(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Koneksi ke server timeout. Periksa jaringan Anda.',
      DioExceptionType.connectionError =>
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      DioExceptionType.cancel => 'Permintaan dibatalkan.',
      DioExceptionType.badResponse =>
        'Server menolak permintaan (HTTP ${error.response?.statusCode ?? '-'}).',
      _ => 'Postingan tidak dapat dimuat. Silakan coba lagi.',
    };
  }
}
