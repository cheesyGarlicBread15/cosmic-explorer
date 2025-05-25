import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/services/gallery_service.dart';

class ViewingHistoryService {
  static Future<void> addToHistory(NasaMediaItem mediaItem) async {
    return GalleryService.addToRecentlyViewed(mediaItem);
  }

  static Future<List<NasaMediaItem>> getHistory() async {
    return GalleryService.getRecentlyViewedMedia();
  }

  static Future<void> clearHistory() async {
    return GalleryService.clearRecentlyViewed();
  }

  static Future<void> removeFromHistory(String nasaId) async {
    print('Remove from history not implemented with Supabase backend');
  }

  static Future<bool> isInHistory(String nasaId) async {
    final history = await getHistory();
    return history.any((item) => item.nasaId == nasaId);
  }
}