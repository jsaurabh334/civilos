import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/document_provider.dart';

class PhotoGallery extends ConsumerStatefulWidget {
  final int initialIndex;

  const PhotoGallery({super.key, this.initialIndex = 0});

  @override
  ConsumerState<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends ConsumerState<PhotoGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getPhotos() {
    final state = ref.watch(documentProvider);
    final allDocs = state.documents;
    return allDocs
        .where((doc) =>
            doc['category'] == 'Photos' ||
            (doc['file_type']?.toString().toLowerCase().contains('png') == true) ||
            (doc['file_type']?.toString().toLowerCase().contains('jpg') == true))
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final photos = _getPhotos();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} of ${photos.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              if (photos.isEmpty) return;
              final photo = photos[_currentIndex];
              ref.read(documentProvider.notifier).deleteDocument(photo['id']);
              if (photos.length == 1) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: photos.isEmpty
          ? const Center(child: Text('No photos', style: TextStyle(color: Colors.white)))
          : PageView.builder(
              controller: _pageController,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final photo = photos[index];
                final fileUrl = photo['file_url'] ?? '';
                final baseUrl = 'http://localhost:8080';
                final fullUrl = '$baseUrl$fileUrl';

                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      fullUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Failed to load', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

void showPhotoGallery(BuildContext context, {int initialIndex = 0}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PhotoGallery(initialIndex: initialIndex),
    ),
  );
}
