import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier ini mensimulasikan request statistik asynchronous.
class StatsNotifier extends AsyncNotifier<List<String>> {
  StatsNotifier({Random? random, Duration? delay})
      : _random = random ?? Random(),
        _delay = delay ?? const Duration(seconds: 2);

  final Random _random;
  final Duration _delay;

  @override
  Future<List<String>> build() async {
    // Delay dua detik mensimulasikan waktu tunggu API.
    await Future<void>.delayed(_delay);

    // Sebagian request gagal agar UI error dan retry dapat diuji.
    if (_random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }

    // Hasil sukses dikembalikan sebagai list baru yang immutable bagi pemakai.
    return [
      'Pengguna aktif: 1.248',
      'Pesanan selesai: 842',
      'Pendapatan bulan ini: Rp24.500.000',
    ];
  }
}

// Provider bertipe eksplisit untuk state asynchronous halaman statistik.
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);
