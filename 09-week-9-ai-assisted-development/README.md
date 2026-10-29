# Week 9 — AI-Assisted Development & Vibe Coding

Portofolio implementasi **AI-Assisted Development** berdisiplin tinggi (*Anti-Vibe Coding*) pada mata kuliah **Pemrograman Mobile**. Folder ini mendokumentasikan penambahan fitur pencarian catatan (*Search Notes*) beserta visual *empty state* dengan bantuan AI, verifikasi kritis terhadap halusinasi AI, audit sterilitas *Clean Architecture*, dan pembuktian pengujian otomatis (*machine green proof*).

---

## 📌 Ringkasan Capaian Praktikum Minggu 9

* **Mahasiswa**: M. Yahya Irvansyah
* **Mata Kuliah**: Pemrograman Mobile (Semester Genap 2026)
* **Fitur Tambahan**: Pencarian Judul Catatan (*Search Notes by Title*) + *Visual Empty State*
* **Branch Pengerjaan**: `feat/search-notes`
* **Logbook Verifikasi AI**: Terinci pada [`docs/ai-log.md`](docs/ai-log.md) & [`docs/ai-challenge.md`](docs/ai-challenge.md)
* **Kualitas Mesin**:
  * `flutter analyze`: **0 issue (Clean)**
  * `dart format`: **100% konsisten (Exit code 0)**
  * `flutter test`: **21 tests passed (100% passing)**
* **Integritas Arsitektur**: **Domain 100% Murni Dart (Steril)**

---

## 🏗️ Struktur Arsitektur Fitur Baru

Fitur pencarian diintegrasikan dengan mematuhi prinsip *Feature-First Clean Architecture*:

```
09-week-9-ai-assisted-development/
├── docs/
│   ├── ai-log.md                       # Logbook Prompt 5 Slot, Halusinasi AI, & Bukti Uji
│   └── ai-challenge.md                 # Evaluasi Kritis AI Code Reviewer vs Developer
├── lib/
│   ├── core/
│   │   ├── database/notes_db.dart
│   │   ├── format.dart
│   │   └── providers.dart
│   ├── features/
│   │   └── notes/
│   │       ├── domain/
│   │       │   ├── entities/note.dart
│   │       │   ├── failures/failure.dart
│   │       │   ├── repositories/note_repository.dart
│   │       │   └── usecases/
│   │       │       ├── add_note.dart
│   │       │       ├── delete_note.dart
│   │       │       ├── get_notes.dart
│   │       │       ├── update_note.dart
│   │       │       └── filter_notes.dart      # Pure Dart Search Filter Use Case
│   │       ├── data/
│   │       │   ├── models/note_model.dart
│   │       │   └── repositories/note_repository_impl.dart
│   │       └── presentation/
│   │           ├── pages/
│   │           │   └── notes_page.dart        # Decomposed Modular Widgets (< 40 baris)
│   │           └── providers/
│   │               └── notes_providers.dart   # Riverpod 3 NotifierProvider
│   ├── main.dart
│   └── routes.dart
└── test/
    ├── search_filter_test.dart                # Unit Tests + 1 Widget Test Empty State
    ├── get_notes_test.dart
    ├── validate_note_test.dart
    ├── widget_test.dart
    └── features/notes/notes_page_test.dart
```

---

## 🧪 Bukti Mesin Hijau (Quality Gate)

### 1. Analisis Statis (`flutter analyze`)
```text
Analyzing 09-week-9-ai-assisted-development...
No issues found! (ran in 50.6s)
```

### 2. Format Konsistensi Kode (`dart format`)
```text
Formatted 23 files (0 changed) in 0.14 seconds. (Exit Code 0)
```

### 3. Otomatisasi Unit Test & Widget Test (`flutter test`)
```text
00:00 +0: test/core/format_test.dart: formatDate returns a zero-padded date
00:00 +1: test/core/format_test.dart: parseRoute returns the URI path without query or fragment
00:00 +2: test/core/format_test.dart: parseRoute returns null for a missing route
00:00 +3: test/search_filter_test.dart: filter abaikan huruf besar/kecil (case-insensitive)
00:00 +4: test/search_filter_test.dart: query tak cocok kembalikan kosong (empty state trigger)
00:00 +5: test/search_filter_test.dart: query kosong mengembalikan seluruh catatan
00:00 +6: test/search_filter_test.dart: query hanya spasi (whitespace) mengembalikan seluruh catatan
00:00 +7: test/search_filter_test.dart: mencocokkan substring di tengah kata
00:00 +8: test/search_filter_test.dart: mempertahankan urutan catatan setelah difilter
00:00 +9: test/search_filter_test.dart: [Widget Test] menampilkan empty state Icons.search_off saat query tidak cocok
00:01 +16: test/validate_note_test.dart: AddNote & UpdateNote validation tests passed
00:02 +20: test/features/notes/notes_page_test.dart: reads notes and completes the Notes CRUD flow
00:03 +21: test/widget_test.dart: Notes button opens the Notes page
00:04 +21: All tests passed!
```

