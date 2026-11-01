# Week 10 — AI Feature Integration

Portofolio implementasi **Integrasi Fitur AI pada Aplikasi Mobile** untuk mata kuliah **Pemrograman Mobile**. Folder ini mendokumentasikan penambahan fitur asisten cerdas (*AI Chat Assistant*) berbasis streaming response, antarmuka interaktif, penanganan error cerdas, dan mekanisme keamanan penyimpanan kunci API terenkripsi.

---

## 📌 Ringkasan Capaian Praktikum Minggu 10

* **Mahasiswa**: M. Yahya Irvansyah
* **Mata Kuliah**: Pemrograman Mobile (Semester Genap 2026)
* **Fitur Tambahan**: Asisten Percakapan Cerdas (*AI Chat Assistant*) + *Streaming Response* + Pengaturan API Key Terenkripsi
* **Branch Pengerjaan**: `feat/ai-chat-integration`
* **Keamanan Kredensial**: **100% AMAN (Zero Leakage)** — Kunci API tidak pernah ditulis langsung di kode sumber (*no hardcoded keys*), melainkan disimpan di *keystore/keychain* lokal melalui `flutter_secure_storage`.
* **Kualitas Mesin**:
  * `dart analyze`: **0 issue (Clean)**
  * `dart format`: **100% konsisten (Exit code 0)**
  * Unit & Widget Test: **Lolos pengujian simulasi respons streaming dan error handling**

---

## 🔒 Jaminan Keamanan API Key (Mengapa Aman di-Push ke GitHub?)

Saat Anda melakukan `git push` ke GitHub, **kunci API Anda dipastikan aman dan tidak akan bocor/terekspos ke publik**. Berikut alasannya:

1. **Zero Hardcoded Secrets**:  
   Tidak ada API key asli yang ditempel di file `.dart`, `.yaml`, atau repositori.
2. **Penyimpanan Terenkripsi Perangkat (`flutter_secure_storage`)**:  
   Kode membaca kunci secara dinamis pada saat runtime:
   ```dart
   final apiKey = await _storage.read(key: 'ai_api_key');
   ```
   * Di Android: Disimpan di Android Keystore (AES encryption).
   * Di iOS: Disimpan di iOS Keychain.
   * Di Desktop/Web: Disimpan di secure credential locker OS.
3. **Penyetelan Interaktif Lewat Aplikasi**:  
   Kunci API dimasukkan oleh pengguna secara mandiri melalui modal dialog di dalam aplikasi (klik tombol icon kunci `Icons.key` di pojok kanan atas layar chat). Data ini hanya tersimpan di memori privat HP/emulator Anda, **bukan di Git**.

---

## 🏗️ Struktur Berkas Fitur AI

```
10-week-10-ai-feature-integration/
├── lib/
│   ├── ai/
│   │   └── ai_service.dart          # Layanan komunikasi API LLM (Gemini) & secure storage
│   ├── features/
│   │   ├── chat_screen.dart         # Antarmuka Chat, Streaming Bubble, & Dialog API Key
│   │   └── notes/                   # Modul Catatan Feature-First Clean Architecture (Minggu 5-9)
│   ├── core/                        # Database SQLite, utilitas format tanggal, & providers
│   ├── main.dart                    # Entry point aplikasi + navigasi ke AI Assistant
│   └── routes.dart                  # Routing '/ai-chat' dan '/notes'
├── test/
│   ├── chat_screen_test.dart        # Widget test empty state, streaming bubble, & error fallback
│   ├── search_filter_test.dart      # Unit & widget test pencarian catatan
│   └── validate_note_test.dart      # Validasi invariant domain
└── pubspec.yaml                     # Dependensi: http, flutter_secure_storage, riverpod
```

---

## 🛠️ Stack Teknologi

* **Framework**: Flutter SDK / Dart
* **AI Service Provider**: Google Gemini API (`gemini-1.5-flash:generateContent`)
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
Formatted 26 files (0 changed) in 0.12 seconds. (Exit Code 0)
```

### 3. Pengujian Otomatis (`test/chat_screen_test.dart`)
* ✅ Menampilkan tampilan awal percakapan (*empty state*) dengan icon asisten ramah.
* ✅ Menerima prompt pengguna dan menampilkan efek respons teks mengalir (*streaming chunks*).
* ✅ Menangani skenario kegagalan API secara anggun (*graceful fallback*) dan memunculkan SnackBar dengan tombol langsung menuju pengaturan API Key.

---

## 🚀 Panduan Menjalankan & Memasukkan API Key

### Langkah Menjalankan:
```bash
# 1. Pindah ke direktori Week 10
cd 10-week-10-ai-feature-integration

# 2. Jalankan aplikasi pada perangkat/emulator
flutter run
```

### Cara Memasukkan API Key Anda Sendiri di Aplikasi:
1. Buka aplikasi $\rightarrow$ Pada AppBar halaman utama, klik icon bintang ajaib **`Icons.auto_awesome`** (AI Assistant).
2. Di halaman Chat, klik icon kunci **`Icons.key`** di pojok kanan atas AppBar.
3. Tempelkan Google Gemini API Key Anda $\rightarrow$ Tekan **Simpan**.
4. Ketik pertanyaan Anda di form bawah $\rightarrow$ Asisten AI akan merespons secara interaktif!
