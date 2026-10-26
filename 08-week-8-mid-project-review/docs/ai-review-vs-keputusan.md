# Verifikasi AI Code Review vs Keputusan Final Developer (Week 8)

Dokumen ini mencatat pelaksanaan **AI Prompt Challenge**, evaluasi kritis terhadap setiap temuan yang diajukan oleh AI coding assistant, tabel verifikasi penerimaan vs penolakan, serta justifikasi arsitektur teknis independen.

---

## 1. AI Review Prompt

Prompt yang diberikan kepada AI Code Reviewer sesuai instruksi Codelab Minggu 8:

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

---

## 2. Output Awal AI Reviewer (Raw Findings)

Berikut adalah 5 temuan yang dihasilkan oleh AI reviewer terhadap PR `feat(notes): validasi judul kosong + test`:

### Temuan 1 (Level: Blocker)
* **Kategori**: Kebenaran & Edge Case
* **Masalah**: Validasi judul pada `AddNote` rentan terhadap input hanya spasi putih (*whitespace*). Jika pengguna memasukkan `"   "`, `title.isEmpty` bernilai false dan catatan kosong tersimpan ke database.
* **Usulan Kode AI**:
  ```dart
  final trimmedTitle = title.trim();
  if (trimmedTitle.isEmpty) {
    return (note: null, failure: const ValidationFailure('Judul tidak boleh kosong'));
  }
  ```

### Temuan 2 (Level: Blocker)
* **Kategori**: Arsitektur & User Feedback
* **Masalah**: Use case `AddNote` tidak langsung menampilkan navigasi kembali atau SnackBar ketika terjadi error validasi, sehingga UI harus menangani logic if-else berulang.
* **Usulan Kode AI**:
  Import `package:flutter/material.dart` dan `package:go_router/go_router.dart` langsung di dalam file domain use case `add_note.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:go_router/go_router.dart';

  class AddNote {
    Future<void> call(BuildContext context, {required String title}) async {
      if (title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error')));
        return;
      }
      // logic
      context.pop();
    }
  }
  ```

### Temuan 3 (Level: Saran)
* **Kategori**: Kebenaran Data (SQLite Row Count)
* **Masalah**: Pada `NoteRepositoryImpl.updateNote`, hasil eksekusi query update `db.update(...)` mengembalikan integer jumlah baris yang terpengaruh (*rows affected*). Jika ID catatan tidak ada di database, SQLite mengembalikan `0` tanpa melempar exception, sehingga sistem mengira update berhasil padahal tidak ada data yang berubah.
* **Usulan Kode AI**:
  ```dart
  final count = await db.update('notes', model.toMap(), where: 'id = ?', whereArgs: [id]);
  if (count == 0) {
    return const LocalFailure('Catatan tidak ditemukan');
  }
  ```

### Temuan 4 (Level: Saran)
* **Kategori**: Testing & Regression Coverage
* **Masalah**: Test suite belum mencakup negative test untuk `UpdateNote` saat validasi judul gagal dan saat ID tidak ditemukan.
* **Usulan Kode AI**:
  Tambahkan pengujian kegagalan pada `test/validate_note_test.dart`:
  ```dart
  test('gagal memperbarui saat judul baru kosong atau hanya spasi', () async {
    final failure = await updateNote.call(id: 1, title: '   ', body: '');
    expect(failure, isA<ValidationFailure>());
  });
  ```

### Temuan 5 (Level: Blocker)
* **Kategori**: State Management (Riverpod)
* **Masalah**: Provider `notesProvider` (sebuah `FutureProvider`) dituduh menyebabkan *memory leak* jika `ConsumerWidget` tidak diubah menjadi `StatefulWidget` dengan manual subscription cancel pada method `dispose()`.
* **Usulan Kode AI**:
  Ubah `NotesPage` menjadi `ConsumerStatefulWidget` dan buat custom listener controller manual untuk meng-cancel stream/future.

---

## 3. Matriks Verifikasi & Keputusan Final Developer

