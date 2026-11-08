import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'gallery_pager.dart';

/// Galeri demo untuk optimasi gambar tampilan:
///
/// * `GridView.builder` hanya membangun tile yang terlihat;
/// * `CachedNetworkImage` menyimpan gambar di disk agar tidak diunduh ulang;
/// * `memCacheWidth`/`memCacheHeight` men-decode gambar sesuai ukuran tampil,
///   bukan resolusi penuh;
/// * placeholder + fade-in menghindari layar kosong saat gambar dimuat;
/// * `precacheImage` memuat thumbnail halaman berikutnya lebih awal.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const int _precacheCount = 4;

  final ScrollController _scrollController = ScrollController();
  final GalleryPager _pager = GalleryPager();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_pager.hasMore) return;
    setState(() => _isLoading = true);

    final newUrls = _pager.nextPage();
    final nextStart = _pager.items.length;

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (newUrls.isEmpty) return;

    // Precache dilakukan setelah frame agar context sudah terpasang.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheNextPage(nextStart);
    });
  }

  /// Memuat thumbnail beberapa gambar halaman berikutnya sebelum di-scroll.
  Future<void> _precacheNextPage(int start) async {
    final end = math.min(start + _precacheCount, _pager.maxItems);
    for (var i = start; i < end; i++) {
      if (!mounted) return;
      await precacheImage(
        CachedNetworkImageProvider(
          _pager.urlFor(i),
          maxWidth: 300,
          maxHeight: 225,
        ),
        context,
        onError: (_, _) {
          // Precache bersifat best-effort; error ditampilkan oleh tile saat
          // gambar benar-benar dibutuhkan.
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _pager.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Galeri')),
      body: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 4 / 3,
        ),
        itemCount: items.length + (_pager.hasMore ? 1 : 0),
        addAutomaticKeepAlives: false,
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const _GalleryLoadingTile();
          }
          return _GalleryTile(url: items[index]);
        },
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          // Decode dan simpan di disk pada ukuran thumbnail, bukan 800x600.
          memCacheWidth: 300,
          memCacheHeight: 225,
          maxWidthDiskCache: 600,
          maxHeightDiskCache: 450,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: _buildPlaceholder,
          errorWidget: _buildError,
        ),
      ),
    );
  }

  /// Tear-off statis agar builder placeholder tidak dibuat ulang tiap build.
  static Widget _buildPlaceholder(BuildContext context, String url) {
    return const ColoredBox(
      color: Color(0xFFE6E6E6),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  static Widget _buildError(BuildContext context, String url, Object error) {
    return const ColoredBox(
      color: Color(0xFFF2F2F2),
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }
}

class _GalleryLoadingTile extends StatelessWidget {
  const _GalleryLoadingTile();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEDEDED),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
