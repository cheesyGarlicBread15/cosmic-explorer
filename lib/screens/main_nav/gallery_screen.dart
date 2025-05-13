import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with AutomaticKeepAliveClientMixin {
  late final List<String> sampleImages;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        sampleImages = List.generate(
          40,
          (index) => 'https://picsum.photos/500/300?random=$index',
        );
        _isLoading = false;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildGalleryGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      key: const PageStorageKey<String>('galleryGrid'),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: sampleImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openImageDetails(context, index),
          child: Card(
            elevation: 3.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                sampleImages[index],
                fit: BoxFit.cover,
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
                    child:
                        Icon(Icons.error_outline, color: Colors.red, size: 30),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _openImageDetails(BuildContext context, int index) {
    if (context.mounted) {
      context.push('/gallery/image/$index');
    }
  }
}
