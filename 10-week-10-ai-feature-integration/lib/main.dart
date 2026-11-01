import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

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
          actions: [
            Builder(
              builder: (context) => IconButton(
                tooltip: 'AI Multimodal (OCR, Vision, STT)',
                icon: const Icon(Icons.document_scanner),
                onPressed: () {
                  Navigator.of(context).pushNamed(aiMultimodalRoute);
                },
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                tooltip: 'AI Chat Assistant',
                icon: const Icon(Icons.auto_awesome),
                onPressed: () {
                  Navigator.of(context).pushNamed(aiChatRoute);
                },
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Catatan',
                icon: const Icon(Icons.note_alt_outlined),
                onPressed: () {
                  Navigator.of(context).pushNamed(notesRoute);
                },
              ),
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
