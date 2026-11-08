import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Batasi cache gambar di memori. Tanpa batas, membuka banyak gambar
  // beresolusi tinggi dapat menghabiskan memori perangkat.
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 80 << 20; // 80 MB
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: onGenerateRoute,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Profil Mahasiswa'),
          // Daftar aksi const: tidak dibangun ulang setiap MyApp rebuild,
          // dan tidak ada lagi Builder + closure di build method induk.
          actions: const [
            _ProfileActionButton(
              tooltip: 'AI Multimodal (OCR, Vision, STT)',
              icon: Icons.document_scanner,
              route: aiMultimodalRoute,
            ),
            _ProfileActionButton(
              tooltip: 'AI Chat Assistant',
              icon: Icons.auto_awesome,
              route: aiChatRoute,
            ),
            _ProfileActionButton(
              tooltip: 'Galeri Gambar',
              icon: Icons.photo_library_outlined,
              route: galleryRoute,
            ),
            _ProfileActionButton(
              tooltip: 'Catatan',
              icon: Icons.note_alt_outlined,
              route: notesRoute,
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, size: 72),
              SizedBox(height: 16),
              Text('M.Yahya Irvansyah', style: TextStyle(fontSize: 24)),
              Text('Pemrograman Mobile — Minggu 1'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol navigasi profil yang bisa dibuat `const`.
///
/// Sebelumnya setiap tombol dibungkus `Builder` dengan closure baru di dalam
/// build method [MyApp]. Dengan widget terpisah, tombol hanya dibangun sekali.
class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.tooltip,
    required this.icon,
    required this.route,
  });

  final String tooltip;
  final IconData icon;
  final String route;

  void _open(BuildContext context) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: () => _open(context),
    );
  }
}
