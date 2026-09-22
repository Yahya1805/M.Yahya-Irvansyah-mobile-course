import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/prefs.dart';
import 'pages/settings_page.dart';
import 'providers/prefs_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefsRepository = PrefsRepository();
  await prefsRepository.markOpenedNow();

  runApp(
    ProviderScope(
      overrides: [
        prefsRepositoryProvider.overrideWithValue(prefsRepository),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final darkMode = ref.watch(darkModeProvider);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: darkMode.when(
            data: (value) => value ? ThemeMode.dark : ThemeMode.light,
            loading: () => ThemeMode.light,
            error: (_, _) => ThemeMode.light,
          ),
          home: const SettingsPage(),
        );
      },
    );
  }
}