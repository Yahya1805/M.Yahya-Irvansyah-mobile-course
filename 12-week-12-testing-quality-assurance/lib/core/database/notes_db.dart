import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 4,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_notes_updated_at
        ON notes(updated_at DESC)
      ''');
      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE ai_cache(
          cache_key TEXT PRIMARY KEY,
          answer TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE posts_cache_meta(
          cache_key TEXT PRIMARY KEY,
          etag TEXT,
          last_synced_at TEXT NOT NULL
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          "ALTER TABLE notes ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
        );
        await db.execute(
          'UPDATE notes SET created_at = updated_at WHERE created_at = \'\'',
        );
      }
      if (oldVersion < 3) {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_notes_updated_at
          ON notes(updated_at DESC)
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ai_cache(
            cache_key TEXT PRIMARY KEY,
            answer TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
      }
      if (oldVersion < 4) {
        // Database lama mungkin belum punya cached_posts, jadi buat juga
        // dengan IF NOT EXISTS.
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cached_posts(
            id INTEGER PRIMARY KEY,
            payload TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS posts_cache_meta(
            cache_key TEXT PRIMARY KEY,
            etag TEXT,
            last_synced_at TEXT NOT NULL
          )
        ''');
      }
    },
  );
}
