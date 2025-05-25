import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cosmic_explorer/models/gallery.dart';
import 'package:cosmic_explorer/services/gallery_service.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';
import 'package:cosmic_explorer/widgets/gallery_card.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Gallery> _galleries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGalleries();
  }

  Future<void> _loadGalleries() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final galleries = await GalleryService.getAllGalleries();
      
      setState(() {
        _galleries = galleries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewGallery() async {
    final controller = TextEditingController();
    final descriptionController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Gallery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Gallery name *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop({
                  'name': name,
                  'description': descriptionController.text.trim(),
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await GalleryService.createGallery(
          name: result['name']!,
          description: result['description']?.isEmpty == true ? null : result['description'],
        );
        await _loadGalleries();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gallery "${result['name']}" created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create gallery: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteGallery(Gallery gallery) async {
    if (gallery.isRecentlyViewed) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gallery'),
        content: Text('Are you sure you want to delete "${gallery.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GalleryService.deleteGallery(gallery.id);
        await _loadGalleries();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gallery "${gallery.name}" deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete gallery: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editGallery(Gallery gallery) async {
    if (gallery.isRecentlyViewed) return;
    
    final nameController = TextEditingController(text: gallery.name);
    final descriptionController = TextEditingController(text: gallery.description ?? '');
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Gallery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Gallery name *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop({
                  'name': name,
                  'description': descriptionController.text.trim(),
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedGallery = gallery.copyWith(
          name: result['name']!,
          description: result['description']?.isEmpty == true ? null : result['description'],
        );
        await GalleryService.updateGallery(updatedGallery);
        await _loadGalleries();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gallery "${result['name']}" updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update gallery: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToGalleryDetail(Gallery gallery) {
    context.push('/gallery/${gallery.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Galleries'),
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        centerTitle: !isMobile,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.getMaxContentWidth(context),
          ),
          child: _buildBody(),
        ),
      ),
      floatingActionButton: isMobile 
          ? FloatingActionButton(
              onPressed: _createNewGallery,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your galleries...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: ResponsiveUtils.getContentPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load galleries',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadGalleries,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_galleries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadGalleries,
      child: GridView.builder(
        padding: ResponsiveUtils.getScreenPadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(context),
          childAspectRatio: 0.9,
          crossAxisSpacing: ResponsiveUtils.getGridSpacing(context),
          mainAxisSpacing: ResponsiveUtils.getGridSpacing(context),
        ),
        itemCount: _galleries.length,
        itemBuilder: (context, index) {
          final gallery = _galleries[index];
          return GalleryCard(
            gallery: gallery,
            onTap: () => _navigateToGalleryDetail(gallery),
            onEdit: gallery.isRecentlyViewed ? null : () => _editGallery(gallery),
            onDelete: gallery.isRecentlyViewed ? null : () => _deleteGallery(gallery),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getContentPadding(context);
    
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: isMobile ? 80 : 120,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 24 : 32),
            Text(
              'No galleries yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 20 : 24,
                  ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'Create your first gallery to organize your favorite NASA media!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 14 : 16,
                  ),
            ),
            SizedBox(height: isMobile ? 32 : 40),
            ElevatedButton.icon(
              onPressed: _createNewGallery,
              icon: const Icon(Icons.add),
              label: const Text('Create Gallery'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 12 : 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}