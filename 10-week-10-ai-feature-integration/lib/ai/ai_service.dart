import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  AiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String> ask(String question) async {
    final apiKey = await _getValidApiKey();

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': question},
            ],
          },
        ],
      }),
    );

    return _parseGeminiResponse(response);
  }

  /// Streaming response simulasi token-by-token untuk antarmuka interaktif mobile
  Stream<String> askStream(String question) async* {
    final fullAnswer = await ask(question);
    final words = fullAnswer.split(' ');
    for (var i = 0; i < words.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      yield words.sublist(0, i + 1).join(' ');
    }
  }

  /// OCR (Optical Character Recognition): Mengekstrak teks dari byte gambar
  Future<String> recognizeText(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final apiKey = await _getValidApiKey();
    final base64Image = base64Encode(imageBytes);

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Tolong lakukan OCR. Ekstrak seluruh teks yang tertulis pada gambar ini secara akurat. '
                    'Tuliskan kembali teks tersebut tanpa tambahan opini atau komentar.',
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
            ],
          },
        ],
      }),
    );

    return _parseGeminiResponse(response);
  }

  /// Image Understanding: Menganalisis dan mendeskripsikan konten visual gambar
  Future<String> describeImage(
    Uint8List imageBytes, {
    String prompt =
        'Jelaskan isi gambar ini secara ringkas dalam Bahasa Indonesia.',
    String mimeType = 'image/jpeg',
  }) async {
    final apiKey = await _getValidApiKey();
    final base64Image = base64Encode(imageBytes);

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
            ],
          },
        ],
      }),
    );

    return _parseGeminiResponse(response);
  }

  /// Speech-to-Text: Mengonversi byte rekaman audio menjadi teks
  Future<String> speechToText(
    Uint8List audioBytes, {
    String mimeType = 'audio/mp3',
  }) async {
    final apiKey = await _getValidApiKey();
    final base64Audio = base64Encode(audioBytes);

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Transkripsikan rekaman suara berikut menjadi teks Bahasa Indonesia yang rapi dan benar.',
              },
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Audio},
              },
            ],
          },
        ],
      }),
    );

    return _parseGeminiResponse(response);
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }

  Future<String?> getApiKey() async {
    return _storage.read(key: 'ai_api_key');
  }

  Future<String> _getValidApiKey() async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }
    return apiKey;
  }

  String _parseGeminiResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String;
        }
      }
      return 'Tidak ada respons yang dihasilkan oleh model.';
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }
}
