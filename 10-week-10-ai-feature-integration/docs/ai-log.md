# AI Integration Log (Week 10)

Dokumen ini mencatat rancangan prompt sistem, prompt pengguna, konteks arsitektur, output awal AI, serta catatan verifikasi untuk fitur **AI Chat Assistant & Multimodal Integration** pada mata kuliah Pemrograman Mobile.

---

## 1. System Prompt (Prompt Sistem)

Prompt sistem yang ditanamkan untuk menetapkan persona, batasan privasi, gaya bahasa, dan batasan panjang output:

```text
Kamu adalah asisten cerdas ramah untuk aplikasi mobile mahasiswa kampus.
Karakteristik & Batasan:
1. Jawab selalu dalam Bahasa Indonesia yang sopan, ringkas, dan jelas.
2. Batasi panjang jawaban maksimal 2-3 kalimat agar nyaman dibaca pada layar perangkat mobile.
3. Fokus pada produktivitas mahasiswa: jadwal perkuliahan, pembuatan catatan, dan tips belajar.
4. Jangan pernah meminta, merekam, atau menyebarkan data pribadi sensitif seperti NIK, nomor telepon, atau kata sandi.
5. Jika ada pertanyaan di luar topik kampus, arahkan pengguna kembali dengan sopan.
```

---

## 2. User Prompt & Konteks Mobile (Prompt Pengguna)

Contoh prompt pengujian interaktif oleh pengguna:

```text
User Prompt:
"Bagaimana tips membuat ringkasan catatan kuliah yang efektif dengan Clean Architecture?"

Konteks yang Disuntikkan:
- Model AI: Google Gemini 1.5 Flash (Latency rendah, multimodal)
- Endpoint: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent
- Streaming Response: Simulasi chunk-by-chunk token stream (30ms per token)
- Data Sensitif: Disaring otomatis via sanitizePrompt() Regex masker
```

---

## 3. Output Awal AI (Raw AI Response)

Respons mentah yang dikembalikan oleh model Gemini API:

```text
Untuk membuat ringkasan yang efektif dengan Clean Architecture, pisahkan catatan Anda ke dalam tiga lapisan: Domain untuk poin-poin inti logika bisnis, Data untuk sumber referensi materi, dan Presentation untuk visualisasi catatan Anda. Pendekatan ini membuat catatan belajar Anda lebih terstruktur, mudah diulas kembali, dan tidak tercampur aduk.
```

---

## 4. Prompt Multimodal Studio (OCR & Vision)

### A. Prompt OCR (Optical Character Recognition)
* **Prompt**:
  ```text
  Tolong lakukan OCR. Ekstrak seluruh teks yang tertulis pada gambar ini secara akurat. Tuliskan kembali teks tersebut tanpa tambahan opini atau komentar.
  ```
* **Payload**: Gambar KTM / Dokumen dikonversi menjadi `image/jpeg` base64.
* **Output**:
  ```text
  KARTU TANDA MAHASISWA
  NAMA: M. YAHYA IRVANSYAH
  NIM: 2241720000
  PROGRAM STUDI: D4 TEKNIK INFORMATIKA
  ```

### B. Prompt Image Understanding (Vision)
* **Prompt**:
  ```text
  Jelaskan isi gambar ini secara ringkas dalam Bahasa Indonesia.
  ```
* **Output**:
  ```text
  Gambar menampilkan sebuah kartu identitas mahasiswa dan buku catatan pemrograman mobile di atas meja belajar.
  ```

---

## 5. Catatan Verifikasi & Mitigasi Risiko

1. **Privasi Data**: Input user yang memuat nomor telepon atau NIK berhasil disaring sebelum payload dikirim ke API (`[NIK_DIRAHASIAKAN]`).
2. **Optimasi Biaya**: Request dengan query identik langsung disajikan dari cache lokal in-memory, menghemat pemakaian token Gemini API.
3. **Offline Fallback**: Saat koneksi dimatikan atau API mengembalikan status error, antarmuka chat beralih ke fallback jawaban lokal tanpa crash.

