import 'package:sqflite/sqflite.dart';

/// Kontrak cache jawaban AI yang bisa bertahan antar sesi aplikasi.
abstract class AiCacheStore {
  Future<String?> read(String cacheKey);
  Future<void> write(String cacheKey, String answer);
}

/// Cache offline-first berbasis SQLite.
///
/// Jawaban disimpan maksimal 24 jam dan jumlah baris dibatasi agar ukuran
/// database tidak tumbuh tanpa kendali.
class SqfliteAiCacheStore implements AiCacheStore {
  SqfliteAiCacheStore(this._openDb);

  final Future<Database> Function() _openDb;

  static const Duration _ttl = Duration(hours: 24);
  static const int _maxEntries = 100;

  @override
  Future<String?> read(String cacheKey) async {
    try {
      final db = await _openDb();
      final rows = await db.query(
        'ai_cache',
        columns: ['answer', 'cached_at'],
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final cachedAt = DateTime.tryParse(
        rows.first['cached_at'] as String? ?? '',
      );
      if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
        await db.delete(
          'ai_cache',
          where: 'cache_key = ?',
          whereArgs: [cacheKey],
        );
        return null;
      }
      return rows.first['answer'] as String?;
    } catch (_) {
      // Cache tidak boleh membuat fitur utama gagal.
      return null;
    }
  }

  @override
  Future<void> write(String cacheKey, String answer) async {
    try {
      final db = await _openDb();
      await db.insert('ai_cache', {
        'cache_key': cacheKey,
        'answer': answer,
        'cached_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await db.rawDelete('''
        DELETE FROM ai_cache
        WHERE cache_key NOT IN (
          SELECT cache_key FROM ai_cache
          ORDER BY cached_at DESC
          LIMIT $_maxEntries
        )
      ''');
    } catch (_) {
      // Abaikan kegagalan cache; request tetap dianggap berhasil.
    }
  }
}
