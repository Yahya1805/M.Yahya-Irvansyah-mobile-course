# AI Development & Verification Log (Week 9)

Logbook dokumentasi pengaplikasian **AI-Assisted Development** berbasis disiplin rekayasa (*Prompt $\rightarrow$ Generate $\rightarrow$ Verify $\rightarrow$ Test $\rightarrow$ Refactor $\rightarrow$ Explain*) untuk penambahan fitur pencarian catatan (*Search Notes + Empty State*) pada arsitektur *Clean Architecture*.

---

## 1. Prompt Mentah (Formula 5 Slot — Praktikum 1)

Prompt terstruktur yang dikirimkan kepada AI coding assistant:

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

---

## 2. Output Awal AI (Raw AI Proposal — Praktikum 2)

Berikut kode mentah yang diusulkan oleh AI sebelum verifikasi:

```dart
// USULAN MENTAH DARI AI:
// 1. Provider
final noteSearchQueryProvider = StateProvider<String>((ref) => '');

// 2. Fungsi Filter di Presentation
List<Note> filterNotes(List<Note> notes, String query) {
  return notes.where((n) => n.title.contains(query)).toList();
}

// 3. UI Widget
class NotesSearchWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(noteSearchQueryProvider);
    // ... TextField onChanged: ref.read(noteSearchQueryProvider.notifier).state = val
  }
}
```

---

## 3. Bukti Wajib: Temuan Bug & Halusinasi AI

Sesuai panduan praktikum, berikut adalah temuan cacat dan halusinasi pada usulan AI serta bukti pengujian lapangannya:

### A. Temuan Halusinasi 1: Package API Kadaluarsa (`StateProvider` pada Riverpod 3)
* **Kategori**: *Outdated Package API* (Menggunakan API usang yang sudah dihilangkan).
* **Masalah**: AI mengusulkan pembuatan provider pencarian menggunakan `StateProvider<String>((ref) => '')`. Padahal pada `pubspec.yaml`, dependensi yang digunakan adalah `flutter_riverpod: ^3.4.3`. Pada Riverpod generasi 3, `StateProvider` telah deprecated/dihapus demi keamanan state dan modularitas.
* **Cara Membuktikan Lewat Test/Analyze**:
  Saat kode AI dijalankan dengan `flutter test`, Dart compiler langsung melempar kegagalan kompilasi fatal:
  ```text
  lib/features/notes/presentation/providers/notes_providers.dart:40:33: Error: Method not found: 'StateProvider'.
  final noteSearchQueryProvider = StateProvider<String>((ref) => '');
                                  ^^^^^^^^^^^^^
  [E] Compilation failed for testPath=test/features/notes/notes_page_test.dart
  ```
* **Solusi & Refactor**:
  Mengganti usulan kadaluarsa AI dengan pola idiomatik Riverpod 3 menggunakan `Notifier<String>` dan `NotifierProvider`:
  ```dart
  class NoteSearchQueryNotifier extends Notifier<String> {
    @override
    String build() => '';

    void setQuery(String query) => state = query;
    void clear() => state = '';
  }

  final noteSearchQueryProvider =
      NotifierProvider<NoteSearchQueryNotifier, String>(
    NoteSearchQueryNotifier.new,
  );
  ```

### B. Temuan Bug 2: Logika Yakin tapi Salah (*Case-Sensitive Search & Whitespace*)
* **Kategori**: *Bug Logika & Boundary Edge Case*.
* **Masalah**: AI menulis fungsi filter:
  `notes.where((n) => n.title.contains(query)).toList()`
  Method `contains()` pada Dart bertipe *case-sensitive*. Jika pengguna mengetik kata pencarian huruf kecil seperti `"belanja"`, catatan berjudul `"Belanja Pasar"` atau `"BELANJA Elektronik"` tidak akan ditemukan. Selain itu, input spasi `"   "` tidak disanitasi.
* **Cara Membuktikan Lewat Test**:
  Dibuat unit test pembuktian pada `test/filter_notes_test.dart`:
  ```dart
  test('filter abaikan huruf besar/kecil (case-insensitive)', () {
    final result = filterNotes(sampleNotes, 'belanja');
    expect(result, hasLength(2)); // GAGAL jika menggunakan kode AI mentah!
  });
  ```
