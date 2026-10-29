# Lembar Refleksi: Mid-Project Review & Code Review (Week 8)

Dokumen ini memuat jawaban refleksi kritis terkait praktik peer review, audit arsitektur, dan evaluasi hasil AI code reviewer pada penugasan paruh semester mata kuliah Pemrograman Mobile.

---

## 1. Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?

### Perbedaan:
* **LGTM Buta (*Rubber-Stamp Review*)**:  
  Memberikan persetujuan (*Approve*) secara instan dengan komentar singkat seperti "LGTM" (Looks Good To Me) hanya berdasarkan judul PR, deskripsi umum, atau melihat tanda centang hijau pada pipeline CI tanpa membaca detail baris kode (*diff*), tanpa memeriksa implikasi desain arsitektur, dan tanpa melakukan checkout branch untuk pengujian fungsionalitas secara lokal.
* **Approve yang Bertanggung Jawab**:  
  Meninjau kebenaran logika kode baris demi baris, memverifikasi penanganan *edge cases* (seperti sanitasi *whitespace* dan penanganan status error), memastikan batasan *Clean Architecture Dependency Rule* tidak dilanggar, memastikan ketersediaan pengujian otomatis (*unit & widget tests*), serta memastikan kode lolos analisis statis (`flutter analyze`) dan format resmi (`dart format`).

### Risiko bagi Tim:
1. **Kebocoran Bug & Regresi ke Produksi**: Cacat fungsional yang lolos dari review akan langsung dirasakan pengguna akhir di lini produksi.
2. **Erosi Arsitektur & Akumulasi Technical Debt**: Masuknya kode instan atau dependensi terlarang (misal UI masuk ke domain) membuat kode sulit di-maintain dan mahal untuk di-refactor di masa mendatang.
3. **Rasa Aman Semu (*False Sense of Security*)**: Tim merasa aman karena ada alur Pull Request, padahal kualitas perangkat lunak tidak tersaring dengan benar.

---

## 2. Kapan komentar wajib berstatus request changes, dan kapan cukup saran?

### Wajib Berstatus `Request Changes` (Blocker / Wajib Diperbaiki):
* **Cacat Logika & Kebenaran Data**: Ditemukan bug yang merusak fungsi atau mengorup persistensi data (misal catatan dapat tersimpan hanya dengan spasi tanpa judul).
* **Pelanggaran Arsitektur**: Terjadi kebocoran layer (misal mengimpor `flutter/material.dart` atau query database di dalam domain use case).
* **Kegagalan Quality Gate**: Analisis statis gagal (`flutter analyze` ada error/lint) atau *automated tests* gagal (*red CI*).
* **Keamanan & Performa Fatal**: Kebocoran kredensial atau *memory leak* terbukti pada alokasi resource.
* **Ketiadaan Test**: Fitur baru krusial dimasukkan tanpa menyertakan unit test pendukung.

### Cukup Berstatus Saran / Nitpick (`Comment` / Non-blocking):
* Rekomendasi penamaan variabel yang lebih ekspresif selama nama awal tidak menimbulkan ambiguitas.
* Saran pemanfaatan fitur bahasa modern (misal Dart 3 pattern matching / switch expression) yang tidak memengaruhi logika bisnis.
* Optimasi mikro yang belum terbukti menjadi bottleneck performa.
* Perbaikan minor pada typo komentar/dokumentasi atau pemformatan teks pesan commit.

---

## 3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?

### Usulan AI yang DITOLAK KERAS:
1. **Temuan AI #2 (Inject `BuildContext` & SnackBar ke Domain)**:  
   AI menyarankan agar domain usecase `AddNote` langsung mengimpor `package:flutter/material.dart` dan `package:go_router/go_router.dart` untuk menampilkan notifikasi UI dan menutup dialog.  
   * **Alasan Penolakan**: **Pelanggaran fatal Clean Architecture Dependency Rule!** Domain harus murni Dart (*pure Dart*). Mengikat usecase ke framework UI menghancurkan portabilitas, mempersulit unit test headless, dan merusak decoupling.
2. **Temuan AI #5 (Tuduhan Memory Leak & Memaksa StatefulWidget)**:  
   AI menuduh bahwa Riverpod `FutureProvider` menyebabkan memory leak dan mendesak refactor ke `StatefulWidget` dengan manual stream subscription controller.  
   * **Alasan Penolakan**: **Halusinasi AI.** Riverpod secara deklaratif mengelola lifecycle dan auto-dispose provider melalui `ref.watch()`. Memaksakan stateful controller manual adalah *premature optimization* dan anti-pattern.

### Usulan AI yang DITERIMA & DITINDAKLANJUTI:
1. **Temuan AI #1 (Sanitasi Whitespace)**: Penggunaan `title.trim().isEmpty` diterapkan untuk memastikan invariant bisnis terjaga.
2. **Temuan AI #3 (Pengecekan Rows Affected)**: Memastikan hasil update SQLite diverifikasi agar tidak menganggap sukses jika record target hilang.
3. **Temuan AI #4 (Negative Test Suite)**: Menambahkan 5 skenario kegagalan validasi pada `test/validate_note_test.dart`.

---

## 4. Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya?

### Hal Konkret yang Diperbaiki:
Menerapkan validasi sanitasi input berbasis invariant di Domain Use Case (`AddNote` dan `UpdateNote`) menggunakan `title.trim().isEmpty`, mengembalikan `ValidationFailure` terstruktur bila tidak valid, serta melengkapinya dengan 5 skenario automated unit test di `test/validate_note_test.dart`.

### Dampaknya:
1. **Integritas Database**: Tidak ada lagi catatan "hantu" tanpa judul yang lolos ke database SQLite lokal.
2. **Kejelasan Error di UI**: Lapisan presentasi menerima pesan kesalahan spesifik (`ValidationFailure('Judul tidak boleh kosong')`) sehingga dapat memunculkan feedback instan kepada user sebelum query diproses.
3. **Jaminan Regresi Hijau**: Kode terverifikasi steril dengan 14 automated tests passed dan `flutter analyze` 0 issues, memberikan keyakinan tinggi saat integrasi ke branch `develop`.

