import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';
import 'task_list_page.dart';

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
  const MyApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: onGenerateRoute,
      home: home ?? const TaskListPage(),
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
