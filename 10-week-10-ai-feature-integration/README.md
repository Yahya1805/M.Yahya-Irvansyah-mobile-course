# Week 10 — AI Feature Integration

Portofolio implementasi **Integrasi Fitur AI pada Aplikasi Mobile** untuk mata kuliah **Pemrograman Mobile**. Folder ini mendokumentasikan penambahan fitur asisten percakapan cerdas (*AI Chat Assistant*) berbasis streaming response, modul **AI Multimodal Studio** (*Optical Character Recognition / OCR*, *Image Understanding*, dan *Speech-to-Text*), mitigasi risiko privasi, kontrol biaya token, penanganan error cerdas, dan mekanisme *graceful offline fallback*.

---

## 📌 Ringkasan Capaian Praktikum Minggu 10

* **Mahasiswa**: M. Yahya Irvansyah
* **Mata Kuliah**: Pemrograman Mobile (Semester Genap 2026)
* **Fitur Utama yang Diintegrasikan**:
  1. **AI Chat Assistant (Streaming Response)**: Percakapan interaktif real-time dengan efek pengetikan teks token-by-token.
  2. **OCR (Optical Character Recognition)**: Pemindaian dan ekstraksi teks otomatis dari foto dokumen/KTM via Gemini Vision.
  3. **Image Understanding**: Analisis visual dan pendeskripsian objek pada gambar dalam Bahasa Indonesia.
  4. **Speech-to-Text**: Konversi input suara/audio percakapan menjadi teks.
  5. **Privacy Guard & Cost Engine**: Sanitasi data pribadi (NIK, No HP, Email), caching lokal in-memory, batasan kuota harian, serta dialog fallback saat offline/down.
* **Branch Pengerjaan**: `feat/ai-privacy-cost-fallback`
* **Keamanan Kredensial**: **100% AMAN (Zero Leakage)** — Kunci API tidak pernah ditulis langsung di kode sumber (*no hardcoded keys*), melainkan disimpan di *keystore/keychain* lokal melalui `flutter_secure_storage`.
* **Kualitas Mesin**:
  * `dart analyze`: **0 issue (Clean)**
  * `dart format`: **100% konsisten (Exit code 0)**
  * Unit & Widget Test: **Lolos pengujian sanitasi privasi, caching hemat biaya, simulasi streaming, multimodal, dan fallback offline**

---

## 🛡️ Tabel Risiko dan Mitigasi (Privasi & Biaya)

| Kategori Risiko | Potensi Masalah | Solusi Mitigasi yang Diterapkan | Bukti Pengujian |
| :--- | :--- | :--- | :--- |
| **Bocor Data Pengguna** | NIK, Nomor HP, atau Email pengguna terkirim tanpa sengaja ke cloud AI API. | Menerapkan `sanitizePrompt()` berbasis Regex untuk me-masking 16 digit NIK, nomor telepon Indonesia, dan email menjadi placeholder anonim sebelum payload dikirim. | `test/ai_privacy_cost_fallback_test.dart` (Passed) |
| **Biaya Melonjak (Cost Spike)** | Panggilan berulang dengan pertanyaan yang sama menghabiskan kuota token berbayar. | 1. **Cache Lokal In-Memory**: Query yang sama langsung mengembalikan jawaban dari cache tanpa memanggil API.<br>2. **Rate Limiting Harian**: Pembatasan maksimal 20 request per hari via Secure Storage. | `test/ai_privacy_cost_fallback_test.dart` (Passed) |
| **API Error / Down** | Jaringan terputus atau server Gemini mengalami status HTTP 500 / 429. | Menampilkan **AlertDialog Layanan AI Sibuk** dengan opsi *"Coba Lagi"* dan secara cerdas mengalihkan ke **Mode Offline Lokal** dengan visual bubble khusus bertanda `Offline Fallback`. | `test/ai_privacy_cost_fallback_test.dart` & `chat_screen.dart` |
| **Respons Tidak Relevan** | Model AI menghasilkan halusinasi jawaban di luar konteks kampus. | Mengunci persona asisten lewat instruksi prompt yang ringkas dan memvalidasi struktur respons sebelum dirender ke layar UI. | `AiService._parseGeminiResponse` |