| No | Temuan AI | Level Temuan | Verifikasi Lapangan (Bukti Nyata) | Keputusan | Alasan Teknis & Justifikasi Arsitektur |
|:--:|:----------|:------------:|:----------------------------------|:---------:|:---------------------------------------|
| **1** | Validasi whitespace `"   "` lolos di `AddNote`. | **Blocker** | **Terbukti Benar**. String spasi tanpa `trim()` sebelumnya lolos validasi `isEmpty`. Unit test membuktikan kegagalan ini jika tidak ditangani. | **DITERIMA** | Menjaga integritas data di lapisan domain sebelum payload menyentuh database SQLite. |
| **2** | Inject `BuildContext` & SnackBar/GoRouter ke dalam Domain Use Case. | **Blocker** | **Salah & Berbahaya**. Usulan AI mengimpor `flutter/material.dart` dan `go_router` ke `lib/features/notes/domain/usecases/add_note.dart`. | **DITOLAK KERAS** | **PELANGGARAN FATAL DEPENDENCY RULE!** Lapisan Domain harus murni Dart (*pure Dart*) dan dilarang keras bergantung pada UI framework atau routing. Domain hanya bertugas memproses bisnis logika dan mengembalikan `Failure`/`Entity`. Navigasi dan SnackBar adalah tanggung jawab murni lapisan Presentation. |
| **3** | Verifikasi *rows affected* pada `updateNote` SQLite. | **Saran** | **Terbukti Benar**. SQLite `update()` mengembalikan `0` bila record hilang tanpa melempar exception SQLite. | **DITERIMA** | Menjamin kebenaran error path saat record lokal yang dicoba diedit telah dihapus pada sesi lain. |
| **4** | Negative unit tests untuk validasi & update failure. | **Saran** | **Terbukti Benar**. Test suite awal belum memiliki negative assertion untuk validasi whitespace dan invalid update. | **DITERIMA** | Meningkatkan test coverage dan mencegah regresi edge case di kemudian hari. |
| **5** | Menuduh `FutureProvider` bocor memori dan memaksa `StatefulWidget`. | **Blocker** | **Halusinasi AI**. Riverpod `FutureProvider` secara otomatis mengelola lifecycle subscription melalui `ref.watch()`. | **DITOLAK** | Usulan AI merupakan antipattern dan komplikasi yang tidak berdasar (*premature optimization*). `ConsumerWidget` adalah standar deklaratif Riverpod yang bersih dan bebas leak. |

---

## 4. Bukti Pengujian Mesin Setelah Tindak Lanjut

Setelah temuan yang valid (Temuan 1, 3, dan 4) diterapkan dan temuan yang melanggar arsitektur (Temuan 2 dan 5) ditolak, berikut bukti hasil verifikasi mesin:

### A. Uji Sterilitas Arsitektur (Buktikan Penolakan Temuan 2 Benar)
```bash
git grep -E "package:flutter/|package:go_router" -- 08-week-8-mid-project-review/lib/features/notes/domain
# Output: Exit code 1 (Tidak ada import Flutter/GoRouter di Domain -> Steril!)
```

### B. Uji Statis (`flutter analyze`)
```bash
flutter analyze
# Output: No issues found! (0 errors, 0 warnings, 0 lints)
```

### C. Uji Otomatisasi Unit Test (`flutter test`)
```bash
flutter test
# Output: All tests passed! (14 tests passed, 0 failures)
```

---

## 5. Kesimpulan Refleksi Terhadap AI Review

1. **AI sebagai Reviewer Awal**: Sangat efektif mendeteksi *edge case* data (seperti spasi putih) dan *blind spot* query SQLite (*rows affected*).
2. **Bahaya Menerima Saran AI Secara Buta**: AI kerap mengabaikan batasan arsitektur (seperti menyarankan import UI ke domain layer atau memaksakan boilerplate stateful yang tidak diperlukan). Tanpa verifikasi kritis dari developer, kode Clean Architecture dapat terkontaminasi dependensi silang dalam sekejap.
3. **Keputusan Final Ada pada Developer**: Nilai seorang software engineer terletak pada kemampuan menganalisis implikasi jangka panjang dari sebuah usulan kode, mempertahankan integritas arsitektur, dan membuktikannya melalui automated tests.
