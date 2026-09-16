- Uji tiga skenario error
-----------------------

1. Jalankan aplikasi dengan internet normal, amati loading lalu daftar 100 posts.
---------------------------------------------------------------------------------
![alt text](image.png)

2. Matikan internet (mode pesawat), tekan refresh, amati pesan ramah + tombol Coba lagi. Nyalakan kembali internet, tekan Coba lagi.
------------------------------------------------------------------------------------------------------------------------------------
![alt text](image-1.png)
ketika tombol coba lagi di pencet itu akan tetap sama dan tidak ada perubahan sama sekali

![alt text](image-2.png)
Setelah internet saya nyalahkan kembali itu baru bisa kembali ke mode awal

3. Sementara ubah baseUrl menjadi URL salah, amati pesan error koneksi. Kembalikan setelah uji.
-----------------------------------------------------------------------------------------------
![alt text](image-3.png)
![alt text](image-4.png)
Ketika memang dirubah baseurlnya menjadi url yang salah maka aplikasinya akan eror juga
---------------------------------------------------------------------------------------

- Ubah home di main.dart menjadi PagedPostPage, jalankan, dan scroll sampai bawah. Amati: halaman 1 tampil dulu, indikator muncul, data bertambah tanpa reload penuh.
---------------------------------------------------------------------------------------------------------------------------------------

![alt text](image-5.png)
Ubah home di main.dart menjadi PagedPostPage, jalankan, dan scroll sampai bawah. Amati: halaman 1 tampil dulu, indikator muncul, data bertambah tanpa reload penuh, dan juga disitu akan loading ketika layar tidak memenuhi syarat yang sudah ditentukan sebesar 200 pixel.

![alt text](image-6.png)

nah ini kalau memang udah menyesuaikan syarat yang sudah ada dan akan muncul page selanjutnya ketika di scroll
--------------------------------------------------------------------------------------------------------------

AI Verification Checklist
Sebelum kode AI diterima, verifikasi hal berikut dan catat temuan Anda di README:

1. Apakah UI memanggil Dio secara langsung (dilarang) atau lewat repository?

UI tidak memanggil Dio secara langsung. Pengambilan data dilakukan melalui CommentRepository dan provider Riverpod sehingga terdapat pemisahan antara UI dan akses API.

2. Apakah fromJson aman null, atau masih memakai cast langsung yang bisa crash?

fromJson dibuat aman terhadap field yang hilang atau bernilai null dengan menggunakan nullable cast dan nilai default, sehingga proses parsing tidak langsung menyebabkan crash.

3. Apakah semua tipe DioExceptionType (timeout, connectionError, badResponse) dipetakan ke pesan pengguna?

Error Dio dipetakan menjadi pesan yang lebih ramah pengguna, termasuk timeout, connection error, 404, dan 500.

4. Apakah baseUrl/timeout terpusat di satu client, bukan tersebar di tiap method?

baseUrl dan konfigurasi timeout dipusatkan pada ApiClient sehingga repository hanya menggunakan client yang sudah dikonfigurasi dan tidak membuat konfigurasi Dio secara berulang.

5. Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path? Tambahkan minimal 1 edge case sendiri.

Test tidak hanya menguji happy path, tetapi juga menguji field yang hilang. Sebagai edge case tambahan, dilakukan pengujian terhadap JSON kosong untuk memastikan fromJson tetap aman.

6. Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?
flutter analyze berhasil tanpa error/warning dan flutter test berhasil dengan seluruh test lulus.
------------------------------------------------------------------------------------------------

![alt text](image-7.png)
Hasil ketika aman dan tidak eror 100 post

![alt text](image-8.png)
Hasil ketika tidak ada internet dan eror 