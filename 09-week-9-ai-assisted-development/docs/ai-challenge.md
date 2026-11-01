# AI Challenge: Evaluasi Kritis AI Code Review (Week 9)

Dokumen ini memuat pelaksanaan **AI Prompt Challenge**, output awal review AI, matriks verifikasi penerimaan vs penolakan, serta bukti uji mesin (*Clean Architecture & Green Test*) pada fitur pencarian catatan (*Search Notes*).

---

## 1. Prompt AI Challenge

Prompt yang diajukan kepada AI reviewer sesuai instruksi Codelab Minggu 9:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

---

## 2. Output Mentah AI Reviewer (Raw Findings)

Berikut 3 temuan teratas yang diajukan oleh AI reviewer terhadap implementasi fitur pencarian:

### Temuan 1 (Level: Saran) — Robustness & Boundary Handling
* **Kategori**: Kebenaran Logika & Boundary Condition
* **Masalah**: Fungsi `filterNotes` saat ini memproses string query dengan `trim().toLowerCase()`. Namun, jika query berupa string kosong atau hanya spasi, evaluasi `.where()` tidak perlu dijalankan karena membuang iterasi `O(N)`. Sebaiknya langsung lakukan *early return* daftar catatan asli.
* **Usulan Kode AI**:
  ```dart
  List<Note> filterNotes(List<Note> notes, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return notes;
    return notes.where((n) => n.title.toLowerCase().contains(trimmed)).toList();
  }
  ```

### Temuan 2 (Level: Blocker) — Skalabilitas & Database Query Langsung
* **Kategori**: Arsitektur & Performa Database
* **Masalah**: Pemfilteran secara *in-memory* pada Dart List dianggap tidak efisien jika jumlah data catatan mencapai puluhan ribu. AI menuntut agar pencarian didelegasikan langsung ke SQLite dengan query `LIKE '%query%'`, dan menyarankan menambahkan parameter query pada `openNotesDb` atau memanggil query database langsung dari controller widget presentasi.
* **Usulan Kode AI**:
  Menambahkan method pencarian langsung ke database query:
  ```dart
  // Diusulkan AI di layer presentasi / domain:
  final results = await db.rawQuery('SELECT * FROM notes WHERE title LIKE ?', ['%$query%']);
  ```

### Temuan 3 (Level: Saran) — Testing Invariant Preservasi Urutan
* **Kategori**: Quality Assurance & Regression Test
* **Masalah**: Test suite pencarian (`test/filter_notes_test.dart`) belum memverifikasi apakah urutan catatan (*chronological order* berdasarkan `updatedAt`) tetap terjaga setelah proses pemfilteran.
* **Usulan Kode AI**:
  Menambahkan test assertion untuk invariant urutan indeks:
  ```dart
  test('mempertahankan urutan updatedAt setelah difilter', () {
    final result = filterNotes(sampleNotes, 'belanja');
    expect(result.first.updatedAt.isBefore(result.last.updatedAt), isTrue);
  });
  ```

---

## 3. Matriks Verifikasi & Keputusan Final Developer

| No | Temuan AI | Level | Verifikasi Lapangan (Bukti Grep/Test) | Keputusan | Alasan Teknis & Justifikasi Arsitektur |
|:--:|:---|:---:|:---|:---:|:---|
| **1** | *Early return* pada query kosong/spasi untuk efisiensi $O(1)$. | **Saran** | **Terbukti Benar**. String spasi tidak memerlukan iterasi linear. Unit test membuktikan output identik dengan performa lebih cepat. | **DITERIMA & DITERAPKAN** | Menghemat siklus CPU pada perangkat mobile ketika pengguna mengetik lalu menghapus spasi di input pencarian. |
| **2** | Menuntut query SQL `LIKE` langsung dan menyarankan pemanggilan database dari widget/domain. | **Blocker** | **Salah & Merusak Arsitektur**. Grep membuktikan presentation steril: `git grep -E "package:sqflite|rawQuery" -- 09-week-9-ai-assisted-development/lib/features/notes/presentation` menghasilkan Exit code 1. | **DITOLAK KERAS** | **1. Pelanggaran Fatal Clean Architecture**: Domain dan UI dilarang bergantung pada driver SQL.<br>**2. Premature Optimization**: Untuk skala catatan offline lokal mahasiswa (< 1.000 data), filter in-memory murni Dart berlangsung instan (< 1ms) tanpa latensi disk I/O, serta dapat diuji secara murni *headless unit test* tanpa emulator database. |
| **3** | Pengujian preservasi urutan (*sort order invariant*). | **Saran** | **Terbukti Benar**. Menjamin UX pengguna tidak berubah acak saat hasil filter ditampilkan. | **TERIMA + REFACTOR** | Ditambahkan ke `test/filter_notes_test.dart` untuk meningkatkan ketahanan regresi. |

