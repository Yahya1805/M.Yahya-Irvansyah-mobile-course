import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/posts_result.dart';
import '../../domain/failures/posts_failure.dart';
import '../providers/posts_providers.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postingan'),
        actions: [
          IconButton(
            key: const Key('postsRefreshButton'),
            tooltip: 'Segarkan postingan',
            onPressed: () => ref.read(postsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PostsError(
          message: error is PostsFailure
              ? error.message
              : 'Postingan tidak dapat dimuat. Silakan coba lagi.',
          onRetry: () => ref.invalidate(postsProvider),
        ),
        data: (data) => _PostsBody(state: data),
      ),
    );
  }
}

class _PostsBody extends StatelessWidget {
  const _PostsBody({required this.state});

  final PostsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PolicySelector(policy: state.policy),
        if (state.isRefreshing) const LinearProgressIndicator(minHeight: 2),
        _StatusBar(state: state),
        if (state.message != null) _MessageBanner(message: state.message!),
        Expanded(
          child: state.posts.isEmpty
              ? const _EmptyPosts()
              : ListView.builder(
                  itemCount: state.posts.length,
                  addAutomaticKeepAlives: false,
                  itemBuilder: (context, index) {
                    final post = state.posts[index];
                    return _PostTile(key: ValueKey(post.id), post: post);
                  },
                ),
        ),
      ],
    );
  }
}

class _PolicySelector extends ConsumerWidget {
  const _PolicySelector({required this.policy});

  final CachePolicy policy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Strategi cache',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CachePolicy>(
                key: const Key('postsPolicySelector'),
                value: policy,
                isExpanded: true,
                isDense: true,
                items: CachePolicy.values
                    .map(
                      (item) => DropdownMenuItem<CachePolicy>(
                        value: item,
                        child: Text(_policyLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (next) {
                  if (next != null && next != policy) {
                    ref.read(postsProvider.notifier).setPolicy(next);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _policyDescription(policy),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});

  final PostsState state;

  @override
  Widget build(BuildContext context) {
    final info = _sourceInfo(state.source);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            avatar: Icon(info.icon, size: 16, color: info.color),
            label: Text(info.label),
            visualDensity: VisualDensity.compact,
          ),
          if (state.notModified)
            const Chip(
              label: Text('304 · tidak berubah'),
              visualDensity: VisualDensity.compact,
            ),
          Text(
            'Sinkron terakhir: ${_formatTimestamp(state.lastSyncedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Belum ada postingan.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(post.id.toString())),
      title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      isThreeLine: true,
    );
  }
}

class _PostsError extends StatelessWidget {
  const _PostsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _policyLabel(CachePolicy policy) {
  return switch (policy) {
    CachePolicy.cacheFirst => 'Cache first',
    CachePolicy.networkFirst => 'Network first',
    CachePolicy.staleWhileRevalidate => 'Stale while revalidate',
    CachePolicy.cacheOnly => 'Cache only',
  };
}

String _policyDescription(CachePolicy policy) {
  return switch (policy) {
    CachePolicy.cacheFirst =>
      'Pakai cache bila ada; API hanya dipanggil saat cache kosong.',
    CachePolicy.networkFirst =>
      'Utamakan API; cache dipakai sebagai fallback saat jaringan gagal.',
    CachePolicy.staleWhileRevalidate =>
      'Tampilkan cache dulu, lalu perbarui dari API di latar belakang.',
    CachePolicy.cacheOnly =>
      'Hanya membaca cache lokal, tanpa request jaringan.',
  };
}

({String label, IconData icon, Color color}) _sourceInfo(PostsSource source) {
  return switch (source) {
    PostsSource.network => (
      label: 'Dari jaringan',
      icon: Icons.cloud_done_outlined,
      color: Colors.green,
    ),
    PostsSource.cache => (
      label: 'Dari cache',
      icon: Icons.storage_outlined,
      color: Colors.blue,
    ),
    PostsSource.fallback => (
      label: 'Fallback cache',
      icon: Icons.cloud_off_outlined,
      color: Colors.orange,
    ),
  };
}

String _formatTimestamp(DateTime? value) {
  if (value == null) return 'belum pernah';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatDate(local)} $hour:$minute';
}
