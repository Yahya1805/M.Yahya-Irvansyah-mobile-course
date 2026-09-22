# Observasi Praktikum 2-3

## Mode offline

1. Jalankan aplikasi dan buat satu catatan dari tombol `+`.
2. Pastikan badge cloud di AppBar menunjukkan `1` dan catatan tetap tampil.
3. Aktifkan `Force offline`, lalu refresh halaman. Catatan dan badge tetap tampil.
4. Ambil screenshot kondisi ini dan simpan sebagai `offline-before-sync.png`.

## Setelah sinkronisasi

1. Nonaktifkan `Force offline`.
2. Tekan tombol sync dan tunggu simulasi upload satu detik.
3. Badge kembali menjadi `0`, sedangkan catatan tetap tersimpan di perangkat.
4. Ambil screenshot dan simpan sebagai `offline-after-sync.png`.

## Aturan konflik

Sinkronisasi dua arah menggunakan **last-write-wins** berdasarkan `updated_at`.
Catatan dengan waktu pembaruan paling baru menjadi versi yang dipertahankan.