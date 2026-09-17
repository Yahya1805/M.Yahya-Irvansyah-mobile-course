# Dokumentasi AI Challenge

Dokumen ini mencatat pekerjaan yang benar-benar dilakukan pada project Week 4.

## Prompt AI yang digunakan

1. Membuat repository layer untuk endpoint `GET /comments?postId={id}` dengan Dio dan Riverpod menggunakan `ApiClient` yang sudah ada.
2. Memperbaiki error `onTap` pada `PostTile` dan menyesuaikan `test/post_test.dart` dengan implementasi project yang sebenarnya.
3. Menyelesaikan Mini Project Week 4: alur posts melalui Riverpod dan repository, error state, pagination, testing, README, dan dokumentasi AI tanpa membuat project baru.

## Hasil implementasi

- Dio terpusat di `lib/data/api_client.dart` dengan base URL JSONPlaceholder, timeout 10 detik, dan `LogInterceptor`.
- `PostRepository` mengambil `/posts` dan pagination memakai `_page` serta `_limit`.
- `postListProvider` menangani loading, data, dan error melalui `AsyncNotifier`.
- `PagedPostsNotifier` mempertahankan data lama, menampilkan loading halaman berikutnya, dan memakai guard `isLoadingMore`.
- UI menyediakan loading, error dengan retry, empty, dan success state.
- `Post.fromJson` memberi default aman untuk field null atau missing.
- Test mencakup parsing field missing, error mapping, provider sukses, provider error, dan JSON kosong.

## Bagian yang diperbaiki setelah hasil AI

- `FamilyAsyncNotifier` ternyata tidak tersedia pada Riverpod `3.4.3`; notifier comments disesuaikan menjadi `AsyncNotifier` dengan constructor `postId` dan provider family yang kompatibel.
- `test/post_test.dart` memakai import package yang salah (`week4_api`); import disesuaikan menjadi `my_app` dan helper error diambil dari `network_errors.dart`.
- `main.dart` memakai `valueOrNull` yang tidak tersedia pada Riverpod versi project; pembacaan data diganti dengan `whenOrNull`.
- Smoke test bawaan counter tidak sesuai aplikasi dan tidak menyediakan `ProviderScope`; test diganti menjadi smoke test aplikasi dengan notifier posts palsu agar tidak melakukan request jaringan.
- `PostListPage` diberi callback `onTap` yang menjalankan `context.push('/post/${post.id}')`. Struktur `PostTile` sendiri sudah benar sehingga tidak diubah.

## Keputusan teknis

- Repository menerima `Dio` dari provider agar base URL, timeout, dan interceptor tidak diduplikasi.
- Error dibiarkan dilempar dari repository ke Riverpod agar state `AsyncError` dibuat oleh `AsyncNotifier`, sedangkan `friendlyErrorMessage` memetakan error ke pesan UI.
- Pagination memakai state immutable sederhana. Request berikutnya menyalin item lama dan menolak request baru ketika `isLoadingMore` atau `hasMore` tidak terpenuhi.
- Test provider memakai `FakePostRepository` yang mengikuti signature `PostRepository` aktual, sehingga test memverifikasi dependency injection tanpa HTTP sungguhan.

## Verifikasi

Perintah dijalankan dari folder `04-week-4-networking-rest-api`:

```text
flutter analyze
No issues found!

flutter test
All tests passed.
```