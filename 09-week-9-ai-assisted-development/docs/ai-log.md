# AI Development & Verification Log (Week 9)

Logbook dokumentasi pengaplikasian **AI-Assisted Development** berbasis disiplin rekayasa (*Prompt $\rightarrow$ Generate $\rightarrow$ Verify $\rightarrow$ Test $\rightarrow$ Refactor $\rightarrow$ Explain*) untuk penambahan fitur pencarian catatan (*Search Notes + Empty State*) pada arsitektur *Clean Architecture*.

---

## 1. Prompt Mentah (Formula 5 Slot)

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

## 2. Output Awal AI (Raw AI Proposal)

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
  git grep -E "package:sqflite|rawQuery" -- lib/features/notes/presentation
  # Hasil: Exit code 1 (Tidak ada query SQLite di presentation layer!)
  ```
* **Solusi & Refactor**:
  Memindahkan invariant bisnis pencarian ke domain usecase murni Dart:
  `lib/features/notes/domain/usecases/filter_notes.dart`.

---

## 4. Evaluasi 6 Langkah Verifikasi

| Langkah | Aktivitas | Hasil Lapangan | Status |
| :--- | :--- | :--- | :---: |
| **1. Baca Tiap Baris** | Menelaah diff perubahan antara kode usulan AI vs struktur Clean Architecture yang ada. | Menemukan penggunaan `StateProvider` yang usang dan method `contains()` yang case-sensitive. | ✅ Lolos |
| **2. Cek Import** | Memastikan layer Domain murni Dart (`pure Dart`) tanpa import Flutter UI, Dio, atau SQLite. | `git grep -E "package:flutter/|package:sqflite" -- lib/features/notes/domain` menghasilkan Exit code 1 (Steril). | ✅ Lolos |
| **3. Cek API Nyata** | Memeriksa ketersediaan API pada Riverpod 3.4.3 via autocomplete dan dokumentasi pub.dev. | Mengganti `StateProvider` ke `NotifierProvider`. | ✅ Lolos |
| **4. Jalankan `flutter analyze`** | Memastikan kebersihan analisis statis dan kesesuaian linter. | Output: `No issues found! (ran in 37.6s)` (0 error, 0 warning). | ✅ Lolos |
| **5. Automated Tests** | Menulis unit test sukses, gagal, boundary spasi, dan substring. | Seluruh 19 unit & widget tests lolos (`All tests passed!`). | ✅ Lolos |
| **6. Uji Manual** | Menguji query kosong, query cocok, dan query tidak cocok (*empty state*). | UI memunculkan icon `search_off` dan pesan `"Tidak ada catatan yang cocok dengan \"<query>\""`. | ✅ Lolos |

---

## 5. Ringkasan Kode Akhir yang Diterima

1. **Domain Use Case** (`lib/features/notes/domain/usecases/filter_notes.dart`): Murni Dart, independen, dan teruji secara headless.
2. **State Management** (`lib/features/notes/presentation/providers/notes_providers.dart`): Menggunakan Riverpod 3 `NotifierProvider` dan `filteredNotesProvider`.
3. **Presentation & Empty State** (`lib/features/notes/presentation/pages/notes_page.dart`): Form pencarian di header catatan + widget empty state adaptif.
4. **Test Suite** (`test/filter_notes_test.dart`): 5 skenario pengujian komprehensif.

