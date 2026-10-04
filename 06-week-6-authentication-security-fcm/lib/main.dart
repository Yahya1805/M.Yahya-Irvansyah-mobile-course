import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'messaging/push_service.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const Scaffold(
          body: Center(
            child: Text('Halaman Utama'),
          ),
        );
      },
    ),
    GoRoute(
      path: '/pengumuman/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';

        return AnnouncementPage(id: id);
      },
    ),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  registerBackgroundHandler();

  await requestNotificationPermission();
  await initLocalNotifications(
    onNotificationTap: router.go,
  );

  debugPrint('=== MULAI FCM ===');

  await initFcmToken(
    onToken: (token) async {
      debugPrint('FCM Token BERHASIL');
      debugPrint(token);
    },
  );

  debugPrint('=== SELESAI FCM ===');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    listenForeground(router.go);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(handleTerminated(router.go));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

class AnnouncementPage extends StatelessWidget {
  final String id;

  const AnnouncementPage({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman Kampus'),
      ),
      body: Center(
        child: Text(
          'Pengumuman ID: $id',
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}