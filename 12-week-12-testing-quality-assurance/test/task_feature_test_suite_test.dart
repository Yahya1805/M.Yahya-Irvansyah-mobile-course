import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/is_valid_task_title.dart';
import 'package:my_app/task_list_page.dart';
import 'package:my_app/task_service.dart';

/// Fake repository yang perilakunya dikendalikan pengujian (test double).
class FakeTaskRepositoryForSuite implements TaskRepository {
  FakeTaskRepositoryForSuite({List<String>? initialTasks, this.error})
      : _tasks = List<String>.from(initialTasks ?? const []);

  final List<String> _tasks;
  final Exception? error;

  @override
  Future<List<String>> getTasks() async {
    if (error != null) throw error!;
    return List<String>.unmodifiable(_tasks);
  }

  @override
  Future<void> addTask(String task) async {
    if (error != null) throw error!;
    _tasks.add(task);
  }
}

void main() {
  group('Praktikum: Test Suite Lengkap Fitur Daftar Tugas', () {
    // =========================================================================
    // 1. UJI LOGIKA BISNIS (UNIT TESTING)
    // =========================================================================
    group('1. Uji Logika & Validasi Bisnis', () {
      // Skenario 1 (Kasus Utama/Sukses)
      test('skenario sukses: menerima judul alfanumerik yang valid', () {
        // Arrange
        const title = 'Selesaikan Codelab Testing Week 12';

        // Act
        final isValid = isValidTaskTitle(title);

        // Assert
        expect(isValid, isTrue);
      });

      // Skenario 2 (Kasus Tepi / Edge Case)
      test('skenario kasus tepi: menerima judul dengan spasi berlebih dan emoji', () {
        // Arrange
        const titleWithEmoji = '   🚀 Praktikum Mobile QA   ';

        // Act
        final isValid = isValidTaskTitle(titleWithEmoji);

        // Assert
        expect(isValid, isTrue);
      });

      // Skenario 3 (Kasus Kegagalan / Failure Case)
      test('skenario kegagalan: menolak judul kosong atau hanya berisi whitespace campuran', () {
        // Arrange
        const emptyTitle = '';
        const whitespaceMixed = '  \t  \n  \r  ';

        // Act & Assert
        expect(isValidTaskTitle(emptyTitle), isFalse);
        expect(isValidTaskTitle(whitespaceMixed), isFalse);
      });
    });

    // =========================================================================
    // 2. UJI DEPENDENSI & KODE ASINKRON (FAKE REPOSITORY)
    // =========================================================================
    group('2. Uji Dependensi via Fake Repository', () {
      test('meneruskan dan menyimpan data melalui repository tanpa jaringan asli', () async {
        // Arrange
        final fakeRepo = FakeTaskRepositoryForSuite(initialTasks: ['Belajar Unit Test']);
        final service = TaskService(fakeRepo);

        // Act
        await service.saveTask('Belajar Widget Test');
        final currentTasks = await service.loadTasks();

        // Assert
        expect(currentTasks.length, equals(2));
        expect(currentTasks, equals(['Belajar Unit Test', 'Belajar Widget Test']));
      });

      test('melemparkan exception dan tidak menelan error ketika repository gagal', () async {
        // Arrange
        final fakeRepo = FakeTaskRepositoryForSuite(
          error: Exception('Simulasi kegagalan server 500'),
        );
        final service = TaskService(fakeRepo);

        // Act & Assert
        expect(
          () => service.loadTasks(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Simulasi kegagalan server 500'),
          )),
        );
      });
    });

    // =========================================================================
    // 3. UJI TAMPILAN DAN INTERAKSI ANTARMUKA (WIDGET TESTING)
    // =========================================================================
    group('3. Uji Antarmuka & Interaksi Widget', () {
      testWidgets('tampilan awal menampilkan form kosong dan pesan belum ada tugas', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: TaskListPage(),
          ),
        );

        // Assert
        expect(find.text('Daftar tugas'), findsOneWidget);
        expect(find.byKey(const Key('task-title-field')), findsOneWidget);
        expect(find.byKey(const Key('save-task-button')), findsOneWidget);
        expect(find.text('Belum ada tugas'), findsOneWidget);
        expect(find.byKey(const Key('task-list')), findsNothing);
      });

      testWidgets('menolak input tidak valid dan menampilkan pesan kesalahan', (tester) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(
            home: TaskListPage(),
          ),
        );

        // Act - Submit kosong
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
        expect(find.byKey(const Key('task-list')), findsNothing);
      });

      testWidgets('tindakan pengguna berhasil menambahkan tugas baru ke tampilan', (tester) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(
            home: TaskListPage(),
          ),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('task-title-field')),
          'Deploy ke Play Store',
        );
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Deploy ke Play Store'), findsOneWidget);
        expect(find.text('Belum ada tugas'), findsNothing);

        // Input field harus bersih setelah simpan
        final textField = tester.widget<TextField>(find.byKey(const Key('task-title-field')));
        expect(textField.controller?.text, isEmpty);
      });
    });

    // =========================================================================
    // 4. UJI ALUR UTAMA TERINTEGRASI (COMPONENT INTEGRATION FLOW)
    // =========================================================================
    group('4. Uji Alur Utama Terintegrasi (UI + Validasi + Repository)', () {
      testWidgets('alur lengkap: input UI terhubung langsung ke Fake Repository dan memperbarui daftar', (tester) async {
        // Arrange
        final fakeRepo = FakeTaskRepositoryForSuite(initialTasks: ['Tugas Awal']);

        await tester.pumpWidget(
          MaterialApp(
            home: TaskListPage(repository: fakeRepo),
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi tugas awal dari repository telah dimuat
        expect(find.text('Tugas Awal'), findsOneWidget);

        // Act - Tambahkan tugas baru
        await tester.enterText(
          find.byKey(const Key('task-title-field')),
          'Tugas Baru dari UI',
        );
        await tester.tap(find.byKey(const Key('save-task-button')));
        await tester.pumpAndSettle();

        // Assert - Verifikasi di UI
        expect(find.text('Tugas Baru dari UI'), findsOneWidget);

        // Assert - Verifikasi persistensi di fake repository
        final repoTasks = await fakeRepo.getTasks();
        expect(repoTasks, contains('Tugas Baru dari UI'));
        expect(repoTasks.length, equals(2));
      });
    });
  });
}
