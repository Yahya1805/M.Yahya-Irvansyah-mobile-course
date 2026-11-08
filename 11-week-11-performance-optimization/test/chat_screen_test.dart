import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/ai/ai_service.dart';
import 'package:my_app/features/chat_screen.dart';

class _FakeAiService extends AiService {
  _FakeAiService({this.response = 'Halo! Saya asisten AI kampus.'});

  final String response;
  bool shouldThrow = false;
  String? savedKey;

  @override
  Future<String> ask(String question) async {
    if (shouldThrow) throw Exception('API key tidak valid');
    return response;
  }

  @override
  Stream<String> askStream(String question) async* {
    if (shouldThrow) throw Exception('API key tidak valid');
    final words = response.split(' ');
    for (var i = 0; i < words.length; i++) {
      yield words.sublist(0, i + 1).join(' ');
    }
  }

  @override
  Future<void> saveApiKey(String key) async {
    savedKey = key;
  }

  @override
  Future<String?> getApiKey() async {
    return savedKey ?? 'dummy-key';
  }
}

void main() {
  group('ChatScreen Widget Tests', () {
    testWidgets('menampilkan initial empty state pada tampilan chat', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen(aiService: _FakeAiService())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo! Ada yang bisa AI bantu?'), findsOneWidget);
      expect(find.byKey(const Key('chatInputField')), findsOneWidget);
      expect(find.byKey(const Key('chatSendButton')), findsOneWidget);
    });

    testWidgets('mengirim pesan dan menampilkan bubble streaming respons AI', (
      tester,
    ) async {
      final fakeService = _FakeAiService(response: 'Jawaban cerdas AI');
      await tester.pumpWidget(
        MaterialApp(home: ChatScreen(aiService: fakeService)),
      );
      await tester.pumpAndSettle();

      // Masukkan teks prompt dari user
      await tester.enterText(
        find.byKey(const Key('chatInputField')),
        'Halo AI',
      );
      await tester.tap(find.byKey(const Key('chatSendButton')));
      await tester.pump();

      // Verifikasi pesan user muncul
      expect(find.text('Halo AI'), findsOneWidget);

      // Settle stream
      await tester.pumpAndSettle();

      // Verifikasi respons AI muncul
      expect(find.text('Jawaban cerdas AI'), findsOneWidget);
    });

    testWidgets(
      'menangani error dan menampilkan dialog fallback jika AI gagal',
      (tester) async {
        final fakeService = _FakeAiService()..shouldThrow = true;
        await tester.pumpWidget(
          MaterialApp(home: ChatScreen(aiService: fakeService)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('chatInputField')),
          'Test error',
        );
        await tester.tap(find.byKey(const Key('chatSendButton')));
        await tester.pumpAndSettle();

        expect(find.text('Layanan AI Sibuk'), findsOneWidget);
        expect(find.textContaining('API key tidak valid'), findsOneWidget);
        expect(find.text('Coba Lagi'), findsOneWidget);
      },
    );
  });
}