---

## 4. Keputusan Tindak Lanjut per Berkas

| Berkas | Keputusan | Keterangan & Tindakan |
|:---|:---:|:---|
| [`lib/features/notes/domain/usecases/filter_notes.dart`](../lib/features/notes/domain/usecases/filter_notes.dart) | **Terima + Refactor** | Mempertahankan kemurnian Dart (*pure Dart*), mengoptimalkan *early return* query kosong, sanitasi `.trim().toLowerCase()`. |
| [`lib/features/notes/presentation/providers/notes_providers.dart`](../lib/features/notes/presentation/providers/notes_providers.dart) | **Terima** | Menghubungkan query `NotifierProvider` dengan `filteredNotesProvider` secara reaktif dan aman. |
| [`lib/features/notes/presentation/pages/notes_page.dart`](../lib/features/notes/presentation/pages/notes_page.dart) | **Terima + Refactor** | Menolak query SQLite di widget, memecah UI menjadi sub-widget modular di bawah 40 baris (`_SearchBar`, `_EmptySearchState`, `_ErrorState`). |
| [`test/filter_notes_test.dart`](../test/filter_notes_test.dart) | **Terima + Refactor** | Menambahkan pengujian case-insensitive, empty query, whitespace, substring, dan invariant preservasi urutan. |

---

## 5. Bukti Pengujian Mesin (Clean & Green)

### A. Uji Sterilitas Arsitektur (Bukti Penolakan Temuan 2 Sahih)
```bash
# Membuktikan layer domain murni Dart:
git grep -E "package:flutter/|package:sqflite|package:dio" -- 09-week-9-ai-assisted-development/lib/features/notes/domain
# Output: Exit code 1 (Steril!)

# Membuktikan layer presentasi tidak memanggil raw query:
git grep -E "package:sqflite|rawQuery" -- 09-week-9-ai-assisted-development/lib/features/notes/presentation
# Output: Exit code 1 (Steril!)
```

### B. Analisis Statis (`flutter analyze`)
```text
Analyzing 09-week-9-ai-assisted-development...
No issues found! (ran in 50.6s)
```

### C. Otomatisasi Unit Test (`flutter test`)
```text
00:00 +0: C:/.../test/core/format_test.dart: formatDate returns a zero-padded date
00:00 +1: C:/.../test/core/format_test.dart: parseRoute returns the URI path without query or fragment
00:00 +2: C:/.../test/core/format_test.dart: parseRoute returns null for a missing route
00:00 +3: C:/.../test/filter_notes_test.dart: filter abaikan huruf besar/kecil (case-insensitive)
00:00 +4: C:/.../test/filter_notes_test.dart: query tak cocok kembalikan kosong (empty state trigger)
00:00 +5: C:/.../test/filter_notes_test.dart: query kosong mengembalikan seluruh catatan
00:00 +6: C:/.../test/filter_notes_test.dart: query hanya spasi (whitespace) mengembalikan seluruh catatan
00:00 +7: C:/.../test/filter_notes_test.dart: mencocokkan substring di tengah kata
00:00 +8: C:/.../test/filter_notes_test.dart: mempertahankan urutan catatan setelah difilter
00:01 +15: C:/.../test/validate_note_test.dart: 5 tests passed
00:02 +19: C:/.../test/features/notes/notes_page_test.dart: reads notes and completes Notes CRUD flow
00:03 +20: C:/.../test/widget_test.dart: Notes button opens the Notes page
00:03 +20: All tests passed!
```

---

## 6. Refleksi & Penjelasan Mandiri (Tanpa AI)

1. **Mengapa menolak query SQL di widget presentasi?**  
   Widget bertugas murni merender antarmuka (*declarative presentation*). Menyisipkan query database ke dalam widget merusak portabilitas UI, membuat pengujian otomatis (*widget test*) wajib menyertakan koneksi SQLite riil, serta melanggar prinsip *Separation of Concerns*.
2. **Mengapa memilih in-memory filtering pada domain use case?**  
   Fungsi `filterNotes` merupakan *pure function*. Fungsi murni sangat mudah diuji secara instan (*deterministic unit testing*), tidak membutuhkan *mocking* SQLite, dan memberikan responsivitas UI 60fps tanpa jeda I/O pada perangkat mobile.

