import 'package:flutter/material.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/models/gallery.dart';
import 'package:cosmic_explorer/services/gallery_service.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';

class MediaCard extends StatelessWidget {
  final NasaMediaItem mediaItem;
  final VoidCallback onTap;
  final bool showAddToGallery;

  const MediaCard({
    super.key,
    required this.mediaItem,
    required this.onTap,
    this.showAddToGallery = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Card(
      elevation: isMobile ? 4 : 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: showAddToGallery ? () => _showAddToGalleryOptions(context) : null,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildMediaPreview(context)
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            mediaItem.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Text(
                          mediaItem.formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: isMobile ? 11 : 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Add to gallery button
            if (showAddToGallery)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    onPressed: () => _showAddToGalleryOptions(context),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.deepPurple.withOpacity(0.3),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (mediaItem.thumbnailUrl != null)
            Hero(
              tag: 'media_${mediaItem.nasaId}',
              child: Image.network(
                mediaItem.thumbnailUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingPlaceholder(context);
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPlaceholder(context);
                },
              ),
            )
          else
            _buildDefaultPlaceholder(context),
          
          // Media type overlay
          Positioned(
            top: 8,
            right: 8,
            child: _buildMediaTypeChip(context)
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeChip(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    Color chipColor;
    switch (mediaItem.mediaType.toLowerCase()) {
      case 'image':
        chipColor = Colors.blue;
        break;
      case 'video':
        chipColor = Colors.red;
        break;
      case 'audio':
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10, 
        vertical: isMobile ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        mediaItem.mediaType.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: isMobile ? 10 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: isMobile ? 40 : 48,
            color: Colors.grey[600],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isMobile ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    IconData iconData;
    switch (mediaItem.mediaType.toLowerCase()) {
      case 'video':
        iconData = Icons.play_circle_filled;
        break;
      case 'audio':
        iconData = Icons.audiotrack;
        break;
      default:
        iconData = Icons.image;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: isMobile ? 40 : 48,
            color: Colors.grey[600],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            mediaItem.mediaType.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToGalleryOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddToGalleryBottomSheet(mediaItem: mediaItem),
    );
  }
}

class AddToGalleryBottomSheet extends StatefulWidget {
  final NasaMediaItem mediaItem;

  const AddToGalleryBottomSheet({
    super.key,
    required this.mediaItem,
  });

  @override
  State<AddToGalleryBottomSheet> createState() => _AddToGalleryBottomSheetState();
}

class _AddToGalleryBottomSheetState extends State<AddToGalleryBottomSheet> {
  List<Gallery> _galleries = [];
  bool _isLoading = true;
  final TextEditingController _newGalleryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGalleries();
  }

  @override
  void dispose() {
    _newGalleryController.dispose();
    super.dispose();
  }

  Future<void> _loadGalleries() async {
    try {
      final galleries = await GalleryService.getAllGalleries();
      setState(() {
        _galleries = galleries.where((g) => !g.isRecentlyViewed).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToGallery(Gallery gallery) async {
    try {
      await GalleryService.addMediaToGallery(gallery.id, widget.mediaItem.nasaId);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to "${gallery.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to gallery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createNewGallery() async {
    final name = _newGalleryController.text.trim();
    if (name.isEmpty) return;

    try {
      final gallery = await GalleryService.createGallery(name: name);
      await GalleryService.addMediaToGallery(gallery.id, widget.mediaItem.nasaId);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created gallery "${gallery.name}" and added media'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            'Add to Gallery',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.mediaItem.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          
          // Create new gallery section
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newGalleryController,
                  decoration: const InputDecoration(
                    labelText: 'New gallery name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _createNewGallery,
                child: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Existing galleries
          Text(
            'Add to existing gallery:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          
          // Galleries list
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _galleries.isEmpty
                    ? Center(
                        child: Text(
                          'No galleries yet.\nCreate your first gallery above!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _galleries.length,
                        itemBuilder: (context, index) {
                          final gallery = _galleries[index];
                          final isAlreadyAdded = gallery.mediaIds.contains(widget.mediaItem.nasaId);
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.withOpacity(0.1),
                              child: Text(
                                gallery.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(gallery.name),
                            subtitle: Text('${gallery.mediaCount} items • ${gallery.formattedDate}'),
                            trailing: isAlreadyAdded
                                ? const Icon(Icons.check, color: Colors.green)
                                : const Icon(Icons.add),
                            onTap: isAlreadyAdded ? null : () => _addToGallery(gallery),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}