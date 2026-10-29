import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('Aplikasi menampilkan Halaman Utama', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halaman Utama'), findsOneWidget);
  });

  testWidgets('AnnouncementPage menampilkan ID pengumuman dengan benar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnnouncementPage(id: '123'),
      ),
    );

    expect(find.text('Pengumuman Kampus'), findsOneWidget);
    expect(find.text('Pengumuman ID: 123'), findsOneWidget);
  });
}
