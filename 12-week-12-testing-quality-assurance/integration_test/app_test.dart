import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pengujian Integrasi dan Pencegahan Regresi (E2E)', () {
    // 1. Alur Pengguna: Menambahkan tugas baru dari awal hingga akhir
    testWidgets('pengguna dapat menambahkan tugas', (tester) async {
      // Jalankan aplikasi secara penuh
      app.main();
      await tester.pumpAndSettle();

      // Cari input field dan masukkan judul tugas
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Baca materi',
      );

      // Tekan tombol simpan
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Verifikasi item telah muncul pada layar
      expect(find.text('Baca materi'), findsOneWidget);
    });

    // 2. Pencegahan Regresi: Mencegah judul spasi kosong masuk ke daftar tugas
    testWidgets('regresi: input judul spasi tidak boleh masuk ke daftar tugas', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Masukkan teks yang hanya terdiri dari whitespace
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        '     ',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Verifikasi pesan validasi muncul dan list tidak bertambah
      expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
      expect(find.text('     '), findsNothing);
    });

    // 3. Pencegahan Regresi: Menambahkan beberapa tugas berurutan tanpa me-reset state sebelumnya
    testWidgets('regresi: beberapa tugas berurutan tersimpan lengkap tanpa overwrite', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      const task1 = 'Pelajari Unit Testing';
      const task2 = 'Pelajari Widget Testing';
      const task3 = 'Pelajari Integration Testing';

      for (final task in [task1, task2, task3]) {
        await tester.enterText(
          find.byKey(const Key('task-title-field')),
          task,
        );
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();
      }

      // Verifikasi ketiga tugas ada di tampilan
      expect(find.text(task1), findsOneWidget);
      expect(find.text(task2), findsOneWidget);
      expect(find.text(task3), findsOneWidget);
    });
  });
}