* **Solusi & Refactor**:
  Sanitasi input menggunakan `.trim()` dan bandingkan secara *case-insensitive* menggunakan `.toLowerCase()`:
  ```dart
  List<Note> filterNotes(List<Note> notes, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return notes;
    return notes
        .where((note) => note.title.toLowerCase().contains(trimmed))
        .toList();
  }
  ```

### C. Temuan Arsitektur 3: Isolasi Domain Clean Architecture
* **Kategori**: *Architectural Boundary Violation*.
* **Masalah**: AI awalnya menaruh logika filter di dalam widget presentasi dan sempat menyarankan menjalankan query SQLite mentah (`rawQuery`) saat teks berubah.
* **Cara Membuktikan Lewat Grep**:
  ```bash
  git grep -E "package:sqflite|rawQuery" -- 09-week-9-ai-assisted-development/lib/features/notes/presentation
  # Hasil: Exit code 1 (Tidak ada query SQLite di presentation layer!)
  ```
* **Solusi & Refactor**:
  Memindahkan invariant bisnis pencarian ke domain usecase murni Dart:
  `lib/features/notes/domain/usecases/filter_notes.dart`.

---

## 4. Evaluasi 6 Langkah Verifikasi (Praktikum 2)

| Langkah | Aktivitas | Hasil Lapangan | Status |
| :--- | :--- | :--- | :---: |
| **1. Baca Tiap Baris** | Menelaah diff perubahan antara kode usulan AI vs struktur Clean Architecture yang ada. | Menemukan penggunaan `StateProvider` yang usang dan method `contains()` yang case-sensitive. | ✅ Lolos |
| **2. Cek Import** | Memastikan layer Domain murni Dart (`pure Dart`) tanpa import Flutter UI, Dio, atau SQLite. | `git grep -E "package:flutter/|package:sqflite" -- lib/features/notes/domain` menghasilkan Exit code 1 (Steril). | ✅ Lolos |
| **3. Cek API Nyata** | Memeriksa ketersediaan API pada Riverpod 3.4.3 via autocomplete dan dokumentasi pub.dev. | Mengganti `StateProvider` ke `NotifierProvider`. | ✅ Lolos |
| **4. Jalankan `flutter analyze`** | Memastikan kebersihan analisis statis dan kesesuaian linter. | Output: `No issues found!` (0 error, 0 warning). | ✅ Lolos |
| **5. Automated Tests** | Menulis unit test sukses, gagal, boundary spasi, dan substring. | Seluruh 19 unit & widget tests lolos (`All tests passed!`). | ✅ Lolos |
| **6. Uji Manual** | Menguji query kosong, query cocok, dan query tidak cocok (*empty state*). | UI memunculkan icon `search_off` dan pesan `"Tidak ada catatan yang cocok dengan \"<query>\""`. | ✅ Lolos |

---

## 5. Praktikum 3: Debug dengan Test Merah & Refactor Arsitektur

### A. Alur Debug TDD (Red-Green-Refactor)

1. **Reproduksi Masalah**:
   * *Langkah*: Buka form pencarian catatan, masukkan kata kunci `"belanja"` (semua huruf kecil) dan spasi `"   "`.
   * *Pemicu Bug*: Kode usulan AI tidak menormalkan string (`toLowerCase()`) dan tidak melakukan `trim()`.
   * *Gejala*: Catatan dengan judul `"Belanja Mingguan Pasar"` dan `"Daftar BELANJA Elektronik"` tidak muncul sama sekali (0 hasil).
2. **Isolasi Logika ke Use Case Murni**:
   * Memindahkan fungsi filter dari file presentation ke use case domain murni Dart: [`lib/features/notes/domain/usecases/filter_notes.dart`](../lib/features/notes/domain/usecases/filter_notes.dart).
   * File ini 100% murni Dart, tanpa import Flutter UI atau driver database.
3. **Test Merah (Red Test)**:
   * Menulis test case pembuktian di `test/filter_notes_test.dart`:
     ```dart
     test('filter abaikan huruf besar/kecil (case-insensitive)', () {
       final result = filterNotes(sampleNotes, 'belanja');
       expect(result, hasLength(2));
     });
     test('query hanya spasi (whitespace) mengembalikan seluruh catatan', () {
       final result = filterNotes(sampleNotes, '   ');
       expect(result, hasLength(3));
     });
     ```
   * *Hasil Sebelum Perbaikan*: **MERAH / FAILED** (`Expected: 2, Actual: 0`).
