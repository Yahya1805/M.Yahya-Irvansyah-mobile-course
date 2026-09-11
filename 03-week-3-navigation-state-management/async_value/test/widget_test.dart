import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:async_value/main.dart';

// Random palsu ini selalu menghasilkan nilai yang menyebabkan sukses.
class AlwaysSuccessRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.5;

  @override
  int nextInt(int max) => 0;
}

// Random palsu ini selalu menghasilkan nilai yang menyebabkan error.
class AlwaysFailureRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.1;

  @override
  int nextInt(int max) => 0;
}

void main() {
  test('notifier mengembalikan tiga statistik saat berhasil', () async {
    // Delay nol membuat unit test cepat tanpa mengubah delay produksi.
    final notifier = StatsNotifier(
      random: AlwaysSuccessRandom(),
      delay: Duration.zero,
    );

    final result = await notifier.build();

    expect(result, hasLength(3));
    expect(result.first, contains('Pengguna aktif'));
  });

  test('notifier melempar error saat pengambilan data gagal', () async {
    // Nilai acak 0.1 berada di bawah ambang kegagalan 0.3.
    final notifier = StatsNotifier(
      random: AlwaysFailureRandom(),
      delay: Duration.zero,
    );

    expect(notifier.build, throwsA(isA<Exception>()));
  });
}
