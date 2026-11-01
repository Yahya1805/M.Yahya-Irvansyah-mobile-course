# Week 10 — AI Feature Integration

Portofolio implementasi **Integrasi Fitur AI pada Aplikasi Mobile** untuk mata kuliah **Pemrograman Mobile**. Folder ini mendokumentasikan penambahan fitur asisten cerdas (*AI Chat Assistant*) berbasis streaming response, modul **AI Multimodal Studio** (*Optical Character Recognition / OCR*, *Image Understanding*, dan *Speech-to-Text*), antarmuka interaktif, penanganan error cerdas, dan mekanisme keamanan penyimpanan kunci API terenkripsi.

---

## 📌 Ringkasan Capaian Praktikum Minggu 10

* **Mahasiswa**: M. Yahya Irvansyah
* **Mata Kuliah**: Pemrograman Mobile (Semester Genap 2026)
* **Fitur Utama**:
  1. **Chat Asisten AI**: Percakapan real-time dengan streaming response token-by-token.
  2. **OCR (Optical Character Recognition)**: Ekstraksi teks otomatis dari gambar dokumen/KTM via Gemini Vision.
  3. **Image Understanding**: Analisis visual dan pendeskripsian objek pada foto ke dalam Bahasa Indonesia.
  4. **Speech-to-Text (Transkripsi Suara)**: Konversi rekaman suara/audio menjadi teks rapi.
* **Branch Pengerjaan**: `feat/ai-multimodal-features`
* **Keamanan Kredensial**: **100% AMAN (Zero Leakage)** — Kunci API tidak pernah ditulis langsung di kode sumber (*no hardcoded keys*), melainkan disimpan di *keystore/keychain* lokal melalui `flutter_secure_storage`.
* **Kualitas Mesin**:
  * `dart analyze`: **0 issue (Clean)**
  * `dart format`: **100% konsisten (Exit code 0)**
  * Unit & Widget Test: **Lolos pengujian simulasi respons streaming, OCR, Vision, STT, dan error handling**

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
│   │   └── ai_service.dart          # Layanan komunikasi Gemini Multimodal (Text, Vision, OCR, Audio)
│   ├── features/
│   │   ├── chat_screen.dart         # Antarmuka Chat, Streaming Bubble, & Dialog API Key
│   │   ├── multimodal_ai_screen.dart # Layar Tab OCR, Image Understanding, & Speech-to-Text
│   │   └── notes/                   # Modul Catatan Feature-First Clean Architecture (Minggu 5-9)
│   ├── core/                        # Database SQLite, utilitas format tanggal, & providers
│   ├── main.dart                    # Entry point aplikasi + navigasi ke Chat & Studio Multimodal
│   └── routes.dart                  # Routing '/ai-chat', '/ai-multimodal', dan '/notes'
├── test/
│   ├── chat_screen_test.dart        # Widget test empty state, streaming bubble, & error fallback
│   ├── multimodal_ai_test.dart      # Widget test tab OCR, Vision, dan Speech-to-Text
│   ├── search_filter_test.dart      # Unit & widget test pencarian catatan
│   └── validate_note_test.dart      # Validasi invariant domain
└── pubspec.yaml                     # Dependensi: http, flutter_secure_storage, riverpod
```

---

## 🛠️ Stack Teknologi

* **Framework**: Flutter SDK / Dart
* **AI Engine**: Google Gemini Multimodal API (`gemini-1.5-flash:generateContent`)
* **Network Client**: `http: ^1.2.0`
* **Credential Security**: `flutter_secure_storage: ^9.0.0`
* **State Management**: Flutter Riverpod (`flutter_riverpod: ^3.4.3`)
* **Local Persistence**: SQLite via `sqflite: ^2.4.4` & `path: ^1.9.1`

---

## 🧪 Verifikasi Mutu dan Analisis Kode

### 1. Analisis Statis (`dart analyze`)
```text
Analyzing 10-week-10-ai-feature-integration...
No issues found!
```

### 2. Formatter Konsistensi Kode (`dart format`)
```text
Formatted 28 files (0 changed) in 0.14 seconds. (Exit Code 0)
```

### 3. Pengujian Otomatis (`test/multimodal_ai_test.dart` & `test/chat_screen_test.dart`)
* ✅ Menampilkan antarmuka tab OCR, Vision, dan Speech.
* ✅ Memproses pemindaian teks pada dokumen gambar dan menampilkan hasil teks KTM.
* ✅ Menganalisis konten gambar visual dan menampilkan deskripsi objek.
* ✅ Menjalankan transkripsi rekaman audio percakapan menjadi teks.
* ✅ Menangani skenario kegagalan API secara anggun (*graceful fallback*).

---

## 🚀 Panduan Menjalankan & Memasukkan API Key

### Langkah Menjalankan:
```bash
# 1. Pindah ke direktori Week 10
cd 10-week-10-ai-feature-integration

# 2. Jalankan aplikasi pada perangkat/emulator
flutter run
```

### Cara Menggunakan Fitur:
1. **AI Chat Assistant**: Klik icon bintang ajaib **`Icons.auto_awesome`** di AppBar untuk chatting dengan Gemini secara real-time.
2. **AI Multimodal Studio**: Klik icon pemindai dokumen **`Icons.document_scanner`** di AppBar untuk membuka layar OCR, Image Understanding, dan Speech-to-Text.
3. **Pengaturan API Key**: Klik icon kunci **`Icons.key`** di pojok kanan atas layar chat untuk memasukkan Gemini API Key pribadi Anda secara aman.
