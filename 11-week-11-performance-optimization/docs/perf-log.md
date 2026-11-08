# Performance Log — Week 11

Dokumen ini mencatat **hipotesis**, **perubahan kode**, dan **cara pengukuran** untuk setiap optimasi. Kolom hasil pengukuran sengaja dikosongkan sampai praktikum akhir; angka tidak boleh diisi tanpa data DevTools yang nyata.

- Perangkat/emulator: _isi saat praktikum_ (mis. `Medium_Phone`, Android API ...)
- Mode aplikasi: `flutter run --profile`
- Baseline pembanding: `10-week-10-ai-feature-integration`
- Tanggal pengukuran: _isi saat praktikum_

---

## Ringkasan Status

| # | Optimasi | Implementasi | Test otomatis | Pengukuran DevTools |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Pagination daftar catatan | Selesai | Lulus | Belum |
| 2 | Debounce pencarian | Selesai | Lulus | Belum |
| 3 | Isolasi rebuild halaman Notes | Selesai | Lulus | Belum |
| 4 | Throttle streaming chat | Selesai | Lulus | Belum |
| 5 | Cache AI berbatas + persisten | Selesai | Lulus | Belum |
| 6 | Kompresi gambar multimodal | Selesai | Lulus | Belum |

---

## 1. Pagination daftar catatan

**Hipotesis:** memuat seluruh tabel sekaligus membuat waktu query, alokasi list, dan jumlah widget naik linear terhadap jumlah catatan. Dengan `LIMIT/OFFSET` 20 baris per halaman, biaya awal menjadi konstan.

**Perubahan:**
- `fetchNotes({limit, offset, query})` di repository dan use case.
- Index `idx_notes_updated_at` pada database versi 3.
- `NotesListNotifier` + `loadMore()`.

**Cara ukur:**
1. Isi database dengan 200+ catatan.
2. Buka halaman Catatan dalam mode profile, rekam Performance.
3. Catat waktu frame pertama yang menampilkan daftar dan puncak memori.
4. Scroll sampai `loadMore` terpicu, catat apakah ada frame >16 ms.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 2. Debounce pencarian

**Hipotesis:** query per ketikan memicu pekerjaan database dan rebuild berulang. Debounce 300 ms mengurangi jumlah query drastis untuk input cepat.

**Perubahan:**
- `_SearchBar` dengan `Timer` 300 ms.
- `setQuery()` mempertahankan daftar lama selama query baru diproses.

**Cara ukur:**
1. Ketik 10 karakter cepat di search bar.
2. Hitung jumlah query yang tercatat (tambahkan log sementara atau lihat DevTools timeline).
3. Bandingkan dengan baseline yang menembak query setiap ketikan.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 3. Isolasi rebuild halaman Notes

**Hipotesis:** perubahan state daftar ikut me-rebuild AppBar dan FAB. Memisahkan `_NotesBody` sebagai `ConsumerWidget` membatasi rebuild ke area daftar.

**Perubahan:**
- `_NotesBody`, `_NotesList`, `_SearchBar` dipisah.
- `ListView.builder` dengan `addAutomaticKeepAlives: false`.

**Cara ukur:**
1. Aktifkan `debugPrintRebuildDirtyWidgets = true` pada build profile/debug.
2. Ketik di search bar dan scroll.
3. Hitung berapa kali AppBar/FAB ikut rebuild (seharusnya tidak).

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 4. Throttle streaming chat

**Hipotesis:** satu `setState` per chunk token membuat seluruh halaman chat rebuild puluhan kali per respons. `ValueNotifier` + `ValueListenableBuilder` membatasi rebuild ke bubble streaming, dan throttle 50 ms membatasi frekuensinya.

**Perubahan:**
- `_streamingText` (`ValueNotifier<String>`).
- `_StreamingBubble` memakai `ValueListenableBuilder`.
- Timer throttle 50 ms.
- Auto-scroll hanya jika pengguna dekat dasar list.

**Cara ukur:**
1. Kirim pertanyaan yang menghasilkan respons panjang.
2. Rekam Performance selama streaming.
3. Catat jumlah frame yang dibangun dan frame drop.
4. Bandingkan dengan baseline yang memakai `setState` per chunk.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 5. Cache AI berbatas + persisten

**Hipotesis:** cache `static Map` tanpa batas berpotensi tumbuh terus selama aplikasi hidup, dan hilang saat aplikasi ditutup sehingga request berulang tetap memakan kuota. Cache LRU 50 entri + SQLite 100 baris/TTL 24 jam menstabilkan memori dan menambah cache hit antar sesi.

**Perubahan:**
- `_maxCacheEntries = 50` dengan eviction LRU sederhana.
- `SqfliteAiCacheStore`: tabel `ai_cache`, TTL 24 jam, maksimal 100 baris.
- Cache dicek sebelum kuota harian dinaikkan.

**Cara ukur:**
1. Kirim pertanyaan yang sama dua kali dalam satu sesi → cek tidak ada request jaringan kedua (DevTools Network).
2. Tutup dan buka ulang aplikasi, kirim pertanyaan yang sama → cek tetap cache hit.
3. Amati ukuran database dan jumlah baris `ai_cache` setelah 100+ pertanyaan berbeda.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 6. Kompresi gambar multimodal

**Hipotesis:** gambar kamera berukuran besar membuat payload base64 dan memori melonjak. Resize ke maksimal 1024 px + JPEG kualitas 82 mengurangi ukuran byte secara signifikan tanpa menghilangkan keterbacaan teks.

**Perubahan:**
- `ImageOptimizer.optimizeForAi()` memakai `image` package di isolate (`compute`).
- Dipakai di `recognizeText()` dan `describeImage()`.
- MIME type disesuaikan dengan hasil konversi.

**Cara ukur:**
1. Siapkan foto 3000+ px.
2. Catat `bytes.length` sebelum dan sesudah `optimizeForAi` (log sementara atau unit test).
3. Jalankan OCR dan bandingkan waktu respons serta ukuran request di DevTools Network.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## Kesimpulan Sementara

Semua optimasi sudah terpasang dan lulus test otomatis. Kesimpulan berbasis angka **belum dapat ditulis** sampai pengukuran DevTools dilakukan pada praktikum akhir. Setelah data terkumpul, isi kolom "Hasil" di atas dan ringkas perbandingannya di README.
