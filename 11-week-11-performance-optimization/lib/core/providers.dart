import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_cache.dart';
import '../ai/ai_service.dart';
import 'database/notes_db.dart';

/// Satu instance [AiService] dipakai bersama oleh chat dan AI multimodal.
///
/// Dengan provider ini, cache in-memory tetap hidup saat pengguna berpindah
/// layar (tidak di-reset setiap route dibuka) dan HTTP client tidak dibuat
/// berulang kali. Cache persisten memakai database SQLite yang sama dengan
/// catatan agar tidak ada koneksi database tambahan.
final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService(cache: SqfliteAiCacheStore(openNotesDb));
  ref.onDispose(service.dispose);
  return service;
});
