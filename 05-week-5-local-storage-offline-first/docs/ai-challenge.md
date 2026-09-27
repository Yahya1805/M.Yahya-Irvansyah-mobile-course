# AI Challenge

## Prompt

> Saya sedang membuat aplikasi Flutter Offline Notes untuk pembelajaran. Bandingkan SharedPreferences, Hive, sqflite, dan Drift untuk preferensi sederhana serta catatan offline dengan CRUD, sorting `updated_at`, dirty flag, cache-first, dan sync. Jelaskan trade-off teknis, testing, migrasi, dan rekomendasi yang mudah dipresentasikan mahasiswa pemula.

## Rekomendasi yang Diterima

- SharedPreferences untuk dark mode dan waktu terakhir dibuka.
- sqflite/SQLite untuk notes terstruktur.
- Repository sebagai batas antara UI dan storage.
- Dirty flag untuk menandai perubahan lokal yang belum sync.
- Last-write-wins sebagai aturan konflik sederhana.
- Cache dibaca lebih dahulu agar UI tetap berguna saat offline.

## Rekomendasi yang Ditolak atau Ditunda

- Drift tidak dipakai pada versi pembelajaran ini. Drift memiliki type-safety dan reactive query yang baik, tetapi code generation dan setup migration menambah konsep sebelum mahasiswa memahami SQL dasar.
- Hive tidak dipakai karena kebutuhan project secara langsung membutuhkan sorting, filter dirty, dan kemungkinan query relasional. Hive tetap cocok untuk cache object sederhana.
- SharedPreferences tidak dipakai untuk seluruh daftar notes karena bukan database query dan akan menulis ulang koleksi besar sebagai JSON.
- Sync queue terpisah belum ditambahkan. Dirty flag cukup untuk scope tugas ini; queue terpisah lebih cocok ketika perlu retry per operasi, delete tombstone, dan audit error.

## Catatan Teknis

JSONPlaceholder hanya backend simulasi. HTTP 2xx menandai catatan sebagai clean, sedangkan kegagalan jaringan mempertahankan dirty flag. Implementasi production perlu autentikasi, retry/backoff, versi server, dan aturan konflik yang lebih kuat.
