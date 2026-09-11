import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

// ConsumerWidget membaca AsyncValue dan membangun UI sesuai state provider.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: statsAsync.when(
        // State loading ditampilkan saat request masih berlangsung.
        loading: () => const Center(child: CircularProgressIndicator()),
        // State error menampilkan pesan dan memulai ulang provider saat retry.
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Gagal memuat statistik: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(statsProvider),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
        // State data menampilkan minimal tiga item statistik.
        data: (stats) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: stats.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: Text(stats[index]),
          ),
        ),
      ),
    );
  }
}
