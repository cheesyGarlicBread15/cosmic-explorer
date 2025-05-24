import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cosmic_explorer/models/nasa_media.dart';

class NasaService {
  static const String _baseUrl = 'https://images-api.nasa.gov';
  static const List<String> _searchTerms = [
    'earth',
    'mars',
    'moon',
    'saturn',
    'jupiter',
    'nebula',
    'galaxy',
    'spacecraft',
    'astronaut',
    'hubble',
    'apollo',
    'space station',
    'solar',
    'planet',
    'asteroid',
    'comet',
    'telescope',
    'rocket',
    'mission',
    'universe'
  ];

  static Future<NasaMediaCollection> searchMedia({
    String? query,
    List<String>? mediaTypes,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query ?? _getRandomSearchTerm(),
          if (mediaTypes != null && mediaTypes.isNotEmpty)
            'media_type': mediaTypes.join(','),
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NasaMediaCollection.fromJson(jsonData);
      } else {
        throw Exception('Failed to load NASA media: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching NASA media: $e');
    }
  }

  static Future<NasaMediaCollection> getRandomMixedMedia({
    int pageSize = 20,
  }) async {
    try {
      // Get a random search term
      final searchTerm = _getRandomSearchTerm();
      
      // Fetch mixed media types
      return await searchMedia(
        query: searchTerm,
        mediaTypes: ['image', 'video', 'audio'],
        pageSize: pageSize,
      );
    } catch (e) {
      throw Exception('Error fetching random mixed media: $e');
    }
  }

  static Future<List<String>> getAssetUrls(String nasaId) async {
    try {
      final uri = Uri.parse('$_baseUrl/asset/$nasaId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final collection = jsonData['collection'] as Map<String, dynamic>;
        final items = collection['items'] as List;
        
        return items.map((item) => item['href'] as String).toList();
      } else {
        throw Exception('Failed to load asset URLs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching asset URLs: $e');
    }
  }

  static Future<Map<String, dynamic>> getMetadata(String nasaId) async {
    try {
      final uri = Uri.parse('$_baseUrl/metadata/$nasaId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception('Failed to load metadata: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching metadata: $e');
    }
  }

  static String _getRandomSearchTerm() {
    final random = Random();
    return _searchTerms[random.nextInt(_searchTerms.length)];
  }

  // Search for specific media types
  static Future<NasaMediaCollection> getImages({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    return searchMedia(
      query: query,
      mediaTypes: ['image'],
      page: page,
      pageSize: pageSize,
    );
  }

  static Future<NasaMediaCollection> getVideos({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    return searchMedia(
      query: query,
      mediaTypes: ['video'],
      page: page,
      pageSize: pageSize,
    );
  }

  static Future<NasaMediaCollection> getAudio({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    return searchMedia(
      query: query,
      mediaTypes: ['audio'],
      page: page,
      pageSize: pageSize,
    );
  }
}