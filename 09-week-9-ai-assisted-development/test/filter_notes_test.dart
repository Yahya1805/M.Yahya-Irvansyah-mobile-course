import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/notes/domain/entities/note.dart';
import 'package:my_app/features/notes/domain/usecases/filter_notes.dart';

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

  group('filterNotes Use Case / Invariant Tests', () {
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
  });
}
