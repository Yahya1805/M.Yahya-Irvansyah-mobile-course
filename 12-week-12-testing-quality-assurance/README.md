# Week 12 — Testing & Quality Assurance

Portofolio implementasi **Pengujian Perangkat Lunak dan Jaminan Kualitas (Software Testing & QA)** untuk mata kuliah **Pemrograman Mobile**. Folder ini mengimplementasikan strategi pengujian menyeluruh pada aplikasi Flutter, mencakup **Unit Testing**, **Asynchronous & Fake Repository Testing**, **Edge Cases Validation**, dan **Widget & UI Interaction Testing**.

---

## 📌 Ringkasan Capaian

* **Mahasiswa**: M. Yahya Irvansyah
* **Mata Kuliah**: Pemrograman Mobile (Semester Genap 2026)
* **Branch Git**:
  * `feat/unit-testing-edge-cases` — implementasi validasi judul tugas dan pengujian kasus tepi (Bagian 3)
  * `feat/async-fake-repository-testing` — pengujian kode asinkron & isolasi dependensi via Fake Repository (Bagian 4)
  * `feat/widget-testing-ui-interaction` — pengujian widget, interaksi form, empty state, loading, dan error state (Bagian 5)
* **Baseline**: Project Week 11 (`11-week-11-performance-optimization`) yang membawa arsitektur bersih (*Clean Architecture*) dari Week 7 hingga optimasi performa Week 11.
* **Fokus Pengujian**:
  1. Pengujian unit berbasis perilaku (*behavior-driven*) dengan pola AAA (*Arrange, Act, Assert*).
  2. Cakupan kasus tepi (*edge cases*) dan batas input (*boundary values*).
  3. Pemisahan kontrak sumber data (*Interface Segregation*) & penghindaran dependensi jaringan langsung.
  4. Penggunaan *Test Double* (*Fake Repository*) untuk simulasi kondisi sukses dan kondisi gagal.
  5. Pengujian antarmuka widget: rendering, interaksi pengguna (`enterText`, `tap`), determinisme frame (`pump`, `pumpAndSettle`), serta penanganan berbagai status UI.

---

## 🧭 Strategi Pengujian Aplikasi Flutter (Bagian 1 & 2)

Pengujian dirancang mengikuti piramida pengujian (*Testing Pyramid*):

| Tingkatan Uji | Cakupan yang Diperiksa | Karakteristik | Implementasi pada Proyek |
| :--- | :--- | :--- | :--- |
| **Unit Test** | Logika fungsi, validasi, dan use case terisolasi tanpa UI | Cepat, deterministik, biaya pemeliharaan rendah | `isValidTaskTitle`, `TaskService`, Use Cases |
| **Widget Test** | Rendering tampilan dan interaksi komponen antarmuka | Berjalan di lingkungan headless tanpa perangkat fisik | `TaskListPage`, validasi form, empty state, loading |
| **Integration Test** | Alur lengkap aplikasi dari awal hingga akhir (*End-to-End*) | Mensimulasikan pengguna nyata di emulator / perangkat | Alur navigasi $\rightarrow$ form input $\rightarrow$ daftar |

### Prinsip Testability: Rancang Kode agar Mudah Diuji
1. **Separation of Concerns**: Widget hanya menangani tampilan dan interaksi pengguna. Pengambilan dan manipulasi data didelegasikan ke *Service* atau *Repository*.
2. **Dependency Inversion**: Service dan widget bergantung pada abstraksi (`TaskRepository`), bukan implementasi konkret. Hal ini memungkinkan penggantian sumber data dengan `FakeTaskRepository` saat pengujian widget.

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

### Bagian 5: Pengujian Widget dan Interaksi Antarmuka

#### 1. Implementasi Komponen UI (`lib/task_list_page.dart`)
Widget `TaskListPage` dirancang untuk mengintegrasikan form input, validasi, dan rendering daftar tugas dengan `Key` eksplisit:
* `Key('task-title-field')`: Input teks judul tugas.
* `Key('save-task-button')`: Tombol simpan tugas baru.
* `Key('task-loading-indicator')`: Indikator pemuatan data asinkron.
* `Key('task-empty-state')`: Tampilan saat daftar tugas masih kosong (`Belum ada tugas`).
* `Key('task-error-message')`: Pesan error ketika pemanggilan repository gagal.
* `Key('task-list')`: Daftar tugas yang berhasil dimuat/ditambahkan.

