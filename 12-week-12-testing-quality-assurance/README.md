# Week 12 — Testing & Quality Assurance

Portofolio implementasi **Pengujian Perangkat Lunak dan Jaminan Kualitas (Software Testing & QA)** untuk mata kuliah **Pemrograman Mobile**. Folder ini mengimplementasikan strategi pengujian menyeluruh pada aplikasi Flutter, mencakup **Unit Testing**, **Asynchronous & Fake Repository Testing**, **Edge Cases Validation**, dan persiapan untuk **Widget Testing** serta **Integration Testing**.

---

## 📌 Ringkasan Capaian

* **Mahasiswa**: M. Yahya Irvansyah
* **Mata Kuliah**: Pemrograman Mobile (Semester Genap 2026)
* **Branch Git**:
  * `feat/unit-testing-edge-cases` — implementasi validasi judul tugas dan pengujian kasus tepi (Bagian 3)
  * `feat/async-fake-repository-testing` — pengujian kode asinkron & isolasi dependensi via Fake Repository (Bagian 4)
* **Baseline**: Project Week 11 (`11-week-11-performance-optimization`) yang membawa arsitektur bersih (*Clean Architecture*) dari Week 7 hingga optimasi performa Week 11.
* **Fokus Pengujian**:
  1. Pengujian unit berbasis perilaku (*behavior-driven*) dengan pola AAA (*Arrange, Act, Assert*).
  2. Cakupan kasus tepi (*edge cases*) dan batas input (*boundary values*).
  3. Pemisahan kontrak sumber data (*Interface Segregation*) & penghindaran dependensi jaringan langsung.
  4. Penggunaan *Test Double* (*Fake Repository*) untuk simulasi kondisi sukses dan kondisi gagal.

---

## 🧭 Strategi Pengujian Aplikasi Flutter (Bagian 1 & 2)

Pengujian dirancang mengikuti piramida pengujian (*Testing Pyramid*):

| Tingkatan Uji | Cakupan yang Diperiksa | Karakteristik | Implementasi pada Proyek |
| :--- | :--- | :--- | :--- |
| **Unit Test** | Logika fungsi, validasi, dan use case terisolasi tanpa UI | Cepat, deterministik, biaya pemeliharaan rendah | `isValidTaskTitle`, `TaskService`, Use Cases |
| **Widget Test** | Rendering tampilan dan interaksi komponen antarmuka | Berjalan di lingkungan headless tanpa perangkat fisik | Validasi form, status kosong (*empty state*), list |
| **Integration Test** | Alur lengkap aplikasi dari awal hingga akhir (*End-to-End*) | Mensimulasikan pengguna nyata di emulator / perangkat | Tambah catatan $\rightarrow$ pencarian $\rightarrow$ verifikasi list |

### Prinsip Testability: Rancang Kode agar Mudah Diuji
1. **Separation of Concerns**: Widget hanya menangani tampilan dan interaksi pengguna. Pengambilan dan manipulasi data didelegasikan ke *Service* atau *Repository*.
2. **Dependency Inversion**: Service bergantung pada abstraksi (`TaskRepository`), bukan implementasi konkret (seperti HTTP client atau database lokal). Hal ini memungkinkan penggantian sumber data dengan `FakeTaskRepository` saat pengujian.

---

## 🧪 Dokumentasi Implementasi Pengujian

### Bagian 3: Pengujian Unit dan Kasus Tepi (*Edge Cases*)

#### 1. Implementasi Logika Validasi (`lib/is_valid_task_title.dart`)
Aturan bisnis: Judul tugas harus mengandung teks yang valid setelah spasi di awal dan di akhir diabaikan.
```dart
bool isValidTaskTitle(String value) {
  return value.trim().isNotEmpty;
}
```

#### 2. Implementasi Pengujian dengan Pola AAA (`test/is_valid_task_title_test.dart`)
Setiap pengujian menerapkan pola **Arrange, Act, Assert** secara disiplin:
* **Arrange**: Menyiapkan variabel input dan konfigurasi awal.
* **Act**: Menjalankan fungsi `isValidTaskTitle(input)`.
* **Assert**: Memverifikasi hasil kembalian dengan `expect(..., isTrue/isFalse)`.

