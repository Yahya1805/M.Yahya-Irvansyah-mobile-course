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
| 7 | Ekstraksi widget + `const` | Selesai | Lulus | Belum |
| 8 | Riverpod `select` pada panel notes | Selesai | Lulus | Belum |
| 9 | `RepaintBoundary` area dinamis | Selesai | Lulus | Belum |
| 10 | Tear-off callback di build | Selesai | Lulus | Belum |
| 11 | Infinite scroll `ScrollController` | Selesai | Lulus | Belum |
| 12 | Lazy grid & item `const` | Selesai | Lulus | Belum |
| 13 | Cache disk + placeholder gambar | Selesai | Lulus | Belum |
| 14 | Decode thumbnail (`memCacheWidth`) | Selesai | Lulus | Belum |
| 15 | Batas `imageCache` + precache | Selesai | Lulus | Belum |
| 16 | Dio client bersama + timeout + gzip | Selesai | Lulus | Belum |
| 17 | Retry interceptor 408/429/5xx/timeout | Selesai | Lulus | Belum |
| 18 | Cache SQLite + metadata (DB v4) | Selesai | Lulus | Belum |
| 19 | Empat strategi cache repository | Selesai | Lulus | Belum |
| 20 | Stale-while-revalidate | Selesai | Lulus | Belum |
| 21 | ETag / `If-None-Match` (304) | Selesai | Lulus | Belum |
| 22 | Payload kecil (`_limit=30`) | Selesai | Lulus | Belum |

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

## 7. Ekstraksi widget + `const` constructor

**Hipotesis:** widget yang dibangun ulang setiap parent rebuild menambah pekerjaan build/layout. Widget `const` dan ekstraksi subtree statis membuat Flutter melewati rebuild untuk instance yang identik.

**Perubahan:**
- `main.dart`: tiga `Builder` + closure diganti `_ProfileActionButton` dan daftar `actions` const.
- Notes: `_NoteListItem`, `_NotesListPanel`, `_LoadMoreIndicator` diekstrak; body memakai subtree const.
- Multimodal: `_MultimodalTab`, `_AiResultPanel`, `_ErrorBanner` diekstrak.
- `const` ditambahkan pada empty state, ikon, padding, dan teks statis.

**Cara ukur:**
1. Aktifkan `debugPrintRebuildDirtyWidgets = true`.
2. Buka halaman Catatan, ketik di search bar, lalu scroll.
3. Hitung berapa kali AppBar, FAB, dan item di luar perubahan ikut rebuild.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 8. Riverpod `select` pada panel Notes

**Hipotesis:** `ref.watch(notesProvider)` membangun ulang seluruh body setiap field state berubah, termasuk saat hanya `isLoadingMore` berubah. Dengan `select`, panel hanya rebuild saat `notes`, `query`, atau `hasMore` berubah.

**Perubahan:**
- `_NotesListPanel` memakai tiga `select` terpisah.
- `_NotesBody` mengembalikan subtree const sehingga rebuild parent tidak membangun ulang search bar/panel.
- Guard `_requestedNextPage` dipindahkan ke panel dan di-reset lewat `ref.listen`.

**Cara ukur:**
1. Tambahkan penghitung build sementara pada `_NotesListPanelState`.
2. Picu `loadMore` dan amati apakah panel rebuild lebih dari sekali.
3. Bandingkan dengan versi yang memakai `ref.watch` penuh.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 9. `RepaintBoundary` area dinamis

**Hipotesis:** repaint streaming chat dan kedipan cursor search bar dapat memicu repaint area lain jika berada di layer yang sama.

**Perubahan:**
- `RepaintBoundary` pada search bar Notes.
- `RepaintBoundary` pada area daftar pesan chat.
- `RepaintBoundary` pada panel hasil AI multimodal.

**Cara ukur:**
1. Aktifkan overlay performa / DevTools Performance.
2. Amati jumlah raster frame saat streaming chat dan saat mengetik di search bar.
3. Bandingkan dengan baseline sebelum boundary ditambahkan.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 10. Tear-off callback di build

**Hipotesis:** closure baru di build method membuat widget anak dianggap berubah dan memicu rebuild. Tear-off method yang stabil memungkinkan Flutter mempertahankan instance.

**Perubahan:**
- `_handleSubmitted` untuk `TextField.onSubmitted` chat.
- `_handleAction` dan `_buildMenuItems` statis pada item catatan.
- `_clear` pada search bar.

**Cara ukur:**
1. Aktifkan `debugPrintRebuildDirtyWidgets`.
2. Ketik di input chat dan buka menu aksi catatan.
3. Amati jumlah rebuild widget yang tidak terkait aksi.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 11. Infinite scroll dengan `ScrollController`

