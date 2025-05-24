// lib/services/viewing_history_service.dart
import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/services/gallery_service.dart';

/// Legacy viewing history service that now delegates to GalleryService
/// This maintains backward compatibility while using Supabase backend
class ViewingHistoryService {
  /// Add item to viewing history (delegates to GalleryService)
  static Future<void> addToHistory(NasaMediaItem mediaItem) async {
    return GalleryService.addToRecentlyViewed(mediaItem);
  }

  /// Get viewing history (delegates to GalleryService)
  static Future<List<NasaMediaItem>> getHistory() async {
    return GalleryService.getRecentlyViewedMedia();
  }

  /// Clear viewing history (delegates to GalleryService)
  static Future<void> clearHistory() async {
    return GalleryService.clearRecentlyViewed();
  }

  /// Remove item from history (not directly supported, but can be implemented)
  static Future<void> removeFromHistory(String nasaId) async {
    // Note: This would require additional Supabase implementation
    // For now, we'll just log that this functionality is not available
    print('Remove from history not implemented with Supabase backend');
  }

  /// Check if item is in history
  static Future<bool> isInHistory(String nasaId) async {
    final history = await getHistory();
    return history.any((item) => item.nasaId == nasaId);
  }
}