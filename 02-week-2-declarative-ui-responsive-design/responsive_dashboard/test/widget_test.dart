import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_dashboard/main.dart';

void main() {
  testWidgets(
    'Dashboard satu kolom di layar sempit',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DashboardApp());

      // Pastikan terdapat 4 kartu informasi
      expect(find.byType(Card), findsNWidgets(4));

      // Pada layar 400px, kartu harus memiliki lebar kurang dari 700px
      final width = tester.getSize(find.byType(Card).first).width;

      expect(width, lessThan(700));
    },
  );

  testWidgets(
    'Dashboard dua kolom di layar lebar',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(tester.view.reset);

      await tester.pumpWidget(const DashboardApp());

      // Pastikan terdapat 4 kartu informasi
      expect(find.byType(Card), findsNWidgets(4));

      // Pada layar 1200px, setiap kartu harus lebih lebar dari 500px
      final width = tester.getSize(find.byType(Card).first).width;

      expect(width, greaterThan(500));
    },
  );
}