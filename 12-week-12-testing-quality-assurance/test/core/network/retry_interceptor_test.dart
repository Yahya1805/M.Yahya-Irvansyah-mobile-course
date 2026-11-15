import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/network/retry_interceptor.dart';

void main() {
  group('RetryInterceptor', () {
    test('mencoba ulang 5xx lalu berhasil', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final adapter = _ScriptedAdapter([500, 503, 200]);
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          retries: 3,
          retryDelays: const [Duration.zero],
        ),
      );

      final response = await dio.get<dynamic>('/posts');

      expect(response.statusCode, 200);
      expect(adapter.calls, 3);
    });

    test('tidak mencoba ulang 404', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final adapter = _ScriptedAdapter([404]);
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          retries: 3,
          retryDelays: const [Duration.zero],
        ),
      );

      await expectLater(
        dio.get<dynamic>('/posts'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    });

    test('hanya mengulang error sementara', () {
      final interceptor = RetryInterceptor(dio: Dio(), retries: 3);
      final request = RequestOptions(path: '/posts');

      expect(
        interceptor.shouldRetry(
          DioException(
            requestOptions: request,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        isTrue,
      );
      expect(
        interceptor.shouldRetry(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 429,
            ),
          ),
        ),
        isTrue,
      );
      expect(
        interceptor.shouldRetry(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 408,
            ),
          ),
        ),
        isTrue,
      );
      expect(
        interceptor.shouldRetry(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 500,
            ),
          ),
        ),
        isTrue,
      );
      expect(
        interceptor.shouldRetry(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 404,
            ),
          ),
        ),
        isFalse,
      );
    });
  });
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.statuses);

  final List<int> statuses;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final status = statuses.removeAt(0);
    return ResponseBody.fromString(
      '{"ok":true}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
