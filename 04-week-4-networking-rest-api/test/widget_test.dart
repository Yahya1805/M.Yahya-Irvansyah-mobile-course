import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_app/data/models/post.dart';
import 'package:my_app/data/providers.dart';
import 'package:my_app/main.dart';

class EmptyPostListNotifier extends PostListNotifier {
  @override
  Future<List<Post>> build() async => const [];
}

void main() {
  testWidgets('aplikasi menampilkan halaman posts', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postListProvider.overrideWith(
            EmptyPostListNotifier.new,
          ),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Posts API'), findsOneWidget);
  });
}
