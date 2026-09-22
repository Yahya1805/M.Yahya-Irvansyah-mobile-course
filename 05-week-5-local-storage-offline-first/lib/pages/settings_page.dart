import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notes_page.dart';
import '../providers/prefs_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final lastOpened = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Praktikum 1: SharedPreferences',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Dark Mode'),
              subtitle: Text(
                darkMode.when(
                  data: (value) => value ? 'Aktif' : 'Tidak aktif',
                  loading: () => 'Memuat...',
                  error: (_, _) => 'Gagal membaca pengaturan',
                ),
              ),
              value: darkMode.value ?? false,
              onChanged: darkMode.isLoading
                  ? null
                  : (value) => ref
                        .read(darkModeProvider.notifier)
                        .setDarkMode(value),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Terakhir dibuka'),
              subtitle: lastOpened.when(
                data: (value) => Text(value ?? 'Belum ada data'),
                loading: () => const Text('Memuat...'),
                error: (_, _) => const Text('Gagal membaca waktu'),
              ),
              leading: const Icon(Icons.schedule),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NotesPage()),
            ),
            icon: const Icon(Icons.note_alt_outlined),
            label: const Text('Buka Catatan Offline'),
          ),
        ],
      ),
    );
  }
}
