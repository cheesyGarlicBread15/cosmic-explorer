// lib/widgets/gallery_card.dart
import 'package:flutter/material.dart';
import 'package:cosmic_explorer/models/gallery.dart';
import 'package:cosmic_explorer/utils/responsive_utils.dart';

class GalleryCard extends StatelessWidget {
  final Gallery gallery;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GalleryCard({
    super.key,
    required this.gallery,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Card(
      elevation: gallery.isRecentlyViewed ? 8 : (isMobile ? 4 : 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        side: gallery.isRecentlyViewed
            ? BorderSide(color: Colors.deepPurple, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: (onEdit != null || onDelete != null)
            ? () => _showOptions(context)
            : null,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildGalleryPreview(context),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gallery.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                gallery.isRecentlyViewed
                                    ? gallery.formattedLastModified
                                    : 'Created ${gallery.formattedDate}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[500],
                                      fontSize: isMobile ? 11 : 12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Options button for user galleries
            if ((onEdit != null || onDelete != null) &&
                !gallery.isRecentlyViewed)
              Positioned(
                top: 8,
                right: 8,
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
                      Icons.more_vert,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => _showOptions(context),
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

  Widget _buildGalleryPreview(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gallery.isRecentlyViewed
              ? [
                  Colors.deepPurple.withOpacity(0.2),
                  Colors.deepPurple.withOpacity(0.4),
                ]
              : [
                  Colors.blue.withOpacity(0.1),
                  Colors.blue.withOpacity(0.3),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Show most recent media or fallback to placeholder
          gallery.coverImageUrl != null
              ? Image.network(
                  gallery.coverImageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildLoadingPlaceholder(context);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(context);
                  },
                )
              : _buildPlaceholder(context),

          // Overlay showing item count if gallery has multiple items
          if (gallery.mediaCount > 1)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.collections,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${gallery.mediaCount}',
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

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: CircularProgressIndicator(
          color: gallery.isRecentlyViewed ? Colors.deepPurple : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            gallery.isEmpty
                ? Icons.add_photo_alternate_outlined
                : (gallery.isRecentlyViewed
                    ? Icons.history
                    : Icons.collections),
            size: isMobile ? 48 : 64,
            color: gallery.isRecentlyViewed
                ? Colors.deepPurple.withOpacity(0.7)
                : Colors.blue.withOpacity(0.7),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            gallery.isEmpty
                ? 'Add Photos'
                : (gallery.isRecentlyViewed
                    ? 'Recently Viewed'
                    : '${gallery.mediaCount} Items'),
            style: TextStyle(
              color: gallery.isRecentlyViewed
                  ? Colors.deepPurple.withOpacity(0.8)
                  : Colors.blue.withOpacity(0.8),
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final options = <Widget>[];

    // Always add view option
    options.add(
      ListTile(
        leading: const Icon(Icons.visibility),
        title: const Text('View Gallery'),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );

    // Add edit option if available
    if (onEdit != null) {
      options.add(
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Gallery'),
          onTap: () {
            Navigator.pop(context);
            onEdit!();
          },
        ),
      );
    }

    // Add delete option if available
    if (onDelete != null) {
      options.add(
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.red),
          title: const Text('Delete Gallery'),
          textColor: Colors.red,
          onTap: () {
            Navigator.pop(context);
            onDelete!();
          },
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
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

            // Gallery info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gallery.isRecentlyViewed
                        ? Colors.deepPurple.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    gallery.isRecentlyViewed
                        ? Icons.history
                        : Icons.collections,
                    color: gallery.isRecentlyViewed
                        ? Colors.deepPurple
                        : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gallery.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${gallery.mediaCount} item${gallery.mediaCount == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Options
            ...options,
          ],
        ),
      ),
    );
  }
}
