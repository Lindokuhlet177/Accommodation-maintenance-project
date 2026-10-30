import 'package:flutter/material.dart';

/// Full-screen photos: swipe between them, pinch to zoom.
class PhotoViewerScreen extends StatelessWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photoUrls,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photoUrls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(
              photoUrls[i],
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                  color: Colors.white54, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}