import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier ini mengelola proses pengambilan data statistik secara asynchronous.
class StatsNotifier extends AsyncNotifier<List<String>> {
  // Dependensi dibuat dapat diubah agar unit test bisa mengontrol hasil acak.
  StatsNotifier({Random? random, Duration? delay})
      : _random = random ?? Random(),
        _delay = delay ?? const Duration(seconds: 2);

  final Random _random;
  final Duration _delay;

  @override
  Future<List<String>> build() async {
    // Simulasikan waktu tunggu jaringan selama dua detik.
    await Future<void>.delayed(_delay);

    // Tiga puluh persen percobaan sengaja dibuat gagal.
    if (_random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }

    // Data ini mewakili hasil respons API statistik.
    return [
      'Pengguna aktif: 1.248',
      'Pesanan selesai: 842',
      'Pendapatan bulan ini: Rp24.500.000',
    ];
  }
}

// Provider membuat satu sumber state asynchronous untuk halaman statistik.
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);

// ConsumerWidget memungkinkan UI membaca dan merespons perubahan provider.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch membuat widget dibangun ulang saat state berubah.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      // when memastikan tiga keadaan asynchronous ditampilkan dengan jelas.
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Gagal memuat statistik: $err'),
              const SizedBox(height: 12),
              // invalidate memulai ulang proses build notifier.
              ElevatedButton(
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        data: (stats) => ListView.builder(
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: Text(stats[index]),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(
    const ProviderScope(
      child: StatsApp(),
    ),
  );
}

// Widget root aplikasi menyediakan tema dan halaman awal.
class StatsApp extends StatelessWidget {
  const StatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stats',
      home: const StatsPage(),
    );
  }
}