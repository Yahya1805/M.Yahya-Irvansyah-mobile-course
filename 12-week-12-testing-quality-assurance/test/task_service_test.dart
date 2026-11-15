import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/task_service.dart';

/// Fake implementation of [TaskRepository] untuk keperluan pengujian.
/// Mengendalikan perilaku pengujian secara deterministik tanpa jaringan nyata.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({this.tasks = const [], this.error});

  final List<String> tasks;
  final Exception? error;

  @override
  Future<List<String>> getTasks() async {
    if (error != null) throw error!;
    return tasks;
  }
}

void main() {
  group('TaskService - Asynchronous & Fake Repository Testing', () {
    // 1. Uji skenario sukses dengan data
    test('meneruskan data dari repository', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(tasks: ['Baca materi']);
      final service = TaskService(fakeRepo);

      // Act
      final result = await service.loadTasks();

      // Assert
      expect(result, equals(['Baca materi']));
    });

    // 2. Uji skenario sukses dengan daftar kosong
    test('mengembalikan daftar kosong jika repository tidak memiliki data tugas', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(tasks: []);
      final service = TaskService(fakeRepo);

      // Act
      final result = await service.loadTasks();

      // Assert
      expect(result, isEmpty);
    });

    // 3. Uji integritas urutan dan kelengkapan data jamak
    test('mempertahankan urutan dan seluruh elemen dari repository', () async {
      // Arrange
      final expectedTasks = [
        'Baca modul testing',
        'Tulis unit test',
        'Jalankan pengujian',
      ];
      final fakeRepo = FakeTaskRepository(tasks: expectedTasks);
      final service = TaskService(fakeRepo);

      // Act
      final result = await service.loadTasks();

      // Assert
      expect(result.length, equals(3));
      expect(result, equals(expectedTasks));
    });

    // 4. Uji skenario kegagalan: memastikan error dilemparkan dan TIDAK tertelan menjadi list kosong
    test('melemparkan exception ketika repository mengalami kegagalan', () async {
      // Arrange
      final simulatedError = Exception('Koneksi database/jaringan gagal');
      final fakeRepo = FakeTaskRepository(error: simulatedError);
      final service = TaskService(fakeRepo);

      // Act & Assert
      // Memastikan error tidak berubah diam-diam menjadi daftar kosong ([])
      expect(
        () => service.loadTasks(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'pesan error',
          contains('Koneksi database/jaringan gagal'),
        )),
      );
    });

    // 5. Uji skenario tipe error spesifik (misal FormatException atau StateError)
    test('melemparkan subtype exception yang sesuai ketika repository gagal', () async {
      // Arrange
      final specificError = const FormatException('Format payload tidak valid');
      final fakeRepo = FakeTaskRepository(error: specificError);
      final service = TaskService(fakeRepo);

      // Act & Assert
      expect(
        () => service.loadTasks(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
