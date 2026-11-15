import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'retry_interceptor.dart';

/// Membuat [Dio] dengan konfigurasi jaringan yang dipakai bersama:
///
/// * timeout eksplisit agar request tidak menggantung selamanya;
/// * header `Accept-Encoding: gzip` supaya server dapat mengirim payload
///   terkompresi;
/// * [RetryInterceptor] untuk kegagalan sementara;
/// * logging ringkas di mode debug.
Dio createApiClient({
  String baseUrl = 'https://jsonplaceholder.typicode.com',
  void Function(String message)? logPrint,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: const {
        'Accept': 'application/json',
        // Kompresi di sisi server. Dio/HttpClient tetap menangani dekompresi
        // otomatis untuk respons gzip.
        'Accept-Encoding': 'gzip',
      },
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(RetryInterceptor(dio: dio, logPrint: logPrint));

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (line) => (logPrint ?? debugPrint)(line.toString()),
      ),
    );
  }

  return dio;
}
