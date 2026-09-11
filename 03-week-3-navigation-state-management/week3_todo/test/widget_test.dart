import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week3_todo/main.dart';
import 'package:week3_todo/providers/todo_provider.dart';

void main() {
  testWidgets('pengguna dapat menambahkan dan menyelesaikan ToDo',
      (tester) async {
    // ProviderScope baru membuat setiap test memiliki state yang terisolasi.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Belajar Riverpod');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Belajar Riverpod'), findsOneWidget);
    expect(find.text('1 tugas belum selesai'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(find.text('0 tugas belum selesai'), findsOneWidget);
  });

  test('provider filter hanya mengembalikan ToDo yang belum selesai', () {
    // Override notifier dengan state awal agar filter dapat diuji langsung.
    final container = ProviderContainer(
      overrides: [
        todoListProvider.overrideWith(() => SeededTodoNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final incompleteTodos = container.read(incompleteTodoProvider);

    expect(incompleteTodos.map((todo) => todo.title), ['Aktif']);
  });
}

// Notifier khusus test menyediakan satu ToDo aktif dan satu yang sudah selesai.
class SeededTodoNotifier extends TodoListNotifier {
  @override
  List<Todo> build() => [
        Todo('Aktif'),
        Todo('Selesai', done: true),
      ];
}
