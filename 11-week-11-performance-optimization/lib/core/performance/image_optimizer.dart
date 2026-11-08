import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Hasil optimasi gambar beserta MIME type yang sesuai dengan byte-nya.
class OptimizedImage {
  const OptimizedImage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

/// Utilitas kompresi gambar sebelum dikirim ke layanan AI.
///
/// Gambar dari kamera bisa berukuran beberapa megapiksel. Mengirim byte
/// mentah sebagai base64 membuat payload jaringan dan memori membengkak.
/// Gambar diperkecil ke sisi terpanjang [maxDimension] lalu di-encode ulang
/// sebagai JPEG dengan kualitas terkendali.
class ImageOptimizer {
  const ImageOptimizer._();

  static const int defaultMaxDimension = 1024;
  static const int defaultQuality = 82;

  static Future<OptimizedImage> optimizeForAi(
    Uint8List bytes, {
    String mimeType = 'image/jpeg',
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) {
    if (bytes.isEmpty) {
      return Future<OptimizedImage>.value(
        OptimizedImage(bytes: bytes, mimeType: mimeType),
      );
    }
    return compute(
      _optimizeImage,
      _OptimizeRequest(
        bytes: bytes,
        mimeType: mimeType,
        maxDimension: maxDimension,
        quality: quality,
      ),
    );
  }
}

class _OptimizeRequest {
  const _OptimizeRequest({
    required this.bytes,
    required this.mimeType,
    required this.maxDimension,
    required this.quality,
  });

  final Uint8List bytes;
  final String mimeType;
  final int maxDimension;
  final int quality;
}

OptimizedImage _optimizeImage(_OptimizeRequest request) {
  final decoded = img.decodeImage(request.bytes);
  // Format tidak dikenali: kirim apa adanya agar AI tetap bisa mencoba.
  if (decoded == null) {
    return OptimizedImage(bytes: request.bytes, mimeType: request.mimeType);
  }

  var image = decoded;
  final longestSide = math.max(decoded.width, decoded.height);
  if (longestSide > request.maxDimension) {
    final scale = request.maxDimension / longestSide;
    image = img.copyResize(
      decoded,
      width: math.max(1, (decoded.width * scale).round()),
      height: math.max(1, (decoded.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  final encoded = Uint8List.fromList(
    img.encodeJpg(image, quality: request.quality),
  );
  // Jangan sampai hasil kompresi justru lebih besar dari file asli.
  if (encoded.length >= request.bytes.length) {
    return OptimizedImage(bytes: request.bytes, mimeType: request.mimeType);
  }
  return OptimizedImage(bytes: encoded, mimeType: 'image/jpeg');
}
