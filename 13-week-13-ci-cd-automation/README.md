# Laporan Praktikum Minggu 13: CI/CD & Automation

**Mata Kuliah:** Pemrograman Mobile  
**Nama:** M. Yahya Irvansyah  
**NIM:** 2241720000  
**Kelas:** TI-3  
**Topik:** Automasi CI/CD dengan GitHub Actions untuk Aplikasi Flutter  
**Branch:** `feat/ci-cd-automation`  
**Target Merge:** `develop` / `main`  

---

## 1. Ikhtisar & Tujuan Pembelajaran

Pemeriksaan manual yang berulang mudah terlewat dan sulit direproduksi antar mesin pengembang. Pada praktikum ini, dibangun pipeline otomatis berbasis **GitHub Actions** yang terisolasi khusus untuk proyek `13-week-13-ci-cd-automation`.

### Capaian:
1. **Continuous Integration (CI):** Menjalankan pemeriksaan format kode (`dart format`), analisis statis (`flutter analyze`), dan pengujian unit/widget otomatis beserta rekapan cakupan (`flutter test --coverage`).
2. **Continuous Delivery (CD):** Membangun paket rilis Android berupa APK (`flutter build apk --release`) dan App Bundle (`flutter build appbundle --release`).
3. **Penyimpanan Artefak:** Mengunggah file biner APK & AAB menggunakan `actions/upload-artifact@v4` agar dapat diunduh langsung untuk pengujian internal.
4. **Keamanan & Versioning:** Menerapkan prinsip *least privilege*, pemisahan secrets vs konfigurasi publik, pemahaman batasan `--dart-define`, serta Semantic Versioning.

---

## 2. Struktur Pipeline CI/CD ([.github/workflows/flutter-ci.yml](../../.github/workflows/flutter-ci.yml))

Workflow dirancang modular, aman, dan efisien dengan konfigurasi berikut:

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
* **Path Filtering:** Parameter `paths` memastikan GitHub Actions hanya terpicu jika ada perubahan pada file di dalam folder `13-week-13-ci-cd-automation/**` atau file workflow-nya sendiri. Perubahan di folder Week 1–12 atau Week 14–16 tidak akan memicu build yang tidak perlu.
* **Working Directory:** Parameter `defaults.run.working-directory: 13-week-13-ci-cd-automation` mengunci eksekusi seluruh perintah build dan test hanya di direktori Week 13.

---

## 3. Tahapan Pengujian Lokal & Quality Gates

Sebelum melakukan push ke GitHub, seluruh tahapan pemeriksaan telah divalidasi secara lokal:

| Tahap Quality Gate | Perintah | Tujuan | Hasil Verifikasi Lokal |
|---|---|---|---|
| **Code Formatting** | `dart format --output=none --set-exit-if-changed .` | Memastikan kepatuhan terhadap gaya kode standar Dart resmi. | **PASSED** (0 files changed) |
| **Static Code Analysis** | `flutter analyze --fatal-infos` | Mendeteksi error sintaksis, bad practice, dan potensi bug dengan toleransi 0 terhadap warning/info. | **PASSED** (No issues found) |
| **Automated Widget Testing** | `flutter test --coverage` | Menguji rendering UI profil mahasiswa dan menghasilkan file cakupan `coverage/lcov.info`. | **PASSED** (All tests passed) |
| **Android Release APK** | `flutter build apk --release` | Kompilasi paket biner `.apk` untuk instalasi langsung dan pengujian manual. | **Dikonfigurasi di CI** |
| **Android Release AAB** | `flutter build appbundle --release` | Kompilasi Android App Bundle `.aab` untuk rilis produksi Google Play Store. | **Dikonfigurasi di CI** |

---

## 4. Analisis Versi, Secrets, dan Keamanan

### 1. Semantic Versioning (SemVer)
* **Format `pubspec.yaml`:**
  $$\text{version: } \mathbf{MAJOR}.\mathbf{MINOR}.\mathbf{PATCH}+\mathbf{BUILD\_NUMBER}$$
  * Saat ini: `1.0.0+1`
  * **Rencana Versi Berikutnya:**
    * `1.0.1+2` jika iterasi berikutnya adalah perbaikan bug (*patch*).
    * `1.1.0+2` jika iterasi berikutnya menambahkan fitur fungsional baru (*minor*).
    * Nomor build inkremental wajib naik (`+1` $\rightarrow$ `+2`) untuk setiap unggahan baru agar dikenali sebagai rilis baru oleh Google Play Console (`versionCode`).
* **Git Tagging:**
  Setiap rilis produksi ditandai dengan Git tag seperti `v1.0.0`. Tag hanya dibuat pada commit yang telah lulus seluruh tahapan pemeriksaan CI.

### 2. Manajemen Secrets & DevSecOps
* **Prinsip Least Privilege:** Workflow hanya menggunakan `permissions: contents: read`. Job pull request tidak memerlukan hak tulis (*write access*).
* **GitHub Actions Secrets:** Password keystore, sertifikat `.jks`, dan token privat API wajib disimpan di GitHub Secrets, bukan di source code repositori.
* **Perbedaan Konfigurasi vs Credentials:** URL endpoint API dan nama environment adalah konfigurasi publik. Sedangkan API private key dan keystore password adalah credentials rahasia.
* **Batasan Kritis `--dart-define`:** Nilai `--dart-define` bukan tempat aman untuk private secret backend karena dikompilasi ke dalam biner aplikasi klien dan dapat diekstrak melalui dekompilasi APK (reverse engineering).
* **Keamanan Keystore:** Keystore produksi tidak boleh diekspos ke workflow Pull Request. Proses penandatanganan rilis produksi harus diisolasi pada workflow terpisah yang hanya dipicu oleh Git Tag rilis resmi.