#### 2. Pengujian Tampilan & Interaksi (`test/task_list_page_test.dart`)
Pengujian menggunakan `WidgetTester` untuk mensimulasikan interaksi nyata tanpa jeda buatan (`Future.delayed` dihindari):
1. **Membangun Widget & Memeriksa Judul**: Menggunakan `tester.pumpWidget()` dan memverifikasi elemen teks `'Daftar tugas'` dengan `find.text()`.
2. **Status Data Kosong (*Empty State*)**: Memastikan saat aplikasi baru dibuka, pesan `'Belum ada tugas'` muncul dan `ListView` belum dirender.
3. **Interaksi Form & Penambahan Tugas**:
   * Memasukkan teks melalui `tester.enterText(find.byKey(Key('task-title-field')), 'Baca materi')`.
   * Menekan tombol melalui `tester.tap(find.byKey(Key('save-task-button')))`.
   * Merender pembaruan state dengan `tester.pumpAndSettle()`.
   * Memverifikasi teks `'Baca materi'` muncul pada layar dan input field otomatis dibersihkan.
4. **Validasi Input Tidak Valid**: Menekan simpan saat field kosong atau hanya berisi spasi `"   "`, lalu memverifikasi pesan `'Judul tidak boleh kosong'` muncul dan tidak ada tugas baru yang dimasukkan.
5. **Indikator Loading Terkendali**: Menggunakan `Completer` pada `FakeTaskRepositoryForWidget` untuk memverifikasi `CircularProgressIndicator` tampil saat proses memuat, dan hilang setelah `pumpAndSettle()`.
6. **Penanganan Error pada UI**: Memastikan pesan kesalahan jaringan dari repository ditampilkan dengan tepat pada antarmuka.

---

## 📁 Struktur File Week 12

```text
12-week-12-testing-quality-assurance/
├── lib/
│   ├── is_valid_task_title.dart     # Logika validasi judul tugas (Bagian 3)
│   ├── task_service.dart            # Kontrak TaskRepository & TaskService (Bagian 4)
│   ├── task_list_page.dart          # Halaman UI Tugas & Form (Bagian 5)
│   ├── main.dart                    # Entry point aplikasi
│   ├── core/                        # Database, network, performance utils
│   └── features/                    # Modul Notes, Posts, Gallery, AI
├── test/
│   ├── is_valid_task_title_test.dart# Unit test & edge cases (Bagian 3)
│   ├── task_service_test.dart       # Async & Fake Repository test (Bagian 4)
│   ├── task_list_page_test.dart     # Widget & UI interaction test (Bagian 5)
│   ├── core/                        # Pengujian format & network interceptor
│   └── features/                    # Pengujian modul notes, posts, ai
├── README.md                        # Dokumentasi lengkap pengujian Week 12
└── pubspec.yaml                     # Konfigurasi dependensi project
```

---

## 🚀 Panduan Menjalankan Pengujian

Jalankan pengujian melalui terminal:

```bash
# Menjalankan pengujian validasi judul tugas (Bagian 3)
flutter test test/is_valid_task_title_test.dart

# Menjalankan pengujian asinkron dan Fake Repository (Bagian 4)
flutter test test/task_service_test.dart

# Menjalankan pengujian widget dan interaksi pengguna (Bagian 5)
flutter test test/task_list_page_test.dart

# Menjalankan seluruh pengujian di dalam folder
flutter test
```

---

## 🔄 Riwayat Branch & Langkah Push Git

Untuk mempublikasikan perubahan pada branch `feat/widget-testing-ui-interaction`:

```bash
# 1. Pastikan branch aktif saat ini
git branch --show-current
# Output: feat/widget-testing-ui-interaction

# 2. Periksa status perubahan
git status

# 3. Tambahkan perubahan pada folder week 12
git add 12-week-12-testing-quality-assurance/

# 4. Commit perubahan
git commit -m "feat(testing): implementasi TaskListPage, widget testing interaksi pengguna, empty state, loading, dan dokumentasi README"

# 5. Push branch baru ke remote GitHub
git push -u origin feat/widget-testing-ui-interaction
```