---

## 🔒 Jaminan Keamanan API Key (Mengapa Aman di-Push ke GitHub?)

Saat Anda melakukan `git push` ke GitHub, **kunci API Anda dipastikan aman dan tidak akan bocor/terekspos ke publik**:

1. **Zero Hardcoded Secrets**:  
   Tidak ada API key asli yang ditempel di file `.dart`, `.yaml`, atau repositori.
2. **Penyimpanan Terenkripsi Perangkat (`flutter_secure_storage`)**:  
   Kode membaca kunci secara dinamis pada saat runtime:
   ```dart
   final apiKey = await _storage.read(key: 'ai_api_key');
   ```
   * Di Android: Disimpan di Android Keystore (AES encryption).
   * Di iOS: Disimpan di iOS Keychain.
   * Di Desktop Windows: Disimpan di Windows Credential Locker.
3. **Penyetelan Interaktif Lewat Aplikasi**:  
   Kunci API dimasukkan oleh pengguna secara mandiri melalui modal dialog di dalam aplikasi (klik tombol icon kunci `Icons.key` di pojok kanan atas layar chat). Data ini hanya tersimpan di memori privat HP/emulator Anda, **bukan di Git**.

---

## 🏗️ Struktur Berkas Portofolio Week 10

```
10-week-10-ai-feature-integration/
├── docs/
│   └── ai-log.md                       # Logbook Prompt Sistem, User Prompt, Output AI, & Mitigasi
├── screenshots/
│   ├── notes-list.png                  # Tampilan daftar catatan
│   ├── notes-dialog.png                # Dialog form input
│   └── notes-before.png                # State awal
├── lib/
│   ├── ai/
│   │   └── ai_service.dart          # Layanan Gemini Multimodal + Privacy Sanitizer + Caching + Fallback
│   ├── features/
│   │   ├── chat_screen.dart         # Antarmuka Chat, Streaming Bubble, Dialog API Key, & Fallback Modal
│   │   ├── multimodal_ai_screen.dart # Layar Tab OCR, Image Understanding, & Speech-to-Text
│   │   └── notes/                   # Modul Catatan Feature-First Clean Architecture (Minggu 5-9)
│   ├── core/                        # Database SQLite, utilitas format tanggal, & providers
│   ├── main.dart                    # Entry point aplikasi + navigasi ke Chat & Studio Multimodal
│   └── routes.dart                  # Routing '/ai-chat', '/ai-multimodal', dan '/notes'
├── test/
│   ├── ai_privacy_cost_fallback_test.dart # Pengujian sanitasi data pribadi, caching, dan fallback offline
│   ├── chat_screen_test.dart        # Widget test empty state, streaming bubble, & error fallback
│   ├── multimodal_ai_test.dart      # Widget test tab OCR, Vision, dan Speech-to-Text
│   ├── search_filter_test.dart      # Unit & widget test pencarian catatan
│   └── validate_note_test.dart      # Validasi invariant domain
├── README.md                        # Laporan lengkap, bukti mesin hijau, tabel risiko, & refleksi
└── pubspec.yaml                     # Dependensi: http, flutter_secure_storage, riverpod
```

---

## 🧪 Bukti Mesin Hijau (Quality Gate)

### 1. Analisis Statis (`dart analyze`)
```text
Analyzing 10-week-10-ai-feature-integration...
No issues found!
```

### 2. Format Konsistensi Kode (`dart format`)
```text
Formatted 29 files (0 changed) in 0.12 seconds. (Exit Code 0)
```

### 3. Pengujian Otomatis (`test/`)
* ✅ `sanitizePrompt` berhasil menyaring 16 digit NIK, nomor handphone, dan alamat email menjadi token privat.
* ✅ Request berulang berhasil mengambil data dari cache lokal tanpa memicu panggilan API baru (menghemat biaya token).
* ✅ Saat API mengalami kegagalan / offline, sistem secara otomatis mengalihkan ke mode jawaban offline lokal.
* ✅ Dialog *"Layanan AI Sibuk"* tampil jika terjadi gangguan jaringan dengan tombol coba lagi.
* ✅ Widget testing chat screen & multimodal tab OCR/Vision/STT berjalan 100% hijau.

