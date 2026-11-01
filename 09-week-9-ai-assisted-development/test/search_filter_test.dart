import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/notes/domain/entities/note.dart';
import 'package:my_app/features/notes/domain/failures/failure.dart';
import 'package:my_app/features/notes/domain/repositories/note_repository.dart';
import 'package:my_app/features/notes/domain/usecases/filter_notes.dart';
import 'package:my_app/features/notes/presentation/pages/notes_page.dart';
import 'package:my_app/features/notes/presentation/providers/notes_providers.dart';

void main() {
  final sampleNotes = [
    Note(
      id: 1,
      title: 'Belanja Mingguan Pasar',
      body: 'Sayur, buah, telur',
      updatedAt: DateTime(2026, 3, 1),
    ),
    Note(
      id: 2,
      title: 'Daftar BELANJA Elektronik',
      body: 'Mouse, keyboard',
      updatedAt: DateTime(2026, 3, 2),
    ),
    Note(
      id: 3,
      title: 'Kuliah Pemrograman Mobile',
      body: 'Clean architecture & AI',
      updatedAt: DateTime(2026, 3, 3),
    ),
  ];

  group('Unit Tests: filterNotes Pure Use Case', () {
    test('filter abaikan huruf besar/kecil (case-insensitive)', () {
      final result = filterNotes(sampleNotes, 'belanja');
      expect(result, hasLength(2));
      expect(result.map((n) => n.id), containsAll([1, 2]));
    });

    test('query tak cocok kembalikan kosong (empty state trigger)', () {
      final result = filterNotes(sampleNotes, 'zzz-tak-ada');
      expect(result, isEmpty);
    });

    test('query kosong mengembalikan seluruh catatan', () {
      final result = filterNotes(sampleNotes, '');
      expect(result, hasLength(3));
    });

    test('query hanya spasi (whitespace) mengembalikan seluruh catatan', () {
      final result = filterNotes(sampleNotes, '   ');
      expect(result, hasLength(3));
    });

    test('mencocokkan substring di tengah kata', () {
      final result = filterNotes(sampleNotes, 'Mobile');
      expect(result, hasLength(1));
      expect(result.first.title, 'Kuliah Pemrograman Mobile');
    });

    test('mempertahankan urutan catatan setelah difilter', () {
      final result = filterNotes(sampleNotes, 'belanja');
      expect(result.first.id, 1);
      expect(result.last.id, 2);
      expect(result.first.updatedAt.isBefore(result.last.updatedAt), isTrue);
    });
  });

  group('Widget Test: Empty State saat Pencarian Tidak Ditemukan', () {
    testWidgets(
        'menampilkan empty state Icons.search_off saat query tidak cocok',
        (tester) async {
      final repository = _FakeNoteRepository()
        ..notes.addAll(sampleNotes);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [noteRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: NotesPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan 3 catatan awal muncul
      expect(find.text('Belanja Mingguan Pasar'), findsOneWidget);
      expect(find.text('Kuliah Pemrograman Mobile'), findsOneWidget);

      // Masukkan query pencarian yang tidak ada di daftar
      await tester.enterText(
          find.byKey(const Key('searchNotesField')), 'zzz-tak-ada');
      await tester.pumpAndSettle();

      // Verifikasi Catatan lama hilang dari tampilan
      expect(find.text('Belanja Mingguan Pasar'), findsNothing);
      expect(find.text('Kuliah Pemrograman Mobile'), findsNothing);

      // Verifikasi Empty State muncul dengan icon dan teks yang tepat
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(
        find.text('Tidak ada catatan yang cocok dengan "zzz-tak-ada"'),
        findsOneWidget,
      );

      // Bersihkan pencarian lewat tombol clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Catatan harus kembali tampil
      expect(find.text('Belanja Mingguan Pasar'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsNothing);
    });
  });
}

class _FakeNoteRepository implements NoteRepository {
  final List<Note> notes = [];

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: List<Note>.of(notes), failure: null);

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    notes.add(note);
    return (note: note, failure: null);
  }

  @override
  Future<Failure?> updateNote({
    required int id,
    required String title,
    required String body,
  }) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index < 0) return const LocalFailure('Catatan tidak ditemukan.');
    notes[index] = Note(
      id: id,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    return null;
  }

  @override
  Future<Failure?> deleteNote(int id) async {
    notes.removeWhere((n) => n.id == id);
    return null;
  }
}

