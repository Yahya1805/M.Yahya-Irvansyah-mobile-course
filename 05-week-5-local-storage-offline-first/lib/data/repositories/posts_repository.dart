import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../local/post.dart';

class PostsRepository {
  PostsRepository({Dio? dio, Future<Database> Function()? openDb})
      : _dio = dio ?? Dio(),
        _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  Future<List<Post>> loadPostsCacheFirst({bool forceOffline = false}) async {
    final cached = await _readCachedPosts();
    if (!forceOffline) {
      unawaited(refreshPosts());
    }
    return cached;
  }

  Future<List<Post>> readCachedPosts() => _readCachedPosts();

  Future<void> refreshPosts() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://jsonplaceholder.typicode.com/posts',
      );
      final data = response.data ?? const <dynamic>[];
      final posts = data
          .whereType<Map<String, dynamic>>()
          .map(Post.fromJson)
          .toList();
      await _writeCachedPosts(posts);
    } on DioException {
      // Cache tetap dipertahankan ketika jaringan gagal.
    }
  }

  Future<List<Post>> _readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows
        .map((row) => Post.fromJson(
              jsonDecode(row['payload'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> _writeCachedPosts(List<Post> posts) async {
    final db = await _openDb();
    await db.transaction((transaction) async {
      for (final post in posts) {
        await transaction.insert(
          'cached_posts',
          {
            'id': post.id,
            'payload': jsonEncode(post.toJson()),
            'cached_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}