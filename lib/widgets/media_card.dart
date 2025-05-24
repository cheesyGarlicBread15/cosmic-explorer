// lib/widgets/media_card.dart
import 'package:flutter/material.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';

class MediaCard extends StatelessWidget {
  final NasaMediaItem mediaItem;
  final VoidCallback onTap;

  const MediaCard({
    super.key,
    required this.mediaItem,
    required this.onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildMediaPreview(context),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMediaTypeChip(context),
                    SizedBox(height: isMobile ? 8 : 12),
                    Expanded(
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
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mediaItem.mediaTypeIcon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
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
}
