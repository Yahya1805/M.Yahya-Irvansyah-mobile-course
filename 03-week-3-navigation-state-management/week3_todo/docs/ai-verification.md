# AI Verification - Week 3 ToDo

## Perubahan yang Dilakukan

- Menambahkan `incompleteTodoProvider` untuk memfilter ToDo yang belum selesai.
- Memastikan update ToDo tetap immutable dengan assignment list baru pada `Notifier`.
- Menambahkan `go_router` dan konfigurasi `StatefulShellRoute.indexedStack`.
- Menambahkan route `/` untuk daftar ToDo dan `/stats` untuk statistik.
- Menambahkan `NavigationBar` untuk berpindah antara daftar ToDo dan statistik.
- Menambahkan `StatsPage` sebagai `ConsumerWidget`.
- Menambahkan `StatsNotifier` dan `statsProvider` berbasis `AsyncNotifier`.
- Menangani state loading, error dengan retry, dan success dengan tiga statistik.
- Mengganti test template counter dengan widget test ToDo dan unit test provider filter.

## Alasan Teknis

### Riverpod

`Notifier` dipakai untuk state daftar ToDo karena state berubah melalui method seperti
`add`, `toggle`, dan `remove`. Setiap perubahan menghasilkan list baru, sehingga
state tidak dimutasi langsung. Provider filter memakai `ref.watch(todoListProvider)`
dan mengembalikan `List.unmodifiable(...)` agar hasil filter tidak dapat diubah
oleh pemakai.

`ConsumerWidget` dipakai pada halaman yang membaca provider. `ref.watch` digunakan
di dalam `build` supaya UI mengikuti perubahan state, sedangkan callback memakai
`ref.read` atau invalidasi ketika melakukan aksi.

### GoRouter

`GoRouter` menyediakan route deklaratif dan mendukung akses langsung ke `/stats`.
`StatefulShellRoute.indexedStack` dipakai agar branch daftar ToDo dan statistik
memiliki navigasi yang jelas melalui `NavigationBar` serta tetap mempertahankan
state branch saat berpindah halaman.

### AsyncValue

`AsyncNotifier` memodelkan request statistik asynchronous tanpa membuat state
loading/error/data secara manual. `AsyncValue.when` memastikan ketiga kondisi
selalu memiliki tampilan: spinner untuk loading, pesan dan tombol retry untuk
error, serta `ListView` untuk data sukses. Request disimulasikan dengan delay dua
detik dan peluang gagal 30%.

## Hasil Verifikasi

Perintah dijalankan dari folder `week3_todo`:

```text
flutter pub get
```

Hasil: dependency berhasil diambil, termasuk `go_router 16.3.0` yang dipilih oleh
constraint `^16.2.0`.

```text
flutter test
```

Hasil: `All tests passed!` dengan 2 test berhasil.

```text
flutter analyze
```

Hasil: `No issues found!`.

Test mencakup penambahan dan penyelesaian ToDo pada UI serta verifikasi bahwa
provider filter hanya mengembalikan ToDo yang belum selesai.