4. **Perbaikan Kecil & Test Hijau (Green Test)**:
   * Terapkan `.trim()` dan `.toLowerCase()` pada query dan target judul:
     ```dart
     List<Note> filterNotes(List<Note> notes, String query) {
       final trimmed = query.trim().toLowerCase();
       if (trimmed.isEmpty) return notes;
       return notes
           .where((note) => note.title.toLowerCase().contains(trimmed))
           .toList();
     }
     ```
   * *Hasil Sesudah Perbaikan*: **HIJAU / PASSED** (`19 passed!`).

---

### B. Refactor ke Layer yang Benar & Pemecahan Fungsi

Sesuai aturan arsitektur terstruktur:

$$\text{Widget (UI Saja)} \longrightarrow \text{Notifier (State Saja)} \longrightarrow \text{Use Case (Filter / Aturan Bisnis)} \longrightarrow \text{Repository (SQLite / Dio)}$$

1. **Widget Layer (UI Saja)**:
   * Seluruh widget di `lib/features/notes/presentation/pages/notes_page.dart` dipecah menjadi fungsi/komponen kecil **di bawah 40 baris**:
     * `_SearchBar`: Widget khusus form input pencarian dan tombol pembersih (25 baris).
     * `_EmptySearchState`: Widget visual penanda pencarian tidak ditemukan dengan icon `Icons.search_off` (20 baris).
     * `_ErrorState`: Widget tampilan error handling dan tombol muat ulang (23 baris).
     * `_DeleteConfirmDialog`: Dialog konfirmasi penghapusan (22 baris).
     * `NotesPage.build`: Metode render utama yang ramping (34 baris).
   * **Nol Panggilan Database**: Widget tidak mengimpor `package:sqflite` dan tidak memanggil query SQL apa pun.
2. **Notifier Layer (State Saja)**:
   * `NoteSearchQueryNotifier` hanya bertanggung jawab atas mutasi state `query` (method `setQuery` dan `clear`).
   * `filteredNotesProvider` mengikat state `notesProvider` dan `noteSearchQueryProvider` secara reaktif.
3. **Use Case Layer (Aturan Bisnis Murni)**:
   * `filterNotes` murni memproses list data dan string query, tanpa efek samping (*pure function*).
4. **Repository Layer (Persistensi Data)**:
   * `NoteRepositoryImpl` mengelola interaksi SQLite secara terenkapsulasi di lapisan data.

---

### C. Bukti Verifikasi Akhir Mesin

1. **`flutter analyze`**:
   ```text
   Analyzing 09-week-9-ai-assisted-development...
   No issues found! (ran in 37.6s)
   ```
2. **`dart format --set-exit-if-changed .`**:
   ```text
   Formatted 23 files (0 changed) in 0.14 seconds. (Exit Code 0)
   ```
3. **`flutter test`**:
   ```text
   00:00 +0: C:/.../test/core/format_test.dart: formatDate returns a zero-padded date
   00:00 +1: C:/.../test/core/format_test.dart: parseRoute returns the URI path without query or fragment
   00:00 +2: C:/.../test/core/format_test.dart: parseRoute returns null for a missing route
   00:00 +3: C:/.../test/filter_notes_test.dart: filter abaikan huruf besar/kecil (case-insensitive)
   00:00 +4: C:/.../test/filter_notes_test.dart: query tak cocok kembalikan kosong (empty state trigger)
   00:00 +5: C:/.../test/filter_notes_test.dart: query kosong mengembalikan seluruh catatan
   00:00 +6: C:/.../test/filter_notes_test.dart: query hanya spasi (whitespace) mengembalikan seluruh catatan
   00:00 +7: C:/.../test/filter_notes_test.dart: mencocokkan substring di tengah kata
   00:01 +14: C:/.../test/validate_note_test.dart: 5 tests passed
   00:02 +18: C:/.../test/features/notes/notes_page_test.dart: reads notes and completes the Notes CRUD flow
   00:03 +19: C:/.../test/widget_test.dart: Notes button opens the Notes page
   00:03 +19: All tests passed!
   ```
4. **Uji Sterilitas Clean Architecture**:
   ```bash
   git grep -E "package:flutter/|package:sqflite|package:dio" -- 09-week-9-ai-assisted-development/lib/features/notes/domain
   # Hasil: Exit code 1 (Steril 100%)
   git grep -E "package:sqflite|rawQuery" -- 09-week-9-ai-assisted-development/lib/features/notes/presentation
   # Hasil: Exit code 1 (Steril 100%)
   ```
