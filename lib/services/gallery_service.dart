import 'package:cosmic_explorer/models/gallery.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';
import 'package:cosmic_explorer/services/supabase_service.dart';

class GalleryService {
  static final _supabase = SupabaseService.supabase;

  // Create a new gallery
  static Future<Gallery> createGallery({
    required String name,
    String? description,
  }) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final gallery = Gallery.create(name: name, description: description);
    
    await _supabase.from('galleries').insert({
      'id': gallery.id,
      'user_id': user.id,
      'name': gallery.name,
      'description': gallery.description,
      'date_created': gallery.dateCreated.toIso8601String(),
      'last_modified': gallery.lastModified.toIso8601String(),
      'media_ids': gallery.mediaIds,
      'is_recently_viewed': gallery.isRecentlyViewed,
      'cover_image_url': gallery.coverImageUrl,
    });

    return gallery;
  }

  // Get all galleries for current user
  static Future<List<Gallery>> getAllGalleries() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get user galleries from Supabase
      final response = await _supabase
          .from('galleries')
          .select()
          .eq('user_id', user.id)
          .order('date_created', ascending: false);

      List<Gallery> galleries = [];
      
      // Convert Supabase data to Gallery objects
      for (final item in response) {
        galleries.add(Gallery(
          id: item['id'],
          name: item['name'],
          description: item['description'],
          dateCreated: DateTime.parse(item['date_created']),
          lastModified: DateTime.parse(item['last_modified']),
          mediaIds: List<String>.from(item['media_ids'] ?? []),
          isRecentlyViewed: item['is_recently_viewed'] ?? false,
          coverImageUrl: item['cover_image_url'],
        ));
      }
      
      // Add recently viewed gallery at the beginning
      final recentlyViewed = await _getRecentlyViewedGallery();
      galleries.insert(0, recentlyViewed);
      
      return galleries;
    } catch (e) {
      print('Error loading galleries: $e');
      return [await _getRecentlyViewedGallery()];
    }
  }

  // Get a specific gallery by ID
  static Future<Gallery?> getGallery(String id) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (id == 'recently_viewed') {
      return await _getRecentlyViewedGallery();
    }
    
    try {
      final response = await _supabase
          .from('galleries')
          .select()
          .eq('user_id', user.id)
          .eq('id', id)
          .single();

      return Gallery(
        id: response['id'],
        name: response['name'],
        description: response['description'],
        dateCreated: DateTime.parse(response['date_created']),
        lastModified: DateTime.parse(response['last_modified']),
        mediaIds: List<String>.from(response['media_ids'] ?? []),
        isRecentlyViewed: response['is_recently_viewed'] ?? false,
        coverImageUrl: response['cover_image_url'],
      );
    } catch (e) {
      print('Error loading gallery $id: $e');
      return null;
    }
  }

  // Update a gallery
  static Future<void> updateGallery(Gallery gallery) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (gallery.isRecentlyViewed) {
      return;
    }

    await _supabase.from('galleries').update({
      'name': gallery.name,
      'description': gallery.description,
      'last_modified': gallery.lastModified.toIso8601String(),
      'media_ids': gallery.mediaIds,
      'cover_image_url': gallery.coverImageUrl,
    }).eq('user_id', user.id).eq('id', gallery.id);
  }

  // Delete a gallery
  static Future<void> deleteGallery(String id) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (id == 'recently_viewed') return;
    
    await _supabase
        .from('galleries')
        .delete()
        .eq('user_id', user.id)
        .eq('id', id);
  }

  // Add media to gallery
  static Future<void> addMediaToGallery(String galleryId, String nasaId) async {
    final gallery = await getGallery(galleryId);
    if (gallery != null) {
      final updatedGallery = gallery.addMedia(nasaId);
      await updateGallery(updatedGallery);
    }
  }

  // Remove media from gallery
  static Future<void> removeMediaFromGallery(String galleryId, String nasaId) async {
    final gallery = await getGallery(galleryId);
    if (gallery != null) {
      final updatedGallery = gallery.removeMedia(nasaId);
      await updateGallery(updatedGallery);
    }
  }

  // Add to recently viewed
  static Future<void> addToRecentlyViewed(NasaMediaItem mediaItem) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Check if this media item already exists in recently viewed
      final existingResponse = await _supabase
          .from('recently_viewed')
          .select()
          .eq('user_id', user.id)
          .eq('nasa_id', mediaItem.nasaId);

      if (existingResponse.isNotEmpty) {
        // Update existing entry with new timestamp
        await _supabase.from('recently_viewed').update({
          'viewed_at': DateTime.now().toIso8601String(),
          'media_data': mediaItem.toJson(),
        }).eq('user_id', user.id).eq('nasa_id', mediaItem.nasaId);
      } else {
        // Insert new entry
        await _supabase.from('recently_viewed').insert({
          'user_id': user.id,
          'nasa_id': mediaItem.nasaId,
          'viewed_at': DateTime.now().toIso8601String(),
          'media_data': mediaItem.toJson(),
        });
      }

      // Clean up old entries (keep only 100 most recent)
      final allRecentlyViewed = await _supabase
          .from('recently_viewed')
          .select('id')
          .eq('user_id', user.id)
          .order('viewed_at', ascending: false);

      if (allRecentlyViewed.length > 100) {
        final toDelete = allRecentlyViewed.skip(100).map((item) => item['id']).toList();
        await _supabase
            .from('recently_viewed')
            .delete()
            .inFilter('id', toDelete);
      }
    } catch (e) {
      print('Error adding to recently viewed: $e');
    }
  }

  // Get recently viewed media items
  static Future<List<NasaMediaItem>> getRecentlyViewedMedia() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final response = await _supabase
          .from('recently_viewed')
          .select()
          .eq('user_id', user.id)
          .order('viewed_at', ascending: false)
          .limit(100);

      return response.map<NasaMediaItem>((item) {
        final mediaData = Map<String, dynamic>.from(item['media_data']);
        return NasaMediaItem.fromStoredJson(mediaData);
      }).toList();
    } catch (e) {
      print('Error loading recently viewed: $e');
      return [];
    }
  }

  // Clear recently viewed
  static Future<void> clearRecentlyViewed() async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _supabase
          .from('recently_viewed')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      print('Error clearing recently viewed: $e');
    }
  }

  // Get galleries that contain a specific media item
  static Future<List<Gallery>> getGalleriesContainingMedia(String nasaId) async {
    final galleries = await getAllGalleries();
    return galleries.where((gallery) => gallery.mediaIds.contains(nasaId)).toList();
  }

  // Private helper method to get recently viewed gallery
  static Future<Gallery> _getRecentlyViewedGallery() async {
    final recentlyViewedMedia = await getRecentlyViewedMedia();
    final mediaIds = recentlyViewedMedia.map((item) => item.nasaId).toList();
    
    return Gallery(
      id: 'recently_viewed',
      name: 'Recently Viewed',
      description: 'Your recently viewed NASA media',
      dateCreated: DateTime.now(),
      lastModified: DateTime.now(),
      mediaIds: mediaIds,
      isRecentlyViewed: true,
    );
  }
}