// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('profile keeps the Notes entry point', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('Profil Mahasiswa'), findsOneWidget);
    expect(find.text('M.Yahya Irvansyah'), findsOneWidget);
    expect(find.byTooltip('Catatan'), findsOneWidget);
  });

  testWidgets('Notes button opens the Notes page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.tap(find.byTooltip('Catatan'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan'), findsOneWidget);
    expect(find.byTooltip('Tambah catatan'), findsOneWidget);
  });
}
