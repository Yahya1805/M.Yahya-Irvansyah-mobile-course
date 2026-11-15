import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:my_app/ai/ai_cache.dart';
import 'package:my_app/ai/ai_service.dart';
import 'package:my_app/core/performance/image_optimizer.dart';

void main() {
  group('ImageOptimizer', () {
    test('memperkecil gambar besar dan menghasilkan JPEG', () async {
      // Gambar "noise" acak agar PNG benar-benar besar dan kompresi terukur.
      final random = Random(7);
      final source = img.Image(width: 1600, height: 1200);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgb(
            x,
            y,
            random.nextInt(256),
            random.nextInt(256),
            random.nextInt(256),
          );
        }
      }
      final pngBytes = Uint8List.fromList(img.encodePng(source));

      final optimized = await ImageOptimizer.optimizeForAi(
        pngBytes,
        maxDimension: 400,
        quality: 75,
      );

      final decoded = img.decodeImage(optimized.bytes)!;
      expect(decoded.width, lessThanOrEqualTo(400));
      expect(decoded.height, lessThanOrEqualTo(400));
      expect(optimized.mimeType, 'image/jpeg');
      expect(optimized.bytes.length, lessThan(pngBytes.length));
    });

    test('byte kosong dikembalikan apa adanya', () async {
      final result = await ImageOptimizer.optimizeForAi(Uint8List(0));
      expect(result.bytes, isEmpty);
      expect(result.mimeType, 'image/jpeg');
    });
  });

  group('AiService persistent cache', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('jawaban tetap tersedia di instance AiService baru', () async {
      var apiCalls = 0;
      final store = _MemoryAiCacheStore();
      final client = MockClient((request) async {
        apiCalls++;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Jawaban dari API'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final first = AiService(client: client, cache: store);
      await first.saveApiKey('test-key');
      final firstResult = await first.ask('Apa itu Flutter?');
      expect(firstResult, 'Jawaban dari API');
      expect(apiCalls, 1);

      // Instance baru mensimulasikan aplikasi dibuka ulang: cache memori
      // kosong, tetapi cache persisten masih ada.
      final offlineClient = MockClient((request) async {
        throw http.ClientException('offline');
      });
      final second = AiService(client: offlineClient, cache: store);
      final secondResult = await second.ask('Apa itu Flutter?');

      expect(secondResult, contains('Diambil dari Cache Lokal'));
      expect(secondResult, contains('Jawaban dari API'));
      expect(apiCalls, 1);
    });
  });
}

class _MemoryAiCacheStore implements AiCacheStore {
  final Map<String, String> data = <String, String>{};

  @override
  Future<String?> read(String cacheKey) async => data[cacheKey];

  @override
  Future<void> write(String cacheKey, String answer) async {
    data[cacheKey] = answer;
  }
}
