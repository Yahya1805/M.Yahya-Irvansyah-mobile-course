import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/gallery/gallery_pager.dart';

void main() {
  group('GalleryPager', () {
    test('memuat halaman 20 item sampai batas maksimal', () {
      final pager = GalleryPager();

      expect(pager.items, isEmpty);
      expect(pager.hasMore, isTrue);

      expect(pager.nextPage(), hasLength(20));
      expect(pager.nextPage(), hasLength(20));
      expect(pager.nextPage(), hasLength(20));

      expect(pager.items, hasLength(60));
      expect(pager.hasMore, isFalse);
      expect(pager.nextPage(), isEmpty);
    });

    test('halaman terakhir mengikuti sisa item', () {
      final pager = GalleryPager(pageSize: 5, maxItems: 8);

      expect(pager.nextPage(), hasLength(5));
      expect(pager.nextPage(), hasLength(3));
      expect(pager.hasMore, isFalse);
      expect(pager.items.toSet(), hasLength(8));
    });

    test('URL unik dan memakai ukuran asli 800x600', () {
      final pager = GalleryPager(pageSize: 4, maxItems: 4);
      final urls = pager.nextPage();

      expect(urls.toSet(), hasLength(4));
      expect(urls.first, contains('800/600'));
      expect(pager.urlFor(10), contains('mobile-course-10'));
    });
  });
}
