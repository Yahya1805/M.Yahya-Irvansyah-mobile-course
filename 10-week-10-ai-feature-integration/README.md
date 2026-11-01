# Week 10 — AI Feature Integration

Portofolio implementasi **Integrasi Fitur AI pada Aplikasi Mobile** untuk mata kuliah **Pemrograman Mobile**. Folder ini mendokumentasikan penambahan fitur asisten cerdas (*AI Chat Assistant*) berbasis streaming response, modul **AI Multimodal Studio** (*Optical Character Recognition / OCR*, *Image Understanding*, dan *Speech-to-Text*), mitigasi risiko privasi, kontrol biaya token, penanganan error cerdas, dan mekanisme *graceful offline fallback*.

---

## 📌 Ringkasan Capaian Praktikum Minggu 10

* **Mahasiswa**: M. Yahya Irvansyah
* **Mata Kuliah**: Pemrograman Mobile (Semester Genap 2026)
* **Fitur Utama**:
  1. **Chat Asisten AI**: Percakapan real-time dengan streaming response token-by-token.
  2. **OCR (Optical Character Recognition)**: Ekstraksi teks otomatis dari gambar dokumen/KTM via Gemini Vision.
  3. **Image Understanding**: Analisis visual dan pendeskripsian objek pada foto ke dalam Bahasa Indonesia.
  4. **Speech-to-Text (Transkripsi Suara)**: Konversi rekaman suara/audio menjadi teks rapi.
  5. **Privasi, Biaya, & Fallback Engine**: Masking data sensitif otomatis, cache lokal hemat kuota, limit harian, dan dialog fallback saat AI sibuk/down.
* **Branch Pengerjaan**: `feat/ai-privacy-cost-fallback`
* **Keamanan Kredensial**: **100% AMAN (Zero Leakage)** — Kunci API tidak pernah ditulis langsung di kode sumber (*no hardcoded keys*), melainkan disimpan di *keystore/keychain* lokal melalui `flutter_secure_storage`.
* **Kualitas Mesin**:
  * `dart analyze`: **0 issue (Clean)**
  * `dart format`: **100% konsisten (Exit code 0)**
  * Unit & Widget Test: **Lolos pengujian sanitasi privasi, caching hemat biaya, dan fallback offline**

---

## 🛡️ Matriks Risiko dan Mitigasi (Privasi, Biaya, & Fallback)

| Kategori Risiko | Potensi Masalah | Solusi Mitigasi yang Diterapkan | Bukti Pengujian |
| :--- | :--- | :--- | :--- |
| **Bocor Data Pengguna** | NIK, Nomor HP, atau Email pengguna terkirim tanpa sengaja ke cloud AI API. | Menerapkan `sanitizePrompt()` berbasis Regex untuk me-masking 16 digit NIK, nomor telepon Indonesia, dan email menjadi placeholder anonim sebelum payload dikirim. | `test/ai_privacy_cost_fallback_test.dart` (Passed) |
| **Biaya Melonjak (Cost Spike)** | Panggilan berulang dengan pertanyaan yang sama menghabiskan kuota token berbayar. | 1. **Cache Lokal In-Memory**: Query yang sama langsung mengembalikan jawaban dari cache tanpa memanggil API.<br>2. **Rate Limiting Harian**: Pembatasan maksimal request per hari via Secure Storage. | `test/ai_privacy_cost_fallback_test.dart` (Passed) |
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

## 🏗️ Struktur Berkas Fitur AI

```
10-week-10-ai-feature-integration/
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
└── pubspec.yaml                     # Dependensi: http, flutter_secure_storage, riverpod
```

---

## 🧪 Verifikasi Mutu dan Analisis Kode

### 1. Analisis Statis (`dart analyze`)
```text
Analyzing 10-week-10-ai-feature-integration...
No issues found!
```

### 2. Formatter Konsistensi Kode (`dart format`)
```text
Formatted 29 files (0 changed) in 0.12 seconds. (Exit Code 0)
```

### 3. Pengujian Otomatis
* ✅ `sanitizePrompt` berhasil menyaring 16 digit NIK, nomor handphone, dan alamat email.
* ✅ Request berulang berhasil mengambil data dari cache lokal tanpa memicu panggilan API baru (menghemat biaya token).
* ✅ Saat API mengalami kegagalan / offline, sistem secara otomatis mengalihkan ke mode jawaban offline lokal.
* ✅ Dialog *"Layanan AI Sibuk"* tampil jika terjadi gangguan jaringan dengan tombol coba lagi.

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
