// lib/models/nasa_media.dart
class NasaMediaCollection {
  final List<NasaMediaItem> items;
  final int totalHits;

  NasaMediaCollection({
    required this.items,
    required this.totalHits,
  });

  factory NasaMediaCollection.fromJson(Map<String, dynamic> json) {
    final collection = json['collection'] as Map<String, dynamic>;
    final items = (collection['items'] as List)
        .map((item) => NasaMediaItem.fromJson(item))
        .toList();

    return NasaMediaCollection(
      items: items,
      totalHits: collection['metadata']?['total_hits'] ?? 0,
    );
  }
}

class NasaMediaItem {
  final String nasaId;
  final String title;
  final String description;
  final String mediaType;
  final List<String> keywords;
  final String? photographer;
  final String? location;
  final DateTime? dateCreated;
  final String? center;
  final List<NasaMediaLink> links;
  final DateTime? viewedAt; // For tracking when it was viewed

  NasaMediaItem({
    required this.nasaId,
    required this.title,
    required this.description,
    required this.mediaType,
    required this.keywords,
    this.photographer,
    this.location,
    this.dateCreated,
    this.center,
    required this.links,
    this.viewedAt,
  });

  factory NasaMediaItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'][0] as Map<String, dynamic>;
    final links = (json['links'] as List?)
            ?.map((link) => NasaMediaLink.fromJson(link))
            .toList() ??
        [];

    return NasaMediaItem(
      nasaId: data['nasa_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      mediaType: data['media_type'] ?? '',
      keywords: List<String>.from(data['keywords'] ?? []),
      photographer: data['photographer'],
      location: data['location'],
      dateCreated: data['date_created'] != null
          ? DateTime.tryParse(data['date_created'])
          : null,
      center: data['center'],
      links: links,
    );
  }

  // Create a copy with viewedAt timestamp
  NasaMediaItem copyWithViewed() {
    return NasaMediaItem(
      nasaId: nasaId,
      title: title,
      description: description,
      mediaType: mediaType,
      keywords: keywords,
      photographer: photographer,
      location: location,
      dateCreated: dateCreated,
      center: center,
      links: links,
      viewedAt: DateTime.now(),
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'nasa_id': nasaId,
      'title': title,
      'description': description,
      'media_type': mediaType,
      'keywords': keywords,
      'photographer': photographer,
      'location': location,
      'date_created': dateCreated?.toIso8601String(),
      'center': center,
      'links': links.map((link) => link.toJson()).toList(),
      'viewed_at': viewedAt?.toIso8601String(),
    };
  }

  // Create from JSON (for storage)
  factory NasaMediaItem.fromStoredJson(Map<String, dynamic> json) {
    final links = (json['links'] as List?)
            ?.map((link) => NasaMediaLink.fromJson(link))
            .toList() ??
        [];

    return NasaMediaItem(
      nasaId: json['nasa_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaType: json['media_type'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      photographer: json['photographer'],
      location: json['location'],
      dateCreated: json['date_created'] != null
          ? DateTime.tryParse(json['date_created'])
          : null,
      center: json['center'],
      links: links,
      viewedAt: json['viewed_at'] != null
          ? DateTime.tryParse(json['viewed_at'])
          : null,
    );
  }

  String? get thumbnailUrl {
    return links.isNotEmpty ? links.first.href : null;
  }

  String get formattedDate {
    if (dateCreated == null) return 'Unknown date';
    return '${dateCreated!.day}/${dateCreated!.month}/${dateCreated!.year}';
  }

  String get formattedViewedDate {
    if (viewedAt == null) return 'Never viewed';
    final now = DateTime.now();
    final difference = now.difference(viewedAt!);
    
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

  String get mediaTypeIcon {
    switch (mediaType.toLowerCase()) {
      case 'image':
        return '🖼️';
      case 'video':
        return '🎥';
      case 'audio':
        return '🎵';
      default:
        return '📄';
    }
  }
}

class NasaMediaLink {
  final String href;
  final String? rel;
  final String? render;

  NasaMediaLink({
    required this.href,
    this.rel,
    this.render,
  });

  factory NasaMediaLink.fromJson(Map<String, dynamic> json) {
    return NasaMediaLink(
      href: json['href'] ?? '',
      rel: json['rel'],
      render: json['render'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'href': href,
      'rel': rel,
      'render': render,
    };
  }
}