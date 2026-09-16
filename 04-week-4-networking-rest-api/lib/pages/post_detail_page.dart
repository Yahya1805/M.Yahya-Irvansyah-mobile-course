import 'package:flutter/material.dart';
import '../data/models/post.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post ${post.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              post.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              post.body,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}