**Hipotesis:** meminta halaman baru hanya saat item terakhir terbangun membuat waktu tunggu lebih lama dan sulit dikendalikan. Listener scroll pada jarak 200 px dari dasar memberi waktu muat lebih awal.

**Perubahan:**
- `_NotesListPanelState` menambahkan `ScrollController` + `_onScroll`.
- `_loadMore` tetap memakai guard `_requestedNextPage` dan status `hasMore`/`isLoadingMore` di notifier.
- Footer tetap menjadi fallback untuk layar tinggi.

**Cara ukur:**
1. Buka daftar 200+ catatan dalam mode profile.
2. Scroll cepat ke bawah; rekam Performance.
3. Catat apakah ada frame kosong/jank saat halaman baru dimuat.
4. Bandingkan waktu tunggu sebelum item baru muncul dengan baseline.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 12. Lazy grid & item `const`

**Hipotesis:** `GridView.builder`/`ListView.builder` hanya membangun item di viewport, sementara item `const`/widget terpisah mengurangi pekerjaan build saat scroll.

**Perubahan:**
- Galeri memakai `GridView.builder` dengan `_GalleryTile` terpisah.
- `_LoadMoreIndicator` dan `_GalleryLoadingTile` memakai `const`.
- Tidak ada `Expanded`/`Flexible` di dalam item list/grid.

**Cara ukur:**
1. Buka Galeri, scroll cepat beberapa halaman.
2. Rekam jumlah frame yang dibangun dan frame drop.
3. Amati jumlah tile yang hidup di Widget Inspector (harus sebatas viewport + cache extent).

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 13. Cache disk + placeholder gambar

**Hipotesis:** tanpa cache disk, gambar diunduh ulang setiap halaman dibuka. Placeholder + fade-in juga mencegah layar kosong dan layout jump.

**Perubahan:**
- `CachedNetworkImage` dengan `placeholder` dan `errorWidget`.
- `fadeInDuration` 200 ms.
- Builder placeholder/error berupa fungsi statis (tear-off).

**Cara ukur:**
1. Buka Galeri, scroll, lalu keluar dan buka kembali.
2. Di DevTools Network, cek apakah request gambar yang sama terulang.
3. Catat waktu sampai tile terisi dan jumlah request.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 14. Decode thumbnail (`memCacheWidth`/`memCacheHeight`)

**Hipotesis:** gambar 800×600 yang di-decode penuh untuk tile ~300×225 membuang memori dan waktu decode. Decode pada ukuran tampil menghemat keduanya.

**Perubahan:**
- `memCacheWidth: 300`, `memCacheHeight: 225`.
- `maxWidthDiskCache: 600`, `maxHeightDiskCache: 450`.

**Cara ukur:**
1. Buka Galeri dan scroll beberapa tile.
2. Catat puncak memori gambar di DevTools Memory.
3. Bandingkan dengan versi tanpa `memCacheWidth`/`memCacheHeight`.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 15. Batas `imageCache` + precache

**Hipotesis:** image cache tanpa batas dapat menahan terlalu banyak bitmap; precache halaman berikutnya mengurangi waktu tunggu saat scroll.

**Perubahan:**
- `PaintingBinding.instance.imageCache` dibatasi 200 gambar / 80 MB.
- `precacheImage` untuk 4 thumbnail halaman berikutnya setelah frame selesai.

**Cara ukur:**
1. Buka Galeri dan scroll sampai 60 gambar.
2. Catat `imageCache.currentSizeBytes` dan puncak memori.
3. Bandingkan waktu tampil tile antara precache aktif dan nonaktif.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 16. Dio client bersama + timeout + gzip

**Hipotesis:** membuat `Dio` baru per request membuang connection pool dan interceptor. Timeout eksplisit mencegah request menggantung; `Accept-Encoding: gzip` memperkecil payload bila server mendukung.

**Perubahan:**
- `apiClientProvider` menyimpan satu `Dio` dan menutupnya saat provider di-dispose.
- `connectTimeout` 10 s, `receiveTimeout` 15 s, `sendTimeout` 10 s.
- Header `Accept-Encoding: gzip` dan logging ringkas di mode debug.

**Cara ukur:**
1. Buka Postingan dalam mode profile dengan DevTools → Network.
2. Catat ukuran transfer respons dan header `Content-Encoding`.
3. Bandingkan jumlah koneksi/request saat halaman dibuka berulang.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 17. Retry interceptor 408/429/5xx/timeout

**Hipotesis:** kegagalan sementara tidak perlu langsung ditampilkan sebagai error. Retry berjeda memberi kesempatan jaringan pulih tanpa membanjiri server.

