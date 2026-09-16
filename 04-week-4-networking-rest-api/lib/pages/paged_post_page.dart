import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/network_errors.dart';
import '../data/paged_posts.dart';
import '../widgets/post_tile.dart';

class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() =>
      _PagedPostPageState();
}

class _PagedPostPageState
    extends ConsumerState<PagedPostPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;

    final position = _controller.position;

    if (position.pixels >=
        position.maxScrollExtent - 200) {
      ref
          .read(pagedPostsProvider.notifier)
          .loadNextPage();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    if (state.error != null && state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Posts Paged'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                friendlyErrorMessage(state.error!),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref
                    .read(pagedPostsProvider.notifier)
                    .loadFirstPage(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Paged'),
      ),
      body: ListView.builder(
        controller: _controller,
        itemCount: state.items.length +
            (state.isLoadingMore || !state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            if (!state.hasMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Semua data termuat.'),
                ),
              );
            }

            if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return const SizedBox.shrink();
          }

          final post = state.items[index];

          return PostTile(
            post: post,
          );
        },
      ),
    );
  }
}