#### 3. Matriks Kasus Tepi (*Edge Cases*) yang Diuji:
* **Teks Normal Valid**: Menerima string standar seperti `'Belajar Flutter'`.
* **String Kosong**: Menolak `""`.
* **Spasi Kosong Standar**: Menolak `"   "`.
* **Whitespace Khusus & Campuran**: Menolak string yang hanya berisi tab (`\t\t\t`), newline (`\n\n\r`), atau kombinasinya (`' \t \n \r '`).
* **Spasi Ekstrem (*Leading/Trailing*)**: Menerima input dengan spasi berlebih di awal/akhir karena `.trim()` membersihkannya.
* **Batas Terpendek (*Boundary*)**: Menerima 1 karakter non-spasi tunggal (`'A'`, `'1'`, `'?'`).
* **Karakter Unicode & Emoji**: Menerima judul dengan emoji (`'🎯 Testing QA'`, `'🔥'`).
* **Batas Teks Panjang (*Stress Test*)**: Menerima string panjang hingga 1000 karakter (`'A' * 1000`).

---

### Bagian 4: Menguji Kode Asinkron dan Dependensi

#### 1. Pemisahan Kontrak Sumber Data (`lib/task_service.dart`)
Untuk mencegah ketergantungan pada jaringan API atau database nyata yang fluktuatif, didefinisikan antarmuka kontrak:
```dart
abstract interface class TaskRepository {
  Future<List<String>> getTasks();
}

class TaskService {
  TaskService(this._repository);

  final TaskRepository _repository;

  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }
}
```

#### 2. Implementasi Fake Repository (`test/task_service_test.dart`)
Implementasi sederhana untuk mengendalikan perilaku pengujian secara deterministik:
```dart
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
```

#### 3. Skenario Pengujian Asinkron yang Diuji:
1. **Meneruskan Data Sukses**: Memastikan data `['Baca materi']` diteruskan dengan benar ke pemanggil.
2. **Daftar Kosong (*Empty List*)**: Memastikan fungsi mengembalikan `[]` jika repository tidak memiliki data.
3. **Integritas Urutan & Jumlah**: Memastikan urutan data jamak (misal 3 item tugas) tetap konsisten dan tidak berubah.
4. **Penanganan Kegagalan (*Error Handling*)**: Memastikan ketika repository mengalami exception, error dilemparkan (`throwsA(isA<Exception>())`) dan **tidak berubah diam-diam menjadi daftar kosong**.
5. **Subtipe Exception Spesifik**: Memastikan tipe error khusus seperti `FormatException` dilemparkan dengan tepat sesuai rancangan sistem.

---

## 📁 Struktur File Week 12

```text
12-week-12-testing-quality-assurance/
├── lib/
│   ├── is_valid_task_title.dart     # Logika validasi judul tugas
│   ├── task_service.dart            # Kontrak TaskRepository & TaskService
│   ├── main.dart                    # Entry point aplikasi
│   ├── core/                        # Database, network, performance utils
│   └── features/                    # Modul Notes, Posts, Gallery, AI
├── test/
│   ├── is_valid_task_title_test.dart# Unit test & edge cases (Bagian 3)
│   ├── task_service_test.dart       # Async & Fake Repository test (Bagian 4)
│   ├── core/                        # Pengujian format & network interceptor
│   └── features/                    # Pengujian modul notes, posts, ai
├── README.md                        # Dokumentasi laporan pengujian
└── pubspec.yaml                     # Konfigurasi dependensi project
```

---

## 🚀 Panduan Menjalankan Pengujian

Jalankan pengujian unit spesifik melalui terminal:

```bash
# Menjalankan pengujian validasi judul tugas (Bagian 3)
flutter test test/is_valid_task_title_test.dart

# Menjalankan pengujian asinkron dan Fake Repository (Bagian 4)
flutter test test/task_service_test.dart

# Menjalankan seluruh pengujian di dalam folder
flutter test
```

---

## 🔄 Riwayat Branch & Langkah Push Git

Untuk mempublikasikan perubahan pada branch `feat/async-fake-repository-testing`:

```bash
# 1. Pastikan branch aktif saat ini
git branch --show-current
# Output: feat/async-fake-repository-testing

# 2. Periksa status perubahan
git status

# 3. Tambahkan perubahan pada folder week 12
git add 12-week-12-testing-quality-assurance/

# 4. Commit perubahan
git commit -m "feat(testing): implementasi kontrak TaskRepository, TaskService, FakeRepository, dan dokumentasi README week 12"

# 5. Push branch baru ke remote GitHub
git push -u origin feat/async-fake-repository-testing
```
