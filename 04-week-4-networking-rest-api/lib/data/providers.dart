import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/comment.dart';
import 'models/post.dart';
import 'repositories/comment_repository.dart';
import 'repositories/post_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    // Inilah ekuivalen deklaratif dari AsyncValue.guard di versi lama.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<Post>>(
        PostListNotifier.new,
        // Nonaktifkan retry otomatis Riverpod 3 agar error langsung
        // final dan mudah diuji (tanpa ini, future provider di-test
        // akan me-retry dan menggantung).
        retry: (retryCount, error) => null);

class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  CommentsNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() async {
    // Error dari repository diteruskan Riverpod sebagai AsyncError.
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, int>(
  CommentsNotifier.new,
  retry: (retryCount, error) => null,
);

/// Helper khusus testing (letakkan di providers.dart): membaca state
/// pertama yang bukan loading lewat listener + completer, sehingga
/// test tidak menunggu retry dan tidak melakukan HTTP sungguhan.
Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

// String friendlyErrorMessage(Object error) {
//   if (error is DioException) {
//     switch (error.type) {
//       case DioExceptionType.connectionTimeout:
//       case DioExceptionType.sendTimeout:
//       case DioExceptionType.receiveTimeout:
//         return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';
//       case DioExceptionType.connectionError:
//         return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
//       case DioExceptionType.badResponse:
//         final code = error.response?.statusCode;
//         if (code == 404) return 'Data tidak ditemukan (404).';
//         if (code == 500) return 'Server sedang bermasalah (500). Coba lagi nanti.';
//         if (code == 401 || code == 403) {
//           return 'Akses ditolak ($code). Periksa kredensial Anda.';
//         }
//         return 'Server bermasalah ($code). Coba lagi nanti.';
//       default:
//         return 'Terjadi kesalahan jaringan. Coba lagi.';
//     }
//   }
//   return 'Terjadi kesalahan tak terduga: $error';
// }