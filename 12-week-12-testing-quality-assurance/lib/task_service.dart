import 'is_valid_task_title.dart';

/// Kontrak abstraksi sumber data untuk mengelola tugas.
/// Memisahkan antarmuka dari implementasi konkret sehingga mudah diuji (testable).
abstract interface class TaskRepository {
  Future<List<String>> getTasks();
  Future<void> addTask(String task);
}

/// Service layer yang menangani logika bisnis pemanggilan tugas melalui repository.
class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  /// Memuat daftar tugas secara asinkron dari repository.
  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }

  /// Menyimpan tugas baru setelah memvalidasi aturan bisnis.
  Future<bool> saveTask(String title) async {
    if (!isValidTaskTitle(title)) {
      throw const FormatException('Judul tugas tidak boleh kosong');
    }
    await _repository.addTask(title.trim());
    return true;
  }
}
