import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_app/ai/ai_service.dart';

void main() {
  group('AiService - Privacy, Cost, & Fallback Tests', () {
    test('Privasi: sanitizePrompt me-masking NIK, No Telepon, dan Email', () {
      final aiService = AiService();
      const rawPrompt =
          'Halo nama saya Budi, NIK 3507123456789012 dan no HP 081234567890 email budi@kampus.ac.id';

      final sanitized = aiService.sanitizePrompt(rawPrompt);

      expect(sanitized, isNot(contains('3507123456789012')));
      expect(sanitized, isNot(contains('081234567890')));
      expect(sanitized, isNot(contains('budi@kampus.ac.id')));

      expect(sanitized, contains('[NIK_DIRAHASIAKAN]'));
      expect(sanitized, contains('[NO_TELEPON_DIRAHASIAKAN]'));
      expect(sanitized, contains('[EMAIL_DIRAHASIAKAN]'));
    });

    test('Biaya & Efisiensi: Pertanyaan yang sama mengambil respons dari Cache Lokal', () async {
      var apiCallCount = 0;
      final mockClient = MockClient((request) async {
        apiCallCount++;
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Ini respons API asli'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final aiService = AiService(client: mockClient);
      await aiService.saveApiKey('test-api-key');

      // Request pertama -> panggil API
      final res1 = await aiService.ask('Apa itu Flutter?');
      expect(res1, 'Ini respons API asli');
      expect(apiCallCount, 1);

      // Request kedua dengan query yang sama -> harus diambil dari Cache
      final res2 = await aiService.ask('Apa itu Flutter?');
      expect(res2, contains('Diambil dari Cache Lokal'));
      expect(apiCallCount, 1); // Tidak menambah panggilan API (Hemat biaya)
    });

    test(
      'Fallback: Saat API Error / Offline, otomatis beralih ke Data Lokal',
      () async {
        final failingClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final aiService = AiService(client: failingClient);
        await aiService.saveApiKey('test-api-key');

        // Pertanyaan terkait jadwal saat API error
        final fallbackResult = await aiService.ask(
          'Bagaimana jadwal hari ini?',
        );

        expect(fallbackResult, contains('Mode Offline:'));
        expect(fallbackResult, contains('Jadwal perkuliahan'));
      },
    );
  });
}
