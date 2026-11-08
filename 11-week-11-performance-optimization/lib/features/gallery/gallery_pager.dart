import 'dart:math' as math;

/// Logika pagination galeri yang murni (tanpa widget/network) agar mudah diuji.
class GalleryPager {
  GalleryPager({
    this.pageSize = 20,
    this.maxItems = 60,
    String Function(int index)? urlBuilder,
  }) : _urlBuilder = urlBuilder ?? _picsumUrl;

  final int pageSize;
  final int maxItems;
  final String Function(int index) _urlBuilder;

  final List<String> _items = <String>[];

  List<String> get items => List<String>.unmodifiable(_items);

  bool get hasMore => _items.length < maxItems;

  /// URL untuk indeks tertentu, termasuk halaman yang belum dimuat (precache).
  String urlFor(int index) => _urlBuilder(index);

  /// Menambahkan satu halaman baru dan mengembalikan URL yang ditambahkan.
  List<String> nextPage() {
    if (!hasMore) return const <String>[];

    final start = _items.length;
    final end = math.min(start + pageSize, maxItems);
    final page = <String>[for (var i = start; i < end; i++) _urlBuilder(i)];
    _items.addAll(page);
    return page;
  }

  static String _picsumUrl(int index) {
    // Ukuran asli 800x600; tile hanya menampilkan thumbnail sehingga decode
    // diperkecil lewat memCacheWidth/memCacheHeight di widget.
    return 'https://picsum.photos/seed/mobile-course-$index/800/600';
  }
}