---

## 5. Riwayat Commit & Eksekusi Pipeline

Pipeline telah diintegrasikan pada branch `feat/ci-cd-automation` dan di-push ke GitHub:

| Commit Hash | Pesan Commit | Keterangan |
|---|---|---|
| `4c6f8b2` | `feat(ci): add flutter-ci workflow and fix local format and tests for week 13` | Penyiapan workflow CI awal, pembersihan format `main.dart`, konfigurasi linter, dan penyesuaian unit test. |
| `cbf6139` | `feat(ci): add android apk and aab release build and artifact upload steps` | Penambahan build release APK & AAB serta konfigurasi `upload-artifact@v4`. |
| `ab0c9dc` | `docs(week13): add comprehensive documentation on ci cd pipeline, versioning, and secrets security` | Dokumentasi arsitektur CI/CD, SemVer, dan mitigasi keamanan. |
| `2c67e8f` | `docs(week13): complete full practical report, evaluation, and reflection for week 13` | Laporan evaluasi tugas, jawaban refleksi, dan panduan pipeline. |

---

## 6. Panduan Menjalankan & Memverifikasi di GitHub Actions

1. **Memantau Status Build:**
   * Buka repositori di GitHub: [Yahya1805/M.Yahya-Irvansyah-mobile-course](https://github.com/Yahya1805/M.Yahya-Irvansyah-mobile-course).
   * Klik tab **Actions** di panel atas repositori.
   * Pilih workflow run **Flutter CI** yang sedang berjalan pada branch `feat/ci-cd-automation`.
   * Tinjau setiap step: `Verify Code Formatting`, `Run Static Analysis`, `Run Automated Tests`, `Build APK`, dan `Build App Bundle`. Pastikan seluruh step berstatus hijau centang (success).

2. **Mengunduh Artefak Biner:**
   * Setelah job `test-and-build` selesai, gulir ke bagian paling bawah pada halaman detail workflow run (**Artifacts**).
   * Klik artefak **`android-builds`** (format zip) untuk mengunduh paket biner `app-release.apk` dan `app-release.aab`.

3. **Membuat Pull Request (PR):**
   * Buat Pull Request dari branch `feat/ci-cd-automation` ke branch `develop` (atau `main`).
   * GitHub Actions akan secara otomatis menjalankan status checks pada PR untuk memastikan bahwa perubahan memenuhi standar sebelum di-merge.

---

## 7. Refleksi

### 1. Masalah apa yang ditemukan otomatis sebelum perubahan di-merge?
1. **Ketidakrapian Format Kode:** Perintah `dart format` mendeteksi bahwa berkas `lib/main.dart` belum mengikuti konvensi indentasi resmi Dart. CI secara otomatis menggagalkan build jika ada kode yang belum diformat rapi.
2. **Kegagalan Widget Test (Regression):** Test bawaan `Counter increments smoke test` gagal karena UI aplikasi telah berubah menjadi halaman Profil Mahasiswa. Pipeline CI langsung menggagalkan job sebelum kode bermasalah dapat di-merge ke branch `develop` atau `main`.
3. **Peringatan Statis (Linting):** Pemeriksaan `flutter analyze --fatal-infos` mendeteksi ketidaksesuaian opsi analyzer dan memastikan seluruh kode bersih dari warning sebelum masuk ke tahap build.

### 2. Informasi apa yang Anda butuhkan untuk menyelidiki build yang gagal?
1. **Raw Log & Stack Trace:** Log detail pada step yang gagal di tab Actions untuk mengetahui baris kode penyebab error.
2. **Exit Code & Output Linter/Tester:** Output spesifik dari `flutter analyze` (berkas, nomor baris, rule lint) atau `flutter test` (nilai yang diharapkan vs nilai aktual).
3. **Commit Hash & Pull Request Diff:** Perubahan kode spesifik yang memicu kegagalan build (`git diff`).
4. **Environment Runner:** Versi Flutter SDK, Dart SDK, Java/JDK, dan OS runner yang tercatat pada log inisialisasi pipeline.

### 3. Bagian mana yang masih perlu persetujuan atau pemeriksaan manual sebelum rilis?
1. **Exploratory & Usability Testing:** Pengujian pengalaman pengguna (UX) langsung pada perangkat fisik dengan berbagai ukuran layar dan kondisi jaringan nyata.
2. **Verifikasi Fungsionalitas End-to-End:** Pengujian integrasi sensor fisik perangkat (kamera, GPS, biometric) dan integrasi layanan pihak ketiga (push notification FCM, payment gateway).
3. **Release Approval & Store Compliance:** Persetujuan akhir dari Tech Lead/Product Owner, peninjauan *release notes* (changelog), dan kepatuhan terhadap kebijakan privasi Google Play Developer Policy.

---

## 8. Referensi Pendukung
* [Slide Minggu 13: CI/CD dan Otomatisasi](https://jti-polinema.github.io/flutter-codelab/00-slides/Week_13_CICD_Automation.html)
* [GitHub Actions Documentation](https://docs.github.com/actions)
* [Continuous Delivery with Flutter](https://docs.flutter.dev/deployment/cd)
* [Build and Release an Android App](https://docs.flutter.dev/deployment/android)
* [Using Secrets in GitHub Actions](https://docs.github.com/actions/security-guides/using-secrets-in-github-actions)
* [Semantic Versioning 2.0.0](https://semver.org/)
