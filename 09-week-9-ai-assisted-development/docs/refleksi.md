# Lembar Refleksi: AI-Assisted Development & Vibe Coding (Week 9)

Dokumen ini memuat jawaban refleksi kritis terkait pengalaman bekerja bersama AI coding assistant, mitigasi halusinasi model, prompt engineering berdisiplin, dan audit arsitektur perangkat lunak.

---

## 1. Satu halusinasi AI apa yang Anda temukan dan bagaimana membuktikannya?

### Temuan Halusinasi: API Versi Kadaluarsa (`StateProvider` pada Riverpod 3)
* **Deskripsi**: AI mengusulkan pembuatan state pencarian menggunakan `StateProvider<String>((ref) => '')`. Padahal pada `pubspec.yaml`, dependensi yang terpasang adalah versi terbaru `flutter_riverpod: ^3.4.3`. Pada Riverpod generasi 3, `StateProvider` telah dihentikan/dihapus (*deprecated/removed*) untuk mendorong pola state yang lebih terstruktur.
* **Cara Membuktikannya**:
  Ketika kode usulan AI dieksekusi dengan `flutter test` atau `flutter analyze`, Dart resident compiler langsung menolak kompilasi dengan pesan error:
  ```text
  lib/features/notes/presentation/providers/notes_providers.dart:40:33: Error: Method not found: 'StateProvider'.
  final noteSearchQueryProvider = StateProvider<String>((ref) => '');
                                  ^^^^^^^^^^^^^
  ```
* **Tindakan Perbaikan**:
  Direfaktor menggunakan API resmi Riverpod 3: `Notifier<String>` dan `NotifierProvider<NoteSearchQueryNotifier, String>`.

---

## 2. Prompt mana yang paling membantu dan apa yang Anda ubah?

### Prompt yang Paling Membantu: Formula 5 Slot dengan Batasan Negatif (*Negative Constraints*)
```text
Peran: Senior Flutter Developer
Konteks: Project Flutter feature-first Clean Architecture (presentation -> domain <- data).
         Menggunakan flutter_riverpod (^3.4.3), SQLite lokal, dan GoRouter.
Tugas: Tambahkan fitur pencarian catatan berdasarkan judul (search notes by title)
       lengkap dengan visual empty state jika hasil pencarian tidak ditemukan.
Batas: Jangan ubah arsitektur dasar. Jangan pernah memanggil driver SQLite langsung dari widget.
       Layer domain harus murni Dart (pure Dart) tanpa import Flutter/UI. Maksimal 80 baris kode.
Output: Kode fungsi filter/use case + state provider + potongan UI empty state
        + minimal 3 unit test (case-insensitive, empty match, query kosong) + cara uji.
```

### Hal yang Diubah dari Prompt Biasa:
1. **Penegasan Batasan Arsitektur (*Architectural Guardrails*)**: Mengharuskan domain murni Dart (*pure Dart*). Tanpa kalimat ini, AI selalu mengimpor `package:flutter/material.dart` atau `package:sqflite` ke mana-mana.
2. **Larangan Eksplisit (*Negative Constraint*)**: Menyebutkan secara jelas *"Jangan pernah memanggil driver SQLite langsung dari widget"*.
3. **Batasan Ukuran Kode (*Line Budget*)**: Membatasi output maksimal 80 baris agar AI tidak meregenerasi seluruh file dan fokus pada diff logika yang dibutuhkan.

---

## 3. Satu refactor apa yang Anda lakukan pada kode AI?

### Refactor Dekomposisi Fungsi & Isolasi Domain:
1. **Isolasi Logika Invariant ke Domain Use Case**:
   AI awalnya menulis logika filter inline di dalam class Widget presentasi. Logika ini diangkat keluar ke file [`lib/features/notes/domain/usecases/filter_notes.dart`](../lib/features/notes/domain/usecases/filter_notes.dart) sebagai pure function. Hal ini membuat logika pencarian dapat diuji secara *headless unit test* dalam hitungan milidetik tanpa emulator atau mock UI.
2. **Pemecahan Widget di Bawah 40 Baris**:
   Method `build` pada `NotesPage` yang awalnya membengkak di atas 75 baris dipecah menjadi sub-widget modular:
   * `_SearchBar` (25 baris)
   * `_EmptySearchState` (20 baris)
   * `_ErrorState` (23 baris)
   * `_DeleteConfirmDialog` (22 baris)
   * `NotesPage.build` (34 baris)

---

## 4. Keputusan terima/tolak mana yang paling sulit?

### Keputusan Menolak Delegasi Query SQL `LIKE` ke Database
* **Dilema**: AI mengajukan temuan bahwa pencarian *in-memory* pada Dart List tidak scalable untuk puluhan ribu data catatan dan mendesak penulisan query `rawQuery('SELECT * FROM notes WHERE title LIKE ?', ...)` yang dipanggil langsung dari widget atau domain.
* **Alasan Mengapa Sulit**: Secara teori komputasi umum, delegasi pencarian ke index database terdengar lebih canggih dan meyakinkan.
* **Justifikasi Penolakan Final**:
  1. **Integritas Clean Architecture**: AI menyarankan pemanggilan database langsung yang melanggar *Dependency Inversion Principle*.
  2. **Konteks Nyata Aplikasi**: Aplikasi ini adalah catatan tugas mahasiswa yang rata-rata menampung puluhan hingga ratusan catatan lokal. Pemfilteran in-memory pada List Dart berjalan instan (< 1 milidetik) tanpa hambatan I/O disk.
  3. **Kemudahan Pengujian**: Filter in-memory di domain dapat diuji dengan pure unit tests yang deterministik dan cepat, tanpa perlu spin-up SQLite runner.

