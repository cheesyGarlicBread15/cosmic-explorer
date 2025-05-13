import 'package:flutter/material.dart';

class ImageDetailsScreen extends StatelessWidget {
  final String imageId;

  const ImageDetailsScreen({super.key, required this.imageId});

  @override
  Widget build(BuildContext context) {
    // Parse the ID safely
    final int index = int.tryParse(imageId) ?? 0;
    final String imageUrl = 'https://picsum.photos/800/600?random=$index';

    return Scaffold(
      appBar: AppBar(
        title: Text('Image ${index + 1}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 60),
                            SizedBox(height: 16),
                            Text('Failed to load image'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
