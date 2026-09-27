# Sinkronisasi dan Conflict Resolution

## Dirty Flag

- `dirty = 1`: catatan dibuat atau diubah secara lokal dan belum berhasil dikirim.
- `dirty = 0`: catatan terakhir sudah berhasil dikirim ke server simulasi.
- Saat create/update lokal, catatan langsung disimpan ke SQLite dengan `dirty = 1`.
- Saat request sync mendapat HTTP 2xx, repository mengubah catatan tersebut menjadi `dirty = 0`.
- Jika jaringan gagal, error ditampilkan dan nilai `dirty` tetap `1`.

## Cache-first

Daftar posts dibaca dari tabel `cached_posts` terlebih dahulu. Saat online, aplikasi mencoba refresh dari JSONPlaceholder di background dan menyimpan respons yang berhasil ke SQLite. Jika request gagal, cache lama tetap ditampilkan.

JSONPlaceholder hanya digunakan sebagai simulasi backend. Endpoint publik ini bukan sistem sinkronisasi production dan tidak menjamin penyimpanan data aplikasi.

## Last-write-wins

Aturan project adalah **last-write-wins**: versi dengan `updated_at` paling baru dianggap sebagai versi yang menang. Timestamp dibandingkan dalam format ISO-8601 yang konsisten.

Dalam implementasi pembelajaran saat ini, sync mengirim `updated_at` lokal ke endpoint simulasi. Server production seharusnya mengembalikan versi remote dan repository membandingkan kedua timestamp sebelum menerima atau menolak perubahan.

Konsekuensinya:

- Sederhana untuk dipahami dan diimplementasikan.
- Perubahan yang lebih lama dapat tertimpa tanpa penggabungan isi.
- Jika jam perangkat salah, timestamp lokal bisa menyesatkan.
- Konflik pada bagian berbeda dari isi catatan tidak digabung secara otomatis.

Untuk aplikasi production, gunakan versi server, revisi/ETag, atau strategi merge yang lebih kuat.
