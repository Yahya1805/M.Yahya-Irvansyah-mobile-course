import 'package:dio/dio.dart';

/// Interceptor retry dengan jeda bertingkat (backoff).
///
/// Permintaan dicoba ulang hanya untuk kegagalan yang bersifat sementara:
/// timeout, gagal koneksi, HTTP 408, 429, dan 5xx. Error 4xx lain (mis. 404
/// atau 401) langsung diteruskan karena mengulangnya tidak akan membantu.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ],
    this.logPrint,
  });

  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;
  final void Function(String message)? logPrint;

  static const String _retryCountKey = 'retry_count';

  /// Menentukan apakah sebuah error layak dicoba ulang.
  bool shouldRetry(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    final status = error.response?.statusCode;
    if (status == null) return false;
    return status == 408 || status == 429 || status >= 500;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (!shouldRetry(err) || attempt >= retries) {
      handler.next(err);
      return;
    }

    final delay = _delayFor(attempt);
    final nextAttempt = attempt + 1;
    logPrint?.call(
      'Retry $nextAttempt/$retries setelah ${delay.inMilliseconds} ms: '
      '${err.requestOptions.method} ${err.requestOptions.path}',
    );

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    // Salin options agar jumlah percobaan tidak bocor ke request lain yang
    // memakai objek requestOptions yang sama.
    final options = err.requestOptions;
    options.extra = {...options.extra, _retryCountKey: nextAttempt};

    try {
      final response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Duration _delayFor(int attempt) {
    if (retryDelays.isEmpty) return Duration.zero;
    final index = attempt < retryDelays.length
        ? attempt
        : retryDelays.length - 1;
    return retryDelays[index];
  }
}
