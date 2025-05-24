// lib/widgets/media_card.dart
import 'package:flutter/material.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';

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
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildMediaPreview(),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMediaTypeChip(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        mediaItem.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mediaItem.formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
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

  Widget _buildMediaPreview() {
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
                  return _buildLoadingPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPlaceholder();
                },
              ),
            )
          else
            _buildDefaultPlaceholder(),
          
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

  Widget _buildMediaTypeChip() {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        mediaItem.mediaType.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
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
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            mediaItem.mediaType.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}