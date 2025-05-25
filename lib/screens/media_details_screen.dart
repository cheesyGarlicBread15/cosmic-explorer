// lib/screens/media_details_screen.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
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
  bool _isDescriptionExpanded = false;

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

      final collection = await NasaService.searchMedia(
        query: widget.nasaId,
        pageSize: 50,
      );

      NasaMediaItem? foundItem;
      for (final item in collection.items) {
        if (item.nasaId == widget.nasaId) {
          foundItem = item;
          break;
        }
      }

      if (foundItem != null) {
        List<String> assetUrls = [];
        try {
          assetUrls = await NasaService.getAssetUrls(widget.nasaId);
        } catch (e) {
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
          if (_assetUrls.isNotEmpty) _buildMediaViewer(),
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
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 4,
                    clipBehavior: Clip.antiAlias,
                    child: _buildMediaPreview(),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMediaInfoContent(),
                      if (_assetUrls.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildMediaViewerContent(),
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
        
        _buildDescriptionSection(),
        
        const SizedBox(height: 16),
        _buildInfoGrid(),
        
        if (_mediaItem!.keywords.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildKeywordsSection(),
        ],
      ],
    );
  }

  Widget _buildDescriptionSection() {
    const int maxLength = 300;
    final description = _mediaItem!.description;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
            children: [
              TextSpan(
                text: description.length > maxLength && !_isDescriptionExpanded
                    ? description.substring(0, maxLength)
                    : description,
              ),
              if (description.length > maxLength && !_isDescriptionExpanded) ...[
                const TextSpan(text: '... '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = true;
                      });
                    },
                    child: Text(
                      'Read More',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            height: 1.5,
                          ),
                    ),
                  ),
                ),
              ],
              if (description.length > maxLength && _isDescriptionExpanded) ...[
                const TextSpan(text: ' '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = false;
                      });
                    },
                    child: Text(
                      'Show Less',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            height: 1.5,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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

  Widget _buildMediaViewer() {
    return Padding(
      padding: ResponsiveUtils.getContentPadding(context),
      child: _buildMediaViewerContent(),
    );
  }

  Widget _buildMediaViewerContent() {
    if (_assetUrls.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media File',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildMediaTypeViewer(),
      ],
    );
  }

  Widget _buildMediaTypeViewer() {
    final mediaType = _mediaItem!.mediaType.toLowerCase();
    final mediaUrl = _findBestMediaFile(mediaType);
    
    if (mediaUrl == null) {
      return _buildNoMediaFound();
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildMediaByType(mediaUrl, mediaType),
    );
  }

  Widget _buildMediaByType(String url, String mediaType) {
    switch (mediaType) {
      case 'image':
        return _buildImageViewer(url);
      case 'video':
        return _buildVideoLauncher(url);
      case 'audio':
        return _buildAudioLauncher(url);
      default:
        return _buildGenericLauncher(url);
    }
  }

  Widget _buildImageViewer(String imageUrl) {
    return Container(
      height: 400,
      child: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        backgroundDecoration: const BoxDecoration(color: Colors.white),
        loadingBuilder: (context, event) {
          return Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: event?.expectedTotalBytes != null
                        ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Loading image...'),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError(imageUrl);
        },
      ),
    );
  }

  Widget _buildImageError(String imageUrl) {
    return Container(
      height: 200,
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text('Could not load image', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchUrl(imageUrl),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open in Browser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLauncher(String videoUrl) {
    return Container(
      height: 300,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, size: 80, color: Colors.white.withOpacity(0.8)),
            const SizedBox(height: 20),
            Text(
              _mediaItem!.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Click to play video',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(videoUrl),
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Play Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _copyToClipboard(videoUrl),
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                  label: const Text('Copy URL', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioLauncher(String audioUrl) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.audiotrack, size: 40, color: Colors.deepPurple),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mediaItem!.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NASA Audio File',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _launchUrl(audioUrl),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Play Audio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyToClipboard(audioUrl),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy URL'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.deepPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenericLauncher(String url) {
    return Container(
      height: 150,
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Media File Available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(url),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Open'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(url),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy URL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMediaFound() {
    return Container(
      height: 150,
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No Media File Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'This item may only contain thumbnails',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String? _findBestMediaFile(String mediaType) {
    for (String url in _assetUrls) {
      final lowerUrl = url.toLowerCase();
      
      if (mediaType == 'video' && 
          (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov') || 
           lowerUrl.endsWith('.avi') || lowerUrl.endsWith('.webm'))) {
        return url;
      }
      
      if (mediaType == 'audio' && 
          (lowerUrl.endsWith('.mp3') || lowerUrl.endsWith('.wav') || 
           lowerUrl.endsWith('.m4a') || lowerUrl.endsWith('.aac'))) {
        return url;
      }
      
      if (mediaType == 'image' && 
          (lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg') || 
           lowerUrl.endsWith('.png') || lowerUrl.endsWith('.gif')) &&
          !lowerUrl.contains('~thumb') && !lowerUrl.contains('~small')) {
        return url;
      }
    }
    
    return null;
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Error opening URL: $e');
    }
  }

  void _copyToClipboard(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL copied: ${url.split('/').last}'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => _launchUrl(url),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}