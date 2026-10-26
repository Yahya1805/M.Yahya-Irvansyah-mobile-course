import 'package:sqflite/sqflite.dart';

import '../../domain/entities/note.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._openDb);

  final Future<Database> Function() _openDb;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      final db = await _openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final List<Note> notes = rows
          .map<Note>((row) => NoteModel.fromMap(row).toEntity())
          .toList();
      return (notes: notes, failure: null);
    } catch (_) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Catatan tidak dapat dimuat. Silakan coba lagi.'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await _openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'notes',
        NoteModel(
          title: title,
          body: body,
          createdAt: now,
          updatedAt: now,
          dirty: true,
        ).toMap(),
      );
      return (
        note: Note(
          id: id,
          title: title,
          body: body,
          createdAt: now,
          updatedAt: now,
          dirty: true,
        ),
        failure: null,
      );
    } catch (_) {
      return (
        note: null,
        failure: LocalFailure(
          'Catatan tidak dapat disimpan. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Future<Failure?> updateNote({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final db = await _openDb();
      final rows = await db.query(
        'notes',
        columns: ['created_at'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const LocalFailure('Catatan tidak ditemukan.');
      }
      final now = DateTime.now();
      await db.update(
        'notes',
        NoteModel(
          id: id,
          title: title,
          body: body,
          createdAt: DateTime.tryParse(
            rows.first['created_at'] as String? ?? '',
          ),
          updatedAt: now,
          dirty: true,
        ).toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [id],
      );
      return null;
    } catch (_) {
      return const LocalFailure(
        'Catatan tidak dapat diperbarui. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<Failure?> deleteNote(int id) async {
    try {
      final db = await _openDb();
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      return null;
    } catch (_) {
      return const LocalFailure(
        'Catatan tidak dapat dihapus. Silakan coba lagi.',
      );
    }
  }
}
