import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/task_service.dart';

/// Fake implementation of [TaskRepository] untuk keperluan pengujian.
/// Mengendalikan perilaku pengujian secara deterministik tanpa jaringan nyata.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({List<String>? tasks, this.error})
      : tasks = List<String>.from(tasks ?? const []);

  final List<String> tasks;
  final Exception? error;

  @override
  Future<List<String>> getTasks() async {
    if (error != null) throw error!;
    return List<String>.unmodifiable(tasks);
  }

  @override
  Future<void> addTask(String task) async {
    if (error != null) throw error!;
    tasks.add(task);
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

    // 4. Uji penambahan data valid melalui saveTask
    test('menyimpan tugas baru yang valid ke repository', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository(tasks: []);
      final service = TaskService(fakeRepo);

      // Act
      final success = await service.saveTask('Tugas Pertama');
      final tasks = await service.loadTasks();

      // Assert
      expect(success, isTrue);
      expect(tasks, contains('Tugas Pertama'));
    });

    // 5. Uji skenario kegagalan: memastikan error dilemparkan dan TIDAK tertelan menjadi list kosong
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

    // 6. Uji skenario validasi bisnis saveTask: melempar FormatException jika judul kosong
    test('saveTask melempar FormatException jika judul kosong atau spasi', () async {
      // Arrange
      final fakeRepo = FakeTaskRepository();
      final service = TaskService(fakeRepo);

      // Act & Assert
      expect(
        () => service.saveTask('   '),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