---

## 💡 Refleksi Pembelajaran (Week 10)

### 1. Fitur AI mana yang Anda integrasikan dan mengapa?
* **Fitur yang Diintegrasikan**: **AI Chat Assistant dengan Streaming Response** serta modul penunjang **OCR & Image Understanding**.
* **Alasan Pemilihan**:
  Aplikasi ini merupakan aplikasi catatan dan pendukung produktivitas mahasiswa. Fitur chat asisten dengan streaming response memberikan interaktivitas tanya jawab instan bagi mahasiswa (misalnya merangkum materi kuliah atau menanyakan tips belajar), sedangkan fitur OCR sangat relevan untuk mendigitalkan teks dari kartu identitas (KTM) atau papan pengumuman secara cepat tanpa perlu mengetik ulang secara manual.

### 2. Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?
* **Tiga Lapis Perlindungan Privasi**:
  1. **Sanitasi Data Sensitif di Sisi Klien (`sanitizePrompt`)**: Sebelum prompt dikirimkan ke internet, Regex scanner secara otomatis menyaring dan mengganti 16 digit NIK menjadi `[NIK_DIRAHASIAKAN]`, nomor telepon menjadi `[NO_TELEPON_DIRAHASIAKAN]`, dan alamat email menjadi `[EMAIL_DIRAHASIAKAN]`.
  2. **Penyimpanan Kunci API Terenkripsi (`flutter_secure_storage`)**: Kunci API tidak pernah disimpan di hardcoded source code atau diunggah ke Git, melainkan disimpan di hardware-backed security (Android Keystore / iOS Keychain).
  3. **Anonimitas Permintaan**: Payload API hanya mengirimkan teks pertanyaan tanpa melampirkan metadata identitas pengguna perangkat.

### 3. Fallback apa yang Anda sediakan jika layanan AI error?
* **Mekanisme Graceful Fallback Multi-Level**:
  1. **Dialog Layanan AI Sibuk**: Jika server API down, kehabisan kuota (HTTP 429), atau mengalami timeout, sistem menampilkan dialog AlertDialog yang ramah pengguna dengan tombol *"Coba Lagi"* (retry action).
  2. **Mode Offline Lokal**: Sistem memindai kata kunci lokal (seperti *jadwal*, *catatan*, *bantuan*). Jika API mati, sistem langsung menyajikan jawaban dari memori lokal dengan indikator visual khusus berlabel `Offline Fallback` berwarna kuning keemasan (`amber`).
  3. **Cache Lokal In-Memory**: Jawaban dari pertanyaan yang pernah berhasil dijawab tetap bisa dibaca meskipun perangkat offline.

### 4. Satu hal yang Anda pelajari tentang UX fitur AI di mobile?
* **Pentingnya Feedback Asinkron yang Responsif (Streaming & Loading Indicator)**:
  Waktu inferensi model AI membutuhkan jeda beberapa detik. Jika layar hanya diam menunggu respons utuh (*blocking request*), pengguna ponsel akan mengira aplikasi mengalami *freeze* atau *hang*. Dengan menerapkan **Streaming Response (token-by-token)** disertai animasi loading mini pada gelembung obrolan, pengguna merasa sistem sedang aktif "berpikir dan mengetik", sehingga menghasilkan pengalaman pengguna (*User Experience*) yang jauh lebih hidup, transparan, dan dapat dipercaya.

---

## 🚀 Panduan Menjalankan & Memasukkan API Key

```bash
# 1. Pindah ke direktori Week 10
cd 10-week-10-ai-feature-integration

# 2. Jalankan aplikasi pada perangkat/emulator
flutter run
```

### Cara Memasukkan API Key:
1. Klik icon bintang ajaib **`Icons.auto_awesome`** di AppBar untuk membuka Chat Assistant.
2. Klik icon kunci **`Icons.key`** di pojok kanan atas AppBar.
3. Masukkan Gemini API Key Anda $\rightarrow$ Tekan **Simpan**.
