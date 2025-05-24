// lib/screens/gallery_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cosmic_explorer/models/gallery.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/services/gallery_service.dart';
import 'package:cosmic_explorer/services/nasa_service.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';
import 'package:cosmic_explorer/widgets/media_card.dart';

class GalleryDetailScreen extends StatefulWidget {
  final String galleryId;

  const GalleryDetailScreen({
    super.key,
    required this.galleryId,
  });

  @override
  State<GalleryDetailScreen> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends State<GalleryDetailScreen> {
  Gallery? _gallery;
  List<NasaMediaItem> _mediaItems = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedFilter;
  final List<String> _filterTypes = ['All', 'Image', 'Video', 'Audio'];

  @override
  void initState() {
    super.initState();
    _loadGalleryDetails();
  }

  Future<void> _loadGalleryDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final gallery = await GalleryService.getGallery(widget.galleryId);
      if (gallery == null) {
        setState(() {
          _error = 'Gallery not found';
          _isLoading = false;
        });
        return;
      }

      List<NasaMediaItem> mediaItems = [];
      
      if (gallery.isRecentlyViewed) {
        // Load recently viewed media
        mediaItems = await GalleryService.getRecentlyViewedMedia();
      } else {
        // Load media items by searching for each NASA ID
        for (final nasaId in gallery.mediaIds) {
          try {
            final collection = await NasaService.searchMedia(
              query: nasaId,
              pageSize: 1,
            );
            
            final foundItem = collection.items.firstWhere(
              (item) => item.nasaId == nasaId,
              orElse: () => throw Exception('Media not found'),
            );
            
            mediaItems.add(foundItem);
          } catch (e) {
            print('Failed to load media $nasaId: $e');
            // Continue loading other items
          }
        }
      }

      setState(() {
        _gallery = gallery;
        _mediaItems = mediaItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromGallery(NasaMediaItem mediaItem) async {
    if (_gallery == null) return;

    try {
      if (_gallery!.isRecentlyViewed) {
        // For recently viewed, we can't remove items directly
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot remove items from Recently Viewed gallery'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await GalleryService.removeMediaFromGallery(_gallery!.id, mediaItem.nasaId);
      await _loadGalleryDetails(); // Reload the gallery
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${mediaItem.title}" from gallery'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await GalleryService.addMediaToGallery(_gallery!.id, mediaItem.nasaId);
                await _loadGalleryDetails();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from gallery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<NasaMediaItem> get _filteredItems {
    if (_selectedFilter == null || _selectedFilter == 'All') {
      return _mediaItems;
    }
    
    return _mediaItems.where((item) {
      return item.mediaType.toLowerCase() == _selectedFilter!.toLowerCase();
    }).toList();
  }

  void _navigateToDetails(NasaMediaItem mediaItem) {
    // Add to recently viewed if not already in recently viewed gallery
    if (!(_gallery?.isRecentlyViewed ?? false)) {
      GalleryService.addToRecentlyViewed(mediaItem);
    }
    
    context.push('/gallery/media/${mediaItem.nasaId}');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_gallery?.name ?? 'Gallery'),
        backgroundColor: _gallery?.isRecentlyViewed == true 
            ? Colors.deepPurple.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
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
            Text('Loading gallery...'),
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
                'Failed to load gallery',
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
                onPressed: _loadGalleryDetails,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_gallery == null) {
      return const Center(
        child: Text('Gallery not found'),
      );
    }

    return Column(
      children: [
        _buildGalleryHeader(),
        if (_mediaItems.isNotEmpty) _buildFilterSection(),
        Expanded(child: _buildMediaGrid()),
      ],
    );
  }

  Widget _buildGalleryHeader() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getContentPadding(context);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _gallery!.isRecentlyViewed 
            ? Colors.deepPurple.withOpacity(0.05)
            : Colors.blue.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _gallery!.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 20 : 24,
                          ),
                    ),
                    if (_gallery!.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _gallery!.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_gallery!.isRecentlyViewed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.deepPurple[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SPECIAL',
                        style: TextStyle(
                          color: Colors.deepPurple[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.photo_library,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${_mediaItems.length} item${_mediaItems.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _gallery!.isRecentlyViewed 
                    ? _gallery!.formattedLastModified
                    : 'Created ${_gallery!.formattedDate}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getContentPadding(context);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTypes.map((type) {
                  final isSelected = (_selectedFilter ?? 'All') == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? type : null;
                          if (type == 'All') _selectedFilter = null;
                        });
                      },
                      selectedColor: _gallery!.isRecentlyViewed 
                          ? Colors.deepPurple.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      checkmarkColor: _gallery!.isRecentlyViewed 
                          ? Colors.deepPurple
                          : Colors.blue,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    final filteredItems = _filteredItems;
    
    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadGalleryDetails,
      child: GridView.builder(
        padding: ResponsiveUtils.getScreenPadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(context),
          childAspectRatio: ResponsiveUtils.getGridChildAspectRatio(context),
          crossAxisSpacing: ResponsiveUtils.getGridSpacing(context),
          mainAxisSpacing: ResponsiveUtils.getGridSpacing(context),
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final mediaItem = filteredItems[index];
          return MediaCard(
            mediaItem: mediaItem,
            onTap: () => _navigateToDetails(mediaItem),
            showAddToGallery: false, // Don't show add to gallery in gallery detail
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final hasFilter = _selectedFilter != null && _selectedFilter != 'All';
    
    return Center(
      child: Padding(
        padding: ResponsiveUtils.getContentPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.filter_list_off : Icons.photo_library_outlined,
              size: isMobile ? 80 : 120,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 24 : 32),
            Text(
              hasFilter 
                  ? 'No ${_selectedFilter!.toLowerCase()} media'
                  : 'Empty gallery',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 20 : 24,
                  ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              hasFilter
                  ? 'Try a different filter to see more content'
                  : _gallery!.isRecentlyViewed
                      ? 'Start viewing NASA media to see them here!'
                      : 'Add some NASA media to this gallery from the home screen',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 14 : 16,
                  ),
            ),
            if (!hasFilter && !_gallery!.isRecentlyViewed) ...[
              SizedBox(height: isMobile ? 32 : 40),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.explore),
                label: const Text('Explore NASA Media'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: isMobile ? 12 : 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}