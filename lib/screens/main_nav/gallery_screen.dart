// lib/screens/gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/services/viewing_history_service.dart';
import 'package:cosmic_explorer/widgets/media_card.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<NasaMediaItem> _recentlyViewed = [];
  bool _isLoading = true;
  String? _selectedFilter;
  final List<String> _filterTypes = ['All', 'Image', 'Video', 'Audio'];

  @override
  void initState() {
    super.initState();
    _loadRecentlyViewed();
  }

  Future<void> _loadRecentlyViewed() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final history = await ViewingHistoryService.getHistory();
      
      setState(() {
        _recentlyViewed = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load viewing history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all viewing history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ViewingHistoryService.clearHistory();
      await _loadRecentlyViewed();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viewing history cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removeFromHistory(NasaMediaItem item) async {
    await ViewingHistoryService.removeFromHistory(item.nasaId);
    await _loadRecentlyViewed();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${item.title}" from history'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await ViewingHistoryService.addToHistory(item);
              await _loadRecentlyViewed();
            },
          ),
        ),
      );
    }
  }

  List<NasaMediaItem> get _filteredItems {
    if (_selectedFilter == null || _selectedFilter == 'All') {
      return _recentlyViewed;
    }
    
    return _recentlyViewed.where((item) {
      return item.mediaType.toLowerCase() == _selectedFilter!.toLowerCase();
    }).toList();
  }

  void _navigateToDetails(NasaMediaItem mediaItem) {
    context.push('/gallery/image/${mediaItem.nasaId}');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        centerTitle: !isMobile,
        actions: [
          if (_recentlyViewed.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear History'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'clear') {
                  _clearHistory();
                }
              },
            ),
        ],
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
            Text('Loading your viewing history...'),
          ],
        ),
      );
    }

    if (_recentlyViewed.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildFilterSection(),
        Expanded(child: _buildHistoryList()),
      ],
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
              Icons.history,
              size: isMobile ? 80 : 120,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 24 : 32),
            Text(
              'No viewing history yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 20 : 24,
                  ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'Browse some NASA media from the home screen to see them here!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 14 : 16,
                  ),
            ),
            SizedBox(height: isMobile ? 32 : 40),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to home tab
                context.go('/home');
              },
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
        ),
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
      child: isMobile ? _buildMobileFilterRow() : _buildDesktopFilterRow(),
    );
  }

  Widget _buildMobileFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Recently Viewed (${_filteredItems.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        DropdownButton<String>(
          value: _selectedFilter ?? 'All',
          underline: const SizedBox(),
          items: _filterTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDesktopFilterRow() {
    return Row(
      children: [
        Text(
          'Recently Viewed (${_filteredItems.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            value: _selectedFilter ?? 'All',
            decoration: InputDecoration(
              labelText: 'Filter',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: _filterTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    final filteredItems = _filteredItems;
    
    if (filteredItems.isEmpty) {
      final isMobile = ResponsiveUtils.isMobile(context);
      
      return Center(
        child: Padding(
          padding: ResponsiveUtils.getContentPadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off,
                size: isMobile ? 64 : 80,
                color: Colors.grey[400],
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Text(
                'No ${_selectedFilter?.toLowerCase()} media in history',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                'Try a different filter or explore more content',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecentlyViewed,
      child: GridView.builder(
        padding: ResponsiveUtils.getScreenPadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.getHistoryGridCount(context),
          childAspectRatio: 0.75,
          crossAxisSpacing: ResponsiveUtils.getGridSpacing(context),
          mainAxisSpacing: ResponsiveUtils.getGridSpacing(context),
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return _buildHistoryCard(item);
        },
      ),
    );
  }

  Widget _buildHistoryCard(NasaMediaItem item) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(item),
        onLongPress: () => _showItemOptions(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildMediaPreview(item),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMediaTypeChip(item),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Viewed ${item.formattedViewedDate}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[600],
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(NasaMediaItem item) {
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
          if (item.thumbnailUrl != null)
            Hero(
              tag: 'media_${item.nasaId}',
              child: Image.network(
                item.thumbnailUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(item);
                },
              ),
            )
          else
            _buildPlaceholder(item),
          
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.mediaTypeIcon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(NasaMediaItem item) {
    IconData iconData;
    switch (item.mediaType.toLowerCase()) {
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
            size: 40,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            item.mediaType.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeChip(NasaMediaItem item) {
    Color chipColor;
    switch (item.mediaType.toLowerCase()) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        item.mediaType.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showItemOptions(NasaMediaItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetails(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove from History'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _removeFromHistory(item);
              },
            ),
          ],
        ),
      ),
    );
  }
}