import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/gallery/gallery_screen.dart';

void main() {
  testWidgets('galeri memakai GridView.builder dan lazy image tile', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GalleryScreen()));
    await tester.pump();

    expect(find.text('Galeri'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    // Gambar jaringan tidak benar-benar diunduh di test; yang diverifikasi
    // adalah struktur lazy grid dan pemakaian CachedNetworkImage.
    expect(find.byType(CachedNetworkImage), findsWidgets);
  });
}
