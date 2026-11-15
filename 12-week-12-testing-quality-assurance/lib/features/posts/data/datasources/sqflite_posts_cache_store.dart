import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/post.dart';
import '../models/post_model.dart';
import 'posts_cache_store.dart';

/// Cache postingan di SQLite, memakai tabel `cached_posts` dan
/// `posts_cache_meta` pada database yang sama dengan catatan.
class SqflitePostsCacheStore implements PostsCacheStore {
  SqflitePostsCacheStore(this._openDb);

  final Future<Database> Function() _openDb;

  static const String _cacheKey = 'posts';

  @override
  Future<List<Post>> readPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');

    return rows
        .map<Post?>((row) {
          final payload = row['payload'] as String?;
          if (payload == null || payload.isEmpty) return null;
          try {
            final json = jsonDecode(payload);
            if (json is! Map<dynamic, dynamic>) return null;
            return PostModel.fromJson(Map<String, dynamic>.from(json))
                .toEntity();
          } on FormatException {
            // Baris rusak tidak boleh menggagalkan seluruh cache.
            return null;
          }
        })
        .whereType<Post>()
        .toList();
  }

  @override
  Future<void> writePosts(List<Post> posts) async {
    final db = await _openDb();
    final cachedAt = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete('cached_posts');
      if (posts.isEmpty) return;

      final batch = txn.batch();
      for (final post in posts) {
        batch.insert('cached_posts', {
          'id': post.id,
          'payload': jsonEncode(
            PostModel(
              id: post.id,
              userId: post.userId,
              title: post.title,
              body: post.body,
            ).toJson(),
          ),
          'cached_at': cachedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<PostsCacheMeta> readMeta() async {
    final db = await _openDb();
    final rows = await db.query(
      'posts_cache_meta',
      where: 'cache_key = ?',
      whereArgs: [_cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return const PostsCacheMeta();

    final row = rows.first;
    return PostsCacheMeta(
      etag: row['etag'] as String?,
      lastSyncedAt: DateTime.tryParse(row['last_synced_at'] as String? ?? ''),
    );
  }

  @override
  Future<void> writeMeta({String? etag, required DateTime syncedAt}) async {
    final db = await _openDb();
    await db.insert('posts_cache_meta', {
      'cache_key': _cacheKey,
      'etag': etag,
      'last_synced_at': syncedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
