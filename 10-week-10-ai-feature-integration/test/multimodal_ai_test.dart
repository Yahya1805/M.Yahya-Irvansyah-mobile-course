import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/ai/ai_service.dart';
import 'package:my_app/features/multimodal_ai_screen.dart';

class _MockMultimodalAiService extends AiService {
  @override
  Future<String> recognizeText(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    return 'KARTU TANDA MAHASISWA\nNAMA: M. YAHYA IRVANSYAH\nNIM: 2241720000';
  }

  @override
  Future<String> describeImage(
    Uint8List imageBytes, {
    String prompt =
        'Jelaskan isi gambar ini secara ringkas dalam Bahasa Indonesia.',
    String mimeType = 'image/jpeg',
  }) async {
    return 'Gambar menunjukkan sebuah kartu identitas akademik di atas meja kayu.';
  }

  @override
  Future<String> speechToText(
    Uint8List audioBytes, {
    String mimeType = 'audio/mp3',
  }) async {
    return 'Halo, saya sedang merekam catatan tugas kuliah minggu sepuluh.';
  }
}

void main() {
  group('MultimodalAiScreen Tests', () {
    testWidgets('menampilkan 3 tab: OCR, Vision, dan Speech', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultimodalAiScreen(aiService: _MockMultimodalAiService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OCR'), findsOneWidget);
      expect(find.text('Vision'), findsOneWidget);
      expect(find.text('Speech'), findsOneWidget);
      expect(find.text('Pindai Teks Gambar (OCR)'), findsOneWidget);
    });

    testWidgets('menjalankan proses OCR dan menampilkan hasil ekstraksi teks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultimodalAiScreen(aiService: _MockMultimodalAiService()),
        ),
      );
      await tester.pumpAndSettle();

      // Klik tombol pindai OCR
      await tester.tap(find.text('Pindai Teks Gambar (OCR)'));
      await tester.pumpAndSettle();

      expect(find.textContaining('KARTU TANDA MAHASISWA'), findsOneWidget);
      expect(find.textContaining('M. YAHYA IRVANSYAH'), findsOneWidget);
    });

    testWidgets(
      'berpindah ke tab Vision dan menampilkan hasil Image Understanding',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MultimodalAiScreen(aiService: _MockMultimodalAiService()),
          ),
        );
        await tester.pumpAndSettle();

        // Pindah ke tab Vision
        await tester.tap(find.text('Vision'));
        await tester.pumpAndSettle();

        expect(find.text('Analisis & Deskripsikan Gambar'), findsOneWidget);

        await tester.tap(find.text('Analisis & Deskripsikan Gambar'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('kartu identitas akademik di atas meja kayu'),
          findsOneWidget,
        );
      },
    );

    testWidgets('berpindah ke tab Speech dan menampilkan transkripsi suara', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultimodalAiScreen(aiService: _MockMultimodalAiService()),
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke tab Speech
      await tester.tap(find.text('Speech'));
      await tester.pumpAndSettle();

      expect(find.text('Mulai Transkripsi Audio'), findsOneWidget);

      await tester.tap(find.text('Mulai Transkripsi Audio'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('merekam catatan tugas kuliah minggu sepuluh'),
        findsOneWidget,
      );
    });
  });
}