**Perubahan:**
- `RetryInterceptor` dengan maksimal 3 percobaan dan jeda 1 s / 2 s / 5 s.
- Retry hanya untuk timeout, gagal koneksi, HTTP 408, 429, dan 5xx.
- Error 4xx lain langsung diteruskan.

**Cara ukur:**
1. Aktifkan mode pesawat sesaat atau gunakan proxy yang mengembalikan 500.
2. Catat jumlah percobaan dan waktu sampai error/berhasil.
3. Pastikan tidak ada retry untuk 404.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 18. Cache SQLite + metadata (DB v4)

**Hipotesis:** feed yang dibuka berulang tidak perlu selalu menunggu jaringan bila data terakhir tersedia di disk.

**Perubahan:**
- `SqflitePostsCacheStore` menulis payload JSON ke `cached_posts`.
- Tabel `posts_cache_meta` menyimpan `etag` dan `last_synced_at`.
- Database naik ke versi 4 dengan migrasi `CREATE TABLE IF NOT EXISTS`.

**Cara ukur:**
1. Muat Postingan sekali saat online.
2. Tutup dan buka kembali halaman; catat waktu sampai item pertama tampil.
3. Bandingkan dengan kondisi cache kosong.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 19. Empat strategi cache repository

**Hipotesis:** setiap jenis data butuh trade-off berbeda antara kesegaran dan kecepatan. Repository perlu menyediakan cache-first, network-first, stale-while-revalidate, dan cache-only.

**Perubahan:**
- `PostsRepositoryImpl.loadPosts(policy: ...)` menangani keempat strategi.
- Cache-first tidak menyentuh API bila cache ada.
- Network-first memakai cache sebagai fallback saat API gagal.
- Cache-only tidak melakukan request jaringan.

**Cara ukur:**
1. Buka Postingan dan ganti strategi melalui dropdown.
2. Di DevTools → Network, catat kapan request terjadi.
3. Matikan jaringan dan bandingkan perilaku tiap strategi.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 20. Stale-while-revalidate

**Hipotesis:** menampilkan cache lebih dulu membuat konten terlihat segera, sementara revalidasi latar belakang menjaga data tetap segar.

**Perubahan:**
- Policy SWR memanggil `onCache` dengan data cache sebelum request jaringan.
- `PostsNotifier` menampilkan cache dengan indikator refresh, lalu mengganti state saat data segar tiba.
- Bila revalidasi gagal, cache tetap tampil dengan pesan fallback.

**Cara ukur:**
1. Pastikan cache sudah terisi, lalu buka Postingan dengan policy SWR.
2. Catat waktu item pertama muncul dan waktu data segar menggantikan cache.
3. Amati apakah ada layar kosong/loading penuh.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 21. ETag / `If-None-Match` (304)

**Hipotesis:** bila data tidak berubah, mengunduh ulang body hanya membuang bandwidth. ETag memungkinkan server menjawab 304 tanpa body.

**Perubahan:**
- ETag cache dikirim sebagai `If-None-Match` bersama `Cache-Control: no-cache`.
- Respons 304 memakai isi cache dan hanya memperbarui `last_synced_at`.
- UI menampilkan badge `304 · tidak berubah`.

**Cara ukur:**
1. Muat Postingan sekali, lalu tekan refresh.
2. Di DevTools → Network, catat status (200/304) dan ukuran transfer.
3. Bandingkan ukuran body 200 vs 304.
4. Uji manual: JSONPlaceholder mengirim `ETag` dan membalas 304 untuk `If-None-Match` yang sama.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## 22. Payload kecil (`_limit=30`)

**Hipotesis:** meminta sebagian data mengurangi ukuran respons, waktu parsing, dan memori daftar.

**Perubahan:**
- Request memakai query `_limit=30`.
- Hanya field yang dibutuhkan (`id`, `userId`, `title`, `body`) yang dipetakan ke entity.
- Pemilihan field di server (`?fields=...`) tidak dipaksakan karena JSONPlaceholder tidak mendukungnya.

**Cara ukur:**
1. Bandingkan ukuran respons `_limit=30` dengan tanpa `_limit` di DevTools → Network.
2. Catat waktu parsing dan jumlah item yang dibangun.
3. Pastikan daftar tetap memakai `ListView.builder`.

**Hasil baseline:** _belum diukur_

**Hasil setelah optimasi:** _belum diukur_

**Catatan/observasi:** _isi saat praktikum_

---

## Kesimpulan Sementara

Semua optimasi sudah terpasang dan lulus test otomatis. Kesimpulan berbasis angka **belum dapat ditulis** sampai pengukuran DevTools dilakukan pada praktikum akhir. Setelah data terkumpul, isi kolom "Hasil" di atas dan ringkas perbandingannya di README.