### 4. Uji Sterilitas Clean Architecture
```bash
git grep -E "package:flutter/|package:sqflite|package:dio" -- 09-week-9-ai-assisted-development/lib/features/notes/domain
# Output: Exit code 1 (Steril: Domain 100% murni Dart)

git grep -E "package:sqflite|rawQuery" -- 09-week-9-ai-assisted-development/lib/features/notes/presentation
# Output: Exit code 1 (Steril: Presentation decoupled dari database)
```

---

## 🔍 Ringkasan Temuan Halusinasi AI

1. **Package Kadaluarsa (`StateProvider` pada Riverpod 3)**:
   * AI menyarankan `StateProvider` yang sudah dihapus pada `flutter_riverpod: ^3.4.3`.
   * *Bukti*: `flutter test` melempar compilation error `Method not found: 'StateProvider'`.
   * *Solusi*: Direfaktor menjadi `Notifier<String>` dan `NotifierProvider`.
2. **Bug Logika Case-Sensitive**:
   * AI menyarankan `.contains(query)` langsung tanpa normalisasi.
   * *Bukti*: Unit test `filter abaikan huruf besar/kecil` gagal karena `"belanja"` tidak menemukan `"Belanja"`.
   * *Solusi*: Normalisasi menggunakan `.trim().toLowerCase()`.
3. **Pelanggaran Dependensi**:
   * Menolak usulan AI yang ingin memanggil raw query SQLite langsung di widget UI demi menjaga prinsip Clean Architecture.

---

## ⚠️ Error Umum dan Solusinya

| Gejala Masalah | Penyebab Umum | Solusi yang Diterapkan |
| :--- | :--- | :--- |
| **Method tidak ada** | Halusinasi API dari AI yang mengarang nama method | Cek autocomplete IDE, verifikasi `pub.dev`, dan cek `pubspec.lock`. |
| **Import lintas layer** | Konteks arsitektur kurang ditegaskan pada prompt | Tegaskan batasan *dependency rule* pada prompt 5 slot dan lakukan refactoring ke domain use case. |
| **Semua test merah** | Prompt terlalu besar / menghasilkan kode masif sekaligus | Minta 1 fitur kecil + sertakan 1 test spesifik secara bertahap. |
| **Prompt diulang-ulang** | Tidak mereproduksi akar masalah (*blind trial*) | Tulis langkah reproduksi + buat unit test merah pembukti sebelum memperbaiki. |
| **Tak bisa menjelaskan** | Menerima kode AI mentah tanpa membaca (*vibe coding*) | Baca diff baris demi baris, sederhanakan fungsi di bawah 40 baris, dan pahami peran tiap layer. |

---

## 📱 Panduan Uji Manual 3 Query

Pengujian manual pada aplikasi dapat diverifikasi dengan 3 skenario query pencarian:
1. **Query Cocok**:
   * *Input*: Ketik `"belanja"` atau `"kuliah"`.
   * *Ekspektasi*: Hanya catatan yang memuat kata kunci tersebut yang tampil pada daftar (case-insensitive).
2. **Query Tak Cocok (Empty State)**:
   * *Input*: Ketik `"zzz-tak-ada"`.
   * *Ekspektasi*: Tampil komponen *empty state* visual berupa icon `Icons.search_off` dengan keterangan teks *"Tidak ada catatan yang cocok dengan \"zzz-tak-ada\""*.
3. **Query Kosong / Reset**:
   * *Input*: Kosongkan teks atau tekan tombol icon `clear` (`X`).
   * *Ekspektasi*: Seluruh daftar catatan kembali muncul secara lengkap.

---

## 📋 Checklist Verifikasi Mandiri

- [x] **Prompt 5 slot + konteks tersimpan di `docs/ai-log.md`**: Lengkap dengan peran, konteks, tugas, batas, dan output.
- [x] **`flutter analyze` bersih**: 0 issue / warning.
- [x] **`flutter test` hijau**: 21 unit & widget tests lolos 100%.
- [x] **1 temuan AI dibuktikan benar + 1 ditolak beralasan**: Temuan whitespace & early exit diterima, temuan raw SQL di widget ditolak keras.
- [x] **Mampu menjelaskan tanpa membuka AI**: Seluruh alur data dari Presentation $\rightarrow$ Notifier $\rightarrow$ Domain Use Case $\rightarrow$ Repository dapat dipertanggungjawabkan secara mandiri.
