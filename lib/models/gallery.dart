import 'package:cosmic_explorer/models/nasa_media.dart';

class Gallery {
  final String id;
  final String name;
  final String? description;
  final DateTime dateCreated;
  final DateTime lastModified;
  final List<String> mediaIds;
  final bool isRecentlyViewed;
  final String? coverImageUrl;

  Gallery({
    required this.id,
    required this.name,
    this.description,
    required this.dateCreated,
    required this.lastModified,
    required this.mediaIds,
    this.isRecentlyViewed = false,
    this.coverImageUrl,
  });

  // Create a new gallery
  factory Gallery.create({
    required String name,
    String? description,
  }) {
    final now = DateTime.now();
    return Gallery(
      id: 'gallery_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      dateCreated: now,
      lastModified: now,
      mediaIds: [],
    );
  }

  // Create the special recently viewed gallery
  factory Gallery.recentlyViewed() {
    final now = DateTime.now();
    return Gallery(
      id: 'recently_viewed',
      name: 'Recently Viewed',
      description: 'Your recently viewed NASA media',
      dateCreated: now,
      lastModified: now,
      mediaIds: [],
      isRecentlyViewed: true,
    );
  }

  // Copy with new values
  Gallery copyWith({
    String? name,
    String? description,
    List<String>? mediaIds,
    String? coverImageUrl,
    DateTime? lastModified,
  }) {
    return Gallery(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      dateCreated: dateCreated,
      lastModified: lastModified ?? DateTime.now(),
      mediaIds: mediaIds ?? this.mediaIds,
      isRecentlyViewed: isRecentlyViewed,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }

  // Add media to gallery
  Gallery addMedia(String nasaId) {
    final updatedMediaIds = List<String>.from(mediaIds);
    if (!updatedMediaIds.contains(nasaId)) {
      updatedMediaIds.insert(0, nasaId); // Add to beginning
    }
    return copyWith(
      mediaIds: updatedMediaIds,
      lastModified: DateTime.now(),
    );
  }

  // Remove media from gallery
  Gallery removeMedia(String nasaId) {
    final updatedMediaIds = List<String>.from(mediaIds);
    updatedMediaIds.remove(nasaId);
    return copyWith(
      mediaIds: updatedMediaIds,
      lastModified: DateTime.now(),
    );
  }

  // JSON 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dateCreated': dateCreated.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'mediaIds': mediaIds,
      'isRecentlyViewed': isRecentlyViewed,
      'coverImageUrl': coverImageUrl,
    };
  }

  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      dateCreated: DateTime.parse(json['dateCreated']),
      lastModified: DateTime.parse(json['lastModified']),
      mediaIds: List<String>.from(json['mediaIds'] ?? []),
      isRecentlyViewed: json['isRecentlyViewed'] ?? false,
      coverImageUrl: json['coverImageUrl'],
    );
  }

  // Getters
  int get mediaCount => mediaIds.length;
  
  bool get isEmpty => mediaIds.isEmpty;
  
  String get formattedDate {
    return '${dateCreated.day}/${dateCreated.month}/${dateCreated.year}';
  }

  String get formattedLastModified {
    final now = DateTime.now();
    final difference = now.difference(lastModified);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

// Gallery with loaded media items
class GalleryWithMedia {
  final Gallery gallery;
  final List<NasaMediaItem> mediaItems;

  GalleryWithMedia({
    required this.gallery,
    required this.mediaItems,
  });

  String? get coverImageUrl {
    if (gallery.coverImageUrl != null) return gallery.coverImageUrl;
    if (mediaItems.isNotEmpty) return mediaItems.first.thumbnailUrl;
    return null;
  }
}