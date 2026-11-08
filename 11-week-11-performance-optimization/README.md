# Week 11 — Performance Optimization

Portofolio implementasi **Optimasi Performa Aplikasi Mobile** untuk mata kuliah **Pemrograman Mobile**. Folder ini merupakan kelanjutan langsung dari project Week 10 (Notes + AI Chat + AI Multimodal) yang dioptimalkan pada empat area: **query database & pencarian**, **rebuild widget saat streaming chat**, **cache jawaban AI**, dan **ukuran payload gambar**.

> Catatan kejujuran: seluruh perubahan kode sudah diimplementasikan dan diuji otomatis (`dart analyze` bersih, 36 test lulus). Angka *before/after* dari Flutter DevTools **belum diisi** karena pengukuran dilakukan pada praktikum akhir. Kolom hasil pengukuran di `docs/perf-log.md` sengaja dibiarkan kosong, bukan diisi angka perkiraan.

---

## 📌 Ringkasan Capaian

* **Mahasiswa**: M. Yahya Irvansyah
* **Mata Kuliah**: Pemrograman Mobile (Semester Genap 2026)
* **Branch**: `feat/performance-optimization`
* **Baseline**: project Week 10 (`10-week-10-ai-feature-integration`)
* **Status mesin**:
  * `dart analyze`: **0 issue (Clean)**
  * `dart format`: konsisten
  * Test: **36 passed** (baseline 31 test + 5 test optimasi baru)

---

## 🎯 Masalah Performa yang Disasar

| Area | Gejala sebelum optimasi | Akar masalah |
| :--- | :--- | :--- |
| Daftar catatan | Membuka halaman Catatan memuat seluruh isi database sekaligus | `fetchNotes()` memakai `SELECT *` tanpa limit dan seluruh hasil dibangun menjadi widget |
| Pencarian catatan | Setiap ketikan langsung memicu query dan rebuild halaman | Tidak ada debounce; state halaman berada di widget yang sama dengan AppBar/FAB |
| Streaming chat | Bubble chat dan seluruh halaman ikut di-render ulang untuk setiap potongan kata | State streaming disimpan di `setState()` halaman |
| Cache AI | Cache hilang setiap aplikasi ditutup; ukuran cache tidak dibatasi | Cache hanya berupa `static Map` tanpa eviction dan tanpa penyimpanan persisten |
| Gambar multimodal | Byte gambar kamera dikirim mentah sebagai base64 | Belum ada resize/kompresi sebelum encoding |

---

## ⚙️ Optimasi yang Diimplementasikan

### 1. Pagination + pencarian di level database

* `NoteRepository.fetchNotes()` sekarang menerima `limit`, `offset`, dan `query`.
* Query memakai `LIMIT/OFFSET` dan `title LIKE ?` sehingga database hanya mengembalikan baris yang dibutuhkan.
* Database naik ke versi 3 dan menambahkan index `idx_notes_updated_at` pada `notes(updated_at DESC)`.
* `NotesListNotifier` memuat **20 catatan per halaman** dan menyediakan `loadMore()`.
* Halaman berikutnya diminta otomatis saat item terakhir list terbangun.
* `ListView.builder` memakai `addAutomaticKeepAlives: false` agar widget di luar layar tidak disimpan lebih lama dari necessary.

**Dampak yang diharapkan:** waktu buka halaman dan memori turun sebanding dengan jumlah catatan, bukan bertambah linear terhadap seluruh isi database.

### 2. Debounce pencarian dan isolasi rebuild

* Search bar memakai debounce **300 ms**; query hanya dikirim setelah pengguna berhenti mengetik.
* Body halaman dipisah menjadi `_NotesBody` yang mendengarkan provider, sedangkan `AppBar` dan FAB tidak ikut rebuild.
* Saat query berubah, daftar lama dipertahankan sampai hasil baru siap agar layar tidak berkedip ke loading state.

### 3. Streaming chat tanpa rebuild seluruh halaman

* Potongan teks streaming disimpan di `ValueNotifier<String>`.
* Hanya `_StreamingBubble` yang memakai `ValueListenableBuilder`, sehingga chunk token tidak me-rebuild `ListView`, input field, maupun AppBar.
* Update visual di-throttle maksimal **~20 kali/detik** (interval 50 ms), bukan satu rebuild per chunk.
* Auto-scroll hanya dilakukan jika pengguna masih berada dekat dasar list (≤160 px), sehingga riwayat yang sedang dibaca tidak "tertarik" ke bawah.

### 4. Cache AI berbatas + offline-first

* Cache in-memory berubah dari `static Map` menjadi **instance LRU** dengan batas 50 entri.
* Ditambahkan `AiCacheStore` dengan implementasi `SqfliteAiCacheStore` pada tabel `ai_cache`:
  * TTL **24 jam**;
  * maksimal **100 baris** (baris terlama dihapus otomatis);
  * kegagalan cache tidak pernah menggagalkan request utama.
