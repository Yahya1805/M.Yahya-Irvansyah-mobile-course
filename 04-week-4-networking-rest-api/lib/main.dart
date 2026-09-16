import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'pages/paged_post_page.dart';
import 'pages/post_detail_page.dart';
import 'pages/post_list_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const PostListPage();
          },
        ),
        GoRoute(
          path: '/paged',
          builder: (context, state) {
            return const PagedPostPage();
          },
        ),
        GoRoute(
          path: '/post/:id',
          builder: (context, state) {
            final id = int.parse(
              state.pathParameters['id']!,
            );

            final posts = ref.read(postListProvider).whenOrNull(
                  data: (value) => value,
                ) ??
                [];

            final post = posts.where((item) {
              return item.id == id;
            }).firstOrNull;

            if (post == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Post Detail'),
                ),
                body: const Center(
                  child: Text(
                    'Post tidak ditemukan di list.',
                  ),
                ),
              );
            }

            return PostDetailPage(post: post);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Week 4 - REST API',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}