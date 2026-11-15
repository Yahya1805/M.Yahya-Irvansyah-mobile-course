import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/task_list_page.dart';
import 'package:my_app/task_service.dart';

/// Fake repository yang dapat dikontrol untuk pengujian widget asinkron.
class FakeTaskRepositoryForWidget implements TaskRepository {
  FakeTaskRepositoryForWidget({
    this.tasks = const [],
    this.error,
    this.completer,
  });

  final List<String> tasks;
  final Exception? error;
  final Completer<List<String>>? completer;

  @override
  Future<List<String>> getTasks() async {
    if (completer != null) {
      return completer!.future;
    }
    if (error != null) {
      throw error!;
    }
    return tasks;
  }
}

void main() {
  group('TaskListPage - Widget & Interaction Testing', () {
    // 1. Bangun widget dan periksa judul halaman
    testWidgets('menampilkan judul halaman tugas', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListPage(),
        ),
      );

      // Assert
      expect(find.text('Daftar tugas'), findsOneWidget);
    });

    // 2. Periksa status data kosong (Empty State)
    testWidgets('menampilkan pesan status kosong saat belum ada tugas', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListPage(),
        ),
      );

      // Assert
      expect(find.byKey(const Key('task-empty-state')), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsOneWidget);
      expect(find.byKey(const Key('task-list')), findsNothing);
    });

    // 3. Uji interaksi pengguna: Tambah tugas valid
    testWidgets('menambahkan tugas baru ke dalam daftar saat form diisi dan disimpan', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListPage(),
        ),
      );

      // Act
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Baca materi',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Baca materi'), findsOneWidget);
      expect(find.text('Belum ada tugas'), findsNothing);

      // Verifikasi input field dibersihkan setelah simpan
      final textField = tester.widget<TextField>(find.byKey(const Key('task-title-field')));
      expect(textField.controller?.text, isEmpty);
    });

    // 4. Uji interaksi pengguna: Validasi input tidak valid (kosong atau spasi)
    testWidgets('menampilkan pesan error saat input judul kosong atau hanya spasi', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListPage(),
        ),
      );

      // Act - Submit tanpa teks
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
      expect(find.byKey(const Key('task-list')), findsNothing);

      // Act - Submit dengan hanya spasi
      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        '     ',
      );
      await tester.tap(find.byKey(const Key('save-task-button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
      expect(find.byKey(const Key('task-list')), findsNothing);
    });

    // 5. Uji indikator loading selama proses asinkron berjalan
    testWidgets('menampilkan indikator loading saat repository sedang memuat tugas', (tester) async {
      // Arrange - Gunakan Completer agar pemompaan waktu dapat dikontrol tanpa Future.delayed
      final completer = Completer<List<String>>();
      final fakeRepo = FakeTaskRepositoryForWidget(completer: completer);

      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(repository: fakeRepo),
        ),
      );

      // Act - Pompa satu frame (initState berjalan, future belum selesai)
      await tester.pump();

      // Assert - Indikator loading harus terlihat
      expect(find.byKey(const Key('task-loading-indicator')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Selesaikan future dan pompa hingga animasi selesai
      completer.complete(['Tugas dari cloud']);
      await tester.pumpAndSettle();

      // Loading hilang, daftar tugas muncul
      expect(find.byKey(const Key('task-loading-indicator')), findsNothing);
      expect(find.text('Tugas dari cloud'), findsOneWidget);
    });

    // 6. Uji penanganan error dari repository
    testWidgets('menampilkan pesan error saat repository gagal memuat data', (tester) async {
      // Arrange
      final fakeRepo = FakeTaskRepositoryForWidget(
        error: Exception('Gagal koneksi jaringan'),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListPage(repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('task-error-message')), findsOneWidget);
      expect(find.textContaining('Gagal koneksi jaringan'), findsOneWidget);
      expect(find.byKey(const Key('task-list')), findsNothing);
    });
  });
}

