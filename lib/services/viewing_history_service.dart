// lib/services/viewing_history_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cosmic_explorer/models/nasa_media.dart';

class ViewingHistoryService {
  static const String _historyKey = 'viewing_history';
  static const int _maxHistoryItems = 100;

  static Future<void> addToHistory(NasaMediaItem mediaItem) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      
      // Remove existing item if it exists (to avoid duplicates)
      history.removeWhere((item) => item.nasaId == mediaItem.nasaId);
      
      // Add the new item at the beginning with current timestamp
      history.insert(0, mediaItem.copyWithViewed());
      
      // Keep only the most recent items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }
      
      // Save to preferences
      final jsonList = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  static Future<List<NasaMediaItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) return [];
      
      final List<dynamic> jsonList = json.decode(historyJson);
      return jsonList
          .map((json) => NasaMediaItem.fromStoredJson(json))
          .toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  static Future<void> removeFromHistory(String nasaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      
      history.removeWhere((item) => item.nasaId == nasaId);
      
      final jsonList = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, json.encode(jsonList));
    } catch (e) {
      print('Error removing from history: $e');
    }
  }

  static Future<bool> isInHistory(String nasaId) async {
    try {
      final history = await getHistory();
      return history.any((item) => item.nasaId == nasaId);
    } catch (e) {
      print('Error checking history: $e');
      return false;
    }
  }
}