// lib/screens/media_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/services/nasa_service.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';

class MediaDetailsScreen extends StatefulWidget {
  final String nasaId;

  const MediaDetailsScreen({
    super.key,
    required this.nasaId,
  });

  @override
  State<MediaDetailsScreen> createState() => _MediaDetailsScreenState();
}

class _MediaDetailsScreenState extends State<MediaDetailsScreen> {
  NasaMediaItem? _mediaItem;
  List<String> _assetUrls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMediaDetails();
  }

  Future<void> _loadMediaDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Search for the specific media item by NASA ID
      final collection = await NasaService.searchMedia(
        query: widget.nasaId,
        pageSize: 50, // Increase page size to find the specific item
      );

      // Find the exact match by NASA ID
      NasaMediaItem? foundItem;
      for (final item in collection.items) {
        if (item.nasaId == widget.nasaId) {
          foundItem = item;
          break;
        }
      }

      if (foundItem != null) {
        // Load asset URLs
        List<String> assetUrls = [];
        try {
          assetUrls = await NasaService.getAssetUrls(widget.nasaId);
        } catch (e) {
          // Asset URLs might not be available for all media
          print('Could not load asset URLs: $e');
        }

        setState(() {
          _mediaItem = foundItem;
          _assetUrls = assetUrls;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Media item not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_mediaItem?.title ?? 'Media Details'),
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        centerTitle: !isMobile,
      ),
      body: _buildBody(),
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
            Text('Loading media details...'),
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
                'Failed to load details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMediaDetails,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_mediaItem == null) {
      return const Center(
        child: Text('No media found'),
      );
    }

    final shouldUseWideLayout = ResponsiveUtils.shouldUseWideLayout(context);

    if (shouldUseWideLayout) {
      return _buildWideLayout();
    } else {
      return _buildNarrowLayout();
    }
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaPreview(),
          _buildMediaInfo(),
          if (_assetUrls.isNotEmpty) _buildAssetUrls(),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.getMaxContentWidth(context),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveUtils.getContentPadding(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Media preview
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 4,
                    clipBehavior: Clip.antiAlias,
                    child: _buildMediaPreview(),
                  ),
                ),
                const SizedBox(width: 32),
                // Right side - Media info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMediaInfoContent(),
                      if (_assetUrls.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildAssetUrlsContent(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    final imageHeight = ResponsiveUtils.getDetailImageHeight(context);
    
    return Container(
      width: double.infinity,
      height: imageHeight,
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
          if (_mediaItem!.thumbnailUrl != null)
            Hero(
              tag: 'media_${_mediaItem!.nasaId}',
              child: Image.network(
                _mediaItem!.thumbnailUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
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
                  return _buildPlaceholder();
                },
              ),
            )
          else
            _buildPlaceholder(),
          
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _mediaItem!.mediaTypeIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _mediaItem!.mediaType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    IconData iconData;
    switch (_mediaItem!.mediaType.toLowerCase()) {
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
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _mediaItem!.mediaType.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaInfo() {
    return Padding(
      padding: ResponsiveUtils.getContentPadding(context),
      child: _buildMediaInfoContent(),
    );
  }

  Widget _buildMediaInfoContent() {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _mediaItem!.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 20 : 24,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'NASA ID: ${_mediaItem!.nasaId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(height: 20),
        
        _buildInfoSection('Description', _mediaItem!.description),
        
        const SizedBox(height: 16),
        _buildInfoGrid(),
        
        if (_mediaItem!.keywords.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildKeywordsSection(),
        ],
      ],
    );
  }

  Widget _buildInfoGrid() {
    final isMobile = ResponsiveUtils.isMobile(context);
    final infoItems = <MapEntry<String, String>>[];
    
    infoItems.add(MapEntry('Date Created', _mediaItem!.formattedDate));
    if (_mediaItem!.center != null) {
      infoItems.add(MapEntry('NASA Center', _mediaItem!.center!));
    }
    if (_mediaItem!.photographer != null) {
      infoItems.add(MapEntry('Photographer', _mediaItem!.photographer!));
    }
    if (_mediaItem!.location != null) {
      infoItems.add(MapEntry('Location', _mediaItem!.location!));
    }

    if (isMobile) {
      return Column(
        children: infoItems.map((entry) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildInfoRow(entry.key, entry.value),
          ),
        ).toList(),
      );
    } else {
      return Wrap(
        spacing: 32,
        runSpacing: 16,
        children: infoItems.map((entry) => 
          SizedBox(
            width: 250,
            child: _buildInfoRow(entry.key, entry.value),
          ),
        ).toList(),
      );
    }
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keywords',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _mediaItem!.keywords.map((keyword) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.3),
                ),
              ),
              child: Text(
                keyword,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.deepPurple[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssetUrls() {
    return Padding(
      padding: ResponsiveUtils.getContentPadding(context),
      child: _buildAssetUrlsContent(),
    );
  }

  Widget _buildAssetUrlsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Assets',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _assetUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              final isLast = index == _assetUrls.length - 1;
              
              return Container(
                decoration: BoxDecoration(
                  border: isLast 
                      ? null 
                      : Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: ListTile(
                  leading: Icon(
                    _getAssetIcon(url),
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    _getAssetName(url),
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    url,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () {
                    // You can implement URL launching here if needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Asset URL: $url'),
                        action: SnackBarAction(
                          label: 'Copy',
                          onPressed: () {
                            // Implement clipboard copy if needed
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getAssetIcon(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getAssetName(String url) {
    final uri = Uri.parse(url);
    String fileName = uri.pathSegments.last;
    if (fileName.isEmpty) {
      fileName = 'Asset file';
    }
    return fileName;
  }
}