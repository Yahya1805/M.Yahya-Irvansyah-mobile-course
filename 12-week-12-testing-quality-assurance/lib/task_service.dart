/// Kontrak abstraksi sumber data untuk mengelola tugas.
/// Memisahkan antarmuka dari implementasi konkret sehingga mudah diuji (testable).
abstract interface class TaskRepository {
  Future<List<String>> getTasks();
}

/// Service layer yang menangani logika bisnis pemanggilan tugas melalui repository.
class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  /// Memuat daftar tugas secara asinkron dari repository.
  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }
}
