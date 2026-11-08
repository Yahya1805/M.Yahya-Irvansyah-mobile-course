import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/performance/image_optimizer.dart';
import 'ai_cache.dart';

class AiServiceException implements Exception {
  AiServiceException(
    this.message, {
    this.isQuotaExceeded = false,
    this.isOffline = false,
  });
  final String message;
  final bool isQuotaExceeded;
  final bool isOffline;

  @override
  String toString() => message;
}

class AiService {
  AiService({
    http.Client? client,
    FlutterSecureStorage? storage,
    AiCacheStore? cache,
    this.maxDailyRequests = 20,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       // ignore: prefer_initializing_formals
       _cache = cache,
       _ownsClient = client == null;

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final AiCacheStore? _cache;
  final bool _ownsClient;
  final int maxDailyRequests;

  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // Cache lokal in-memory dengan batas ukuran (LRU sederhana).
  static const int _maxCacheEntries = 50;
  final Map<String, String> _responseCache = <String, String>{};

  // Database fallback lokal jika AI API sedang offline / down
  static final Map<String, String> _localFallbackAnswers = {
    'jadwal': 'Mode Offline: Jadwal perkuliahan Senin adalah Pemrograman Mobile di Lab Komputer.',
    'catatan': 'Mode Offline: Anda dapat melihat dan mengelola catatan offline pada menu Catatan.',
    'bantuan': 'Mode Offline: Asisten kampus siap membantu pertanyaan seputar jadwal, catatan, dan profil mahasiswa.',
  };

  /// Sanitasi Privasi: Masking NIK, nomor telepon, dan email sebelum dikirim ke AI
  String sanitizePrompt(String input) {
    var sanitized = input;
    // Masking 16 digit NIK
    sanitized = sanitized.replaceAll(
      RegExp(r'\b\d{16}\b'),
      '[NIK_DIRAHASIAKAN]',
    );
    // Masking nomor telepon Indonesia (+62 / 08xx)
    sanitized = sanitized.replaceAll(
      RegExp(r'(\+62|08)\d{8,12}'),
      '[NO_TELEPON_DIRAHASIAKAN]',
    );
    // Masking alamat email
    sanitized = sanitized.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[EMAIL_DIRAHASIAKAN]',
    );
    return sanitized;
  }

  Future<String> ask(String question) async {
    final cleanPrompt = sanitizePrompt(question).trim();

    // 1. Cek Cache Lokal (Menghemat kuota & biaya token)
    final cacheKey = cleanPrompt.toLowerCase();
    final cached = await _readCache(cacheKey);
    if (cached != null) {
      return '$cached (Diambil dari Cache Lokal)';
    }

    // 2. Kontrol Biaya: Batasi Kuota Harian (Rate Limiting)
    await _checkAndIncrementDailyQuota();

    // 3. Eksekusi Request ke API dengan Fallback Otomatis
    try {
      final apiKey = await _getValidApiKey();
      final response = await _client
          .post(
            Uri.parse('$_apiUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': cleanPrompt},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      final result = _parseGeminiResponse(response);
      await _writeCache(cacheKey, result);
      return result;
    } on AiServiceException {
      rethrow;
    } catch (e) {
      // 4. Fallback ke Data Lokal saat Offline / Error
      return _matchFallbackAnswer(cleanPrompt);
    }
  }

  Stream<String> askStream(String question) async* {
    final fullAnswer = await ask(question);
    final words = fullAnswer.split(' ');
    for (var i = 0; i < words.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      yield words.sublist(0, i + 1).join(' ');
    }
  }

  Future<String> recognizeText(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    await _checkAndIncrementDailyQuota();
    try {
      final apiKey = await _getValidApiKey();
      final optimized = await ImageOptimizer.optimizeForAi(
        imageBytes,
        mimeType: mimeType,
      );
      final base64Image = base64Encode(optimized.bytes);

      final response = await _client
          .post(
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
                      'inline_data': {
                        'mime_type': optimized.mimeType,
                        'data': base64Image,
                      },
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _parseGeminiResponse(response);
    } on AiServiceException {
      rethrow;
    } catch (_) {
      return 'Layanan OCR Offline: Teks pada gambar belum dapat dipindai saat ini. Coba periksa koneksi internet Anda.';
    }
  }

  Future<String> describeImage(
    Uint8List imageBytes, {
    String prompt =
        'Jelaskan isi gambar ini secara ringkas dalam Bahasa Indonesia.',
    String mimeType = 'image/jpeg',
  }) async {
    await _checkAndIncrementDailyQuota();
    try {
      final apiKey = await _getValidApiKey();
      final optimized = await ImageOptimizer.optimizeForAi(
        imageBytes,
        mimeType: mimeType,
      );
      final base64Image = base64Encode(optimized.bytes);

      final response = await _client
          .post(
            Uri.parse('$_apiUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inline_data': {
                        'mime_type': optimized.mimeType,
                        'data': base64Image,
                      },
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _parseGeminiResponse(response);
    } on AiServiceException {
      rethrow;
    } catch (_) {
      return 'Layanan Vision Offline: Deskripsi gambar tidak tersedia tanpa koneksi jaringan.';
    }
  }

  Future<String> speechToText(
    Uint8List audioBytes, {
    String mimeType = 'audio/mp3',
  }) async {
    await _checkAndIncrementDailyQuota();
    try {
      final apiKey = await _getValidApiKey();
      final base64Audio = base64Encode(audioBytes);

      final response = await _client
          .post(
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
                      'inline_data': {
                        'mime_type': mimeType,
                        'data': base64Audio,
                      },
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _parseGeminiResponse(response);
    } on AiServiceException {
      rethrow;
    } catch (_) {
      return 'Layanan Speech-to-Text Offline: Transkripsi suara gagal diproses secara lokal.';
    }
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
      throw AiServiceException(
        'API key tidak tersedia. Silakan atur di pengaturan.',
      );
    }
    return apiKey;
  }

  Future<void> _checkAndIncrementDailyQuota() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final countStr = await _storage.read(key: 'req_count_$today');
    final count = int.tryParse(countStr ?? '0') ?? 0;

    if (count >= maxDailyRequests) {
      throw AiServiceException(
        'Batas kuota harian tercapai ($maxDailyRequests request/hari). '
        'Gunakan cache lokal atau coba lagi besok untuk mencegah lonjakan biaya.',
        isQuotaExceeded: true,
      );
    }
    await _storage.write(key: 'req_count_$today', value: '${count + 1}');
  }

  Future<String?> _readCache(String key) async {
    final inMemory = _responseCache.remove(key);
    if (inMemory != null) {
      // Pindahkan ke urutan terakhir sebagai penanda recently used.
      _responseCache[key] = inMemory;
      return inMemory;
    }

    try {
      final persisted = await _cache?.read(key);
      if (persisted != null) _putMemoryCache(key, persisted);
      return persisted;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, String value) async {
    _putMemoryCache(key, value);
    try {
      await _cache?.write(key, value);
    } catch (_) {
      // Cache persisten bersifat best-effort.
    }
  }

  void _putMemoryCache(String key, String value) {
    _responseCache.remove(key);
    _responseCache[key] = value;
    while (_responseCache.length > _maxCacheEntries) {
      _responseCache.remove(_responseCache.keys.first);
    }
  }

  /// Menutup HTTP client hanya jika dibuat sendiri oleh [AiService].
  void dispose() {
    if (_ownsClient) _client.close();
  }

  String _matchFallbackAnswer(String query) {
    final lower = query.toLowerCase();
    for (final entry in _localFallbackAnswers.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Layanan AI sedang sibuk/offline. Sistem beralih ke mode offline. Silakan coba beberapa saat lagi.';
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
    } else if (response.statusCode == 429) {
      throw AiServiceException(
        'Batas frekuensi request AI (Rate Limit) tercapai. Silakan coba lagi nanti.',
      );
    } else {
      throw AiServiceException(
        'Gagal memanggil AI API: HTTP ${response.statusCode}',
      );
    }
  }
}
