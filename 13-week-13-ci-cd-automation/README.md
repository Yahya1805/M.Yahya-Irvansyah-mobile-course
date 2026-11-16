# Laporan Praktikum Minggu 13: CI/CD & Automation

**Mata Kuliah:** Pemrograman Mobile  
**Nama:** M. Yahya Irvansyah  
**NIM:** 2241720000 *(sesuaikan jika diperlukan)*  
**Kelas:** TI-3  
**Topik:** Automasi CI/CD dengan GitHub Actions untuk Aplikasi Flutter  

---

## 1. Ikhtisar & Tujuan Pembelajaran

Pemeriksaan manual yang berulang mudah terlewat dan sulit direproduksi antar mesin pengembang. Pada praktikum ini, dibangun pipeline otomatis berbasis **GitHub Actions** yang terisolasi khusus untuk proyek `13-week-13-ci-cd-automation`.

### Capaian:
1. **Continuous Integration (CI):** Menjalankan pemeriksaan format kode (`dart format`), analisis kode statis (`flutter analyze`), dan pengujian unit/widget otomatis beserta laporan cakupan (`flutter test --coverage`).
2. **Continuous Delivery (CD):** Membangun paket rilis Android berupa APK (`flutter build apk --release`) dan App Bundle (`flutter build appbundle --release`).
3. **Penyimpanan Artefak:** Mengunggah file biner APK & AAB menggunakan `actions/upload-artifact@v4` agar dapat diunduh langsung untuk pengujian internal.
4. **Keamanan & Versioning:** Menerapkan prinsip *least privilege*, pemisahan secrets vs konfigurasi publik, pemahaman batasan `--dart-define`, serta Semantic Versioning.

---

## 2. Struktur Pipeline CI/CD ([.github/workflows/flutter-ci.yml](../../.github/workflows/flutter-ci.yml))

Workflow dirancang modular dan aman dengan konfigurasi berikut:

```yaml
name: Flutter CI

on:
  push:
    branches: [main, develop]
    paths:
      - '13-week-13-ci-cd-automation/**'
      - '.github/workflows/flutter-ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - '13-week-13-ci-cd-automation/**'
      - '.github/workflows/flutter-ci.yml'
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test-and-build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: 13-week-13-ci-cd-automation
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage

      - run: flutter build apk --release
      - run: flutter build appbundle --release

      - uses: actions/upload-artifact@v4
        with:
          name: android-builds
          path: |
            13-week-13-ci-cd-automation/build/app/outputs/flutter-apk/app-release.apk
            13-week-13-ci-cd-automation/build/app/outputs/bundle/release/app-release.aab
          if-no-files-found: error
          retention-days: 7
```

### Isolasi Folder (Monorepo Guard):
* Parameter `paths` membatasi eksekusi hanya jika terdapat commit pada `13-week-13-ci-cd-automation/**` atau file workflow. Folder week lain tidak terpicu secara tidak perlu.
* Parameter `defaults.run.working-directory: 13-week-13-ci-cd-automation` mengunci eksekusi terminal hanya di folder Week 13.

---

## 3. Tahapan Pengujian Lokal & Quality Gates

| Tahap | Perintah | Tujuan | Status Lokal |
|---|---|---|---|
| **Format** | `dart format --output=none --set-exit-if-changed .` | Memastikan konsistensi penulisan kode sesuai konvensi Dart resmi tanpa deviasi. | **PASSED** (0 unformatted files) |
| **Lint / Analyze** | `flutter analyze --fatal-infos` | Memeriksa potensi bug, bad practice, dan tipe data statis. Flag `--fatal-infos` menghentikan build jika ada info/warning sekecil apa pun. | **PASSED** (No issues found) |
| **Automated Testing** | `flutter test --coverage` | Menjalankan suite pengujian widget/unit dan menghasilkan file rekapan coverage `lcov.info`. | **PASSED** (All tests passed) |
| **Android APK Build** | `flutter build apk --release` | Kompilasi biner APK release mandiri untuk testing internal dan sideloading. | **SIAP DI CI** |
| **Android AAB Build** | `flutter build appbundle --release` | Kompilasi Android App Bundle teroptimasi untuk Google Play Store. | **SIAP DI CI** |

---

## 4. Analisis Versi, Secrets, dan Keamanan

### 1. Semantic Versioning (SemVer)
* Format pada `pubspec.yaml`:
  $$\text{version: } \text{MAJOR}.\text{MINOR}.\text{PATCH}+\text{BUILD\_NUMBER}$$
  * Contoh: `1.0.0+1`
  * **MAJOR:** Perubahan besar yang merombak API / arsitektur sehingga tidak backward compatible.
  * **MINOR:** Penambahan fitur baru yang tetap kompatibel dengan versi sebelumnya.
  * **PATCH:** Perbaikan bug tanpa mengubah atau menambah fitur baru.
  * **BUILD_NUMBER:** Nomor build inkremental yang wajib bertambah setiap kali melakukan rilis/unggah baru ke Google Play Console (`versionCode` di Android).
* **Git Tagging:**
  Setiap rilis produksi ditandai dengan Git Tag (misalnya `v1.0.0`). Tag hanya boleh disematkan pada commit yang telah lulus seluruh tahapan quality gates di pipeline CI/CD.

### 2. Manajemen Secrets & Batasan `--dart-define`
* **Prinsip Least Privilege:** Workflow CI/CD hanya diberikan izin `permissions: contents: read`. Job pull request tidak membutuhkan hak write.
* **GitHub Secrets:**
  * Password keystore, sertifikat signing `.jks`, dan token privat API backend wajib disimpan di menu **Settings $\rightarrow$ Secrets and variables $\rightarrow$ Actions**.
  * Secrets disuntikkan secara dinamis saat runtime runner dan tidak pernah dicetak (*masked*) ke log console.
* **Perbedaan Konfigurasi vs Credentials:**
  * Base URL API (`https://api.example.com`), nama environment (`staging`/`production`), dan flag fitur adalah konfigurasi publik.
  * API Secret Key, JWT Private Key, dan Keystore Password adalah credentials rahasia.
* **Batasan Kritis `--dart-define`:**
  * Nilai `--dart-define` (misal `--dart-define=API_KEY=xxx`) **bukan rahasia aman** karena dikompilasi langsung ke dalam biner aplikasi klien (APK/AAB).
  * Siapa pun dapat mengekstrak string tersebut melalui proses *reverse engineering* (dekompilasi APK menggunakan JADX atau apktool).
  * Jangan menyimpan private credentials backend di dalam kode aplikasi klien Flutter.
* **Keystore Produksi:**
  * Keystore produksi tidak boleh dijalankan pada workflow Pull Request dari kontributor luar/fork.
  * Proses signing release sebaiknya dipisahkan pada pipeline khusus (*Release Workflow*) yang hanya terpicu saat pembuatan Git Tag rilis resmi.