* Cache dicek **sebelum** kuota harian dinaikkan, sehingga pertanyaan berulang tidak memakan kuota.
* `AiService` dibagikan lewat `aiServiceProvider` (Riverpod), sehingga HTTP client dan cache tidak dibuat ulang setiap route dibuka.

### 5. Kompresi gambar sebelum dikirim ke AI

* `ImageOptimizer.optimizeForAi()`:
  * memperkecil sisi terpanjang menjadi maksimal **1024 px**;
  * encode ulang sebagai **JPEG kualitas 82**;
  * dijalankan di isolate terpisah memakai `compute`;
  * jika hasil kompresi lebih besar dari file asli, file asli yang dipakai;
  * MIME type ikut disesuaikan (`image/jpeg` setelah konversi).
* Dipakai oleh `recognizeText()` (OCR) dan `describeImage()` (Vision).

---

## 🧪 Bukti Pengujian Otomatis

| Berkas | Cakupan |
| :--- | :--- |
| `test/features/notes/notes_pagination_test.dart` | Halaman pertama 20 item, `loadMore` menambah sampai 25, pencarian hanya memuat hasil yang cocok |
| `test/performance_optimization_test.dart` | Gambar 1600×1200 diperkecil ≤400 px dan menjadi JPEG; jawaban AI tetap terbaca dari cache persisten pada instance `AiService` baru |
| `test/search_filter_test.dart` | Debounce 300 ms dan empty state pencarian |
| `test/chat_screen_test.dart` | Empty state, bubble streaming, dialog fallback error |
| `test/multimodal_ai_test.dart` | Tab OCR, Vision, Speech |
| `test/ai_privacy_cost_fallback_test.dart` | Sanitasi privasi, cache lokal, fallback offline |

Menjalankan seluruh test:

```bash
flutter test
```

Hasil terakhir: **36 test lulus**.

---

## 🔬 Cara Verifikasi di Praktikum (DevTools)

Pengukuran dilakukan pada **emulator/perangkat Android** (bukan Windows desktop, karena target desktop tidak tersedia di environment ini).

1. Jalankan aplikasi dalam mode profile:
   ```bash
   flutter run --profile
   ```
2. Buka **DevTools → Performance**.
3. Rekam (Record) lalu lakukan skenario berikut:
   * buka halaman Catatan dengan database berisi banyak catatan (mis. 200+);
   * scroll sampai memicu `loadMore`;
   * ketik kata kunci di search bar dan berhenti mengetik;
   * buka AI Chat dan kirim satu pertanyaan sampai streaming selesai;
   * buka AI Multimodal lalu jalankan OCR pada gambar besar.
4. Catat pada `docs/perf-log.md`:
   * jumlah frame yang melewati budget 16 ms;
   * puncak memori (DevTools → Memory);
   * ukuran payload gambar sebelum/sesudah kompresi (DevTools → Network atau log `bytes.length`);
   * jumlah rebuild (DevTools → Widget Inspector / `debugPrintRebuildDirtyWidgets`).
5. Untuk membandingkan dengan baseline, jalankan project `10-week-10-ai-feature-integration` pada perangkat yang sama dengan skenario identik.

> Karena pengukuran belum dilakukan, README ini tidak mencantumkan angka "sebelum vs sesudah". Isi tabel di `docs/perf-log.md` setelah praktikum agar laporan tetap valid.

---

## 🏗️ Struktur Perubahan Penting

```
11-week-11-performance-optimization/
├── docs/
│   └── perf-log.md                     # Log hipotesis, perubahan, dan slot hasil pengukuran
├── lib/
│   ├── ai/
│   │   ├── ai_cache.dart               # Kontrak cache + implementasi SQLite (TTL & batas baris)
│   │   └── ai_service.dart             # LRU cache, cache persisten, kompresi gambar, dispose
│   ├── core/
│   │   ├── database/notes_db.dart      # DB v3: index updated_at + tabel ai_cache
│   │   ├── performance/image_optimizer.dart # Resize + JPEG encode di isolate
│   │   └── providers.dart              # aiServiceProvider (shared instance)
│   ├── features/
│   │   ├── notes/                      # Pagination, debounce, isolasi rebuild
│   │   ├── chat_screen.dart            # ValueNotifier + throttle streaming
│   │   └── multimodal_ai_screen.dart   # Memakai AiService bersama
│   └── routes.dart                     # Inject aiServiceProvider ke layar AI
└── test/
    ├── features/notes/notes_pagination_test.dart
    └── performance_optimization_test.dart
```

---

## 🚀 Menjalankan Project

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

API key Gemini diatur dari dalam aplikasi melalui ikon kunci di halaman AI Chat. Tidak ada kredensial yang ditulis di repository.
