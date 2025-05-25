// lib/screens/media_details_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:photo_view/photo_view.dart';
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
  
  // Video player controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoHasError = false;
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;
  bool _isAudioLoading = false;
  bool _audioHasError = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadMediaDetails();
    _setupAudioListeners();
  }

  @override
  void dispose() {
    // Safely dispose video controller
    _videoController?.pause();
    _videoController?.dispose();
    
    // Safely dispose audio player
    _audioPlayer.stop();
    _audioPlayer.dispose();
    
    super.dispose();
  }

  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
        });
      }
    });
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

        // Initialize media players if we have assets
        if (assetUrls.isNotEmpty) {
          _initializeMediaPlayer();
        }
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

  Future<void> _initializeMediaPlayer() async {
    if (_assetUrls.isEmpty) return;
    
    final originalAssetUrl = _assetUrls[0];
    final mediaType = _mediaItem!.mediaType.toLowerCase();
    
    if (mediaType == 'video') {
      await _initializeVideoPlayer(originalAssetUrl);
    } else if (mediaType == 'audio') {
      await _initializeAudioPlayer(originalAssetUrl);
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      // Dispose previous controller if exists
      await _videoController?.dispose();
      
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      
      // Add timeout for initialization
      await _videoController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video initialization timeout - this may not be a direct video file');
        },
      );
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _videoHasError = false;
        });
      }
    } catch (e) {
      print('Error initializing video player: $e');
      print('Video URL: $videoUrl');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
          _videoHasError = true;
        });
      }
    }
  }

  Future<void> _initializeAudioPlayer(String audioUrl) async {
    try {
      if (mounted) {
        setState(() {
          _isAudioLoading = true;
          _audioHasError = false;
        });
      }
      
      // Stop any previous audio
      await _audioPlayer.stop();
      
      // Add timeout for audio loading
      await _audioPlayer.setSourceUrl(audioUrl).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Audio loading timeout - this may not be a direct audio file');
        },
      );
      
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _audioHasError = false;
        });
      }
    } catch (e) {
      print('Error initializing audio player: $e');
      print('Audio URL: $audioUrl');
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _audioHasError = true;
        });
      }
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
          if (_assetUrls.isNotEmpty) _buildMediaPlayer(),
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
                        _buildMediaPlayerContent(),
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

  Widget _buildMediaPlayer() {
    return Padding(
      padding: ResponsiveUtils.getContentPadding(context),
      child: _buildMediaPlayerContent(),
    );
  }

  Widget _buildMediaPlayerContent() {
    if (_assetUrls.isEmpty) return const SizedBox.shrink();
    
    final originalAssetUrl = _assetUrls[0]; // Get the first (original quality) asset
    final mediaType = _mediaItem!.mediaType.toLowerCase();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Original Media',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildMediaPlayerByType(originalAssetUrl, mediaType),
        ),
      ],
    );
  }

  Widget _buildMediaPlayerByType(String assetUrl, String mediaType) {
    switch (mediaType) {
      case 'image':
        return _buildImagePlayer(assetUrl);
      case 'video':
        return _buildVideoPlayer(assetUrl);
      case 'audio':
        return _buildAudioPlayer(assetUrl);
      default:
        return _buildDefaultPlayer(assetUrl);
    }
  }

  Widget _buildImagePlayer(String imageUrl) {
    return Container(
      height: 400,
      child: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.0,
        backgroundDecoration: const BoxDecoration(
          color: Colors.white,
        ),
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
                  const Text('Loading original image...'),
                ],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 400,
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not load image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        height: 300,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_videoHasError) ...[
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Video Player Unavailable',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This might be a metadata file or requires\nexternal video player',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Video URL: $videoUrl'),
                        action: SnackBarAction(
                          label: 'Copy',
                          onPressed: () {
                            // Could implement clipboard copy here
                          },
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: Text('View URL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.deepPurple,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            backgroundColor: Colors.deepPurple.withOpacity(0.8),
            child: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(String audioUrl) {
    if (_audioHasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.grey[50],
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Audio Player Unavailable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This might be a metadata file or requires\nexternal audio player',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Audio URL: $audioUrl'),
                      action: SnackBarAction(
                        label: 'Copy',
                        onPressed: () {
                          // Could implement clipboard copy here
                        },
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.open_in_new, size: 16),
                label: Text('View URL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.audiotrack,
                  size: 30,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mediaItem!.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NASA Audio File',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress bar
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _audioDuration.inMilliseconds > 0
                      ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
                      : 0.0,
                  onChanged: (value) async {
                    final position = Duration(
                      milliseconds: (value * _audioDuration.inMilliseconds).round(),
                    );
                    await _audioPlayer.seek(position);
                  },
                  activeColor: Colors.deepPurple,
                  inactiveColor: Colors.grey[300],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_audioPosition),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDuration(_audioDuration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  final position = _audioPosition - const Duration(seconds: 10);
                  await _audioPlayer.seek(position.isNegative ? Duration.zero : position);
                },
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 20),
              _isAudioLoading
                  ? const CircularProgressIndicator()
                  : FloatingActionButton(
                      onPressed: () async {
                        if (_isAudioPlaying) {
                          await _audioPlayer.pause();
                        } else {
                          await _audioPlayer.resume();
                        }
                      },
                      backgroundColor: Colors.deepPurple,
                      child: Icon(
                        _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () async {
                  final position = _audioPosition + const Duration(seconds: 10);
                  final maxPosition = _audioDuration;
                  await _audioPlayer.seek(position > maxPosition ? maxPosition : position);
                },
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
                color: Colors.deepPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlayer(String assetUrl) {
    return Container(
      height: 150,
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Media File Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Media URL: $assetUrl'),
                    action: SnackBarAction(
                      label: 'Copy',
                      onPressed: () {
                        // You can implement clipboard copy here if needed
                      },
                    ),
                  ),
                );
              },
              child: const Text('View Media'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}