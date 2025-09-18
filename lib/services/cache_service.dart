import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/event.dart';

/// Cache service for managing data persistence and retrieval
class CacheService {
  static const String _itemsKey = 'cache_items';
  static const String _itemPropertiesKey = 'cache_item_properties';
  static const String _itemImagesKey = 'cache_item_images';
  static const String _eventsKey = 'cache_events';
  static const String _prefetchDataKey = 'cache_prefetch_data';
  static const String _lastModifiedKey = 'cache_last_modified';
  
  static const int _defaultTtlMs = 5 * 60 * 1000; // 5 minutes

  /// Cache entry with metadata
  static Map<String, dynamic> _createCacheEntry<T>(T data, {String? lastModified, String? etag}) {
    return {
      'data': data,
      'storedAt': DateTime.now().millisecondsSinceEpoch,
      'lastModified': lastModified,
      'etag': etag,
    };
  }

  /// Check if cache entry is expired
  static bool _isExpired(Map<String, dynamic> entry, int ttlMs) {
    final storedAt = entry['storedAt'] as int? ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - storedAt) > ttlMs;
  }

  /// Get cached items
  static Future<List<Item>?> getCachedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_itemsKey);
      if (cached == null) return null;

      final entry = jsonDecode(cached) as Map<String, dynamic>;
      if (_isExpired(entry, _defaultTtlMs)) {
        await clearItemsCache();
        return null;
      }

      final itemsJson = entry['data'] as List<dynamic>;
      return itemsJson.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      debugPrint('CacheService: Error getting cached items: $e');
      return null;
    }
  }

  /// Set cached items
  static Future<void> setCachedItems(List<Item> items, {String? lastModified, String? etag}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = _createCacheEntry(items, lastModified: lastModified, etag: etag);
      await prefs.setString(_itemsKey, jsonEncode(entry));
      debugPrint('CacheService: Cached ${items.length} items');
    } catch (e) {
      debugPrint('CacheService: Error setting cached items: $e');
    }
  }

  /// Get cached item properties
  static Future<Map<int, List<Map<String, dynamic>>>?> getCachedItemProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_itemPropertiesKey);
      if (cached == null) return null;

      final entry = jsonDecode(cached) as Map<String, dynamic>;
      if (_isExpired(entry, _defaultTtlMs)) {
        await clearItemPropertiesCache();
        return null;
      }

      final propertiesJson = entry['data'] as Map<String, dynamic>;
      final result = <int, List<Map<String, dynamic>>>{};
      
      propertiesJson.forEach((key, value) {
        final itemId = int.tryParse(key);
        if (itemId != null && value is List) {
          result[itemId] = value.cast<Map<String, dynamic>>();
        }
      });

      return result;
    } catch (e) {
      debugPrint('CacheService: Error getting cached item properties: $e');
      return null;
    }
  }

  /// Set cached item properties
  static Future<void> setCachedItemProperties(Map<int, List<Map<String, dynamic>>> properties, {String? lastModified, String? etag}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert int keys to string keys for JSON serialization
      final serializableProperties = <String, List<Map<String, dynamic>>>{};
      properties.forEach((key, value) {
        serializableProperties[key.toString()] = value;
      });
      
      final entry = _createCacheEntry(serializableProperties, lastModified: lastModified, etag: etag);
      await prefs.setString(_itemPropertiesKey, jsonEncode(entry));
      debugPrint('CacheService: Cached properties for ${properties.length} items');
    } catch (e) {
      debugPrint('CacheService: Error setting cached item properties: $e');
    }
  }

  /// Get cached item images
  static Future<Map<int, String>?> getCachedItemImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_itemImagesKey);
      if (cached == null) return null;

      final entry = jsonDecode(cached) as Map<String, dynamic>;
      if (_isExpired(entry, _defaultTtlMs)) {
        await clearItemImagesCache();
        return null;
      }

      final imagesJson = entry['data'] as Map<String, dynamic>;
      final result = <int, String>{};
      
      imagesJson.forEach((key, value) {
        final itemId = int.tryParse(key);
        if (itemId != null && value is String) {
          result[itemId] = value;
        }
      });

      return result;
    } catch (e) {
      debugPrint('CacheService: Error getting cached item images: $e');
      return null;
    }
  }

  /// Set cached item images
  static Future<void> setCachedItemImages(Map<int, String> images, {String? lastModified, String? etag}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert int keys to string keys for JSON serialization
      final serializableImages = <String, String>{};
      images.forEach((key, value) {
        serializableImages[key.toString()] = value;
      });
      
      final entry = _createCacheEntry(serializableImages, lastModified: lastModified, etag: etag);
      await prefs.setString(_itemImagesKey, jsonEncode(entry));
      debugPrint('CacheService: Cached images for ${images.length} items');
    } catch (e) {
      debugPrint('CacheService: Error setting cached item images: $e');
    }
  }

  /// Get cached events
  static Future<List<Event>?> getCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_eventsKey);
      if (cached == null) return null;

      final entry = jsonDecode(cached) as Map<String, dynamic>;
      if (_isExpired(entry, _defaultTtlMs)) {
        await clearEventsCache();
        return null;
      }

      final eventsJson = entry['data'] as List<dynamic>;
      return eventsJson.map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('CacheService: Error getting cached events: $e');
      return null;
    }
  }

  /// Set cached events
  static Future<void> setCachedEvents(List<Event> events, {String? lastModified, String? etag}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = _createCacheEntry(events, lastModified: lastModified, etag: etag);
      await prefs.setString(_eventsKey, jsonEncode(entry));
      debugPrint('CacheService: Cached ${events.length} events');
    } catch (e) {
      debugPrint('CacheService: Error setting cached events: $e');
    }
  }

  /// Get cached prefetch data
  static Future<Map<String, dynamic>?> getCachedPrefetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefetchDataKey);
      if (cached == null) return null;

      final entry = jsonDecode(cached) as Map<String, dynamic>;
      if (_isExpired(entry, _defaultTtlMs)) {
        await clearPrefetchCache();
        return null;
      }

      return entry['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('CacheService: Error getting cached prefetch data: $e');
      return null;
    }
  }

  /// Set cached prefetch data
  static Future<void> setCachedPrefetchData(Map<String, dynamic> data, {String? lastModified, String? etag}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = _createCacheEntry(data, lastModified: lastModified, etag: etag);
      await prefs.setString(_prefetchDataKey, jsonEncode(entry));
      debugPrint('CacheService: Cached prefetch data');
    } catch (e) {
      debugPrint('CacheService: Error setting cached prefetch data: $e');
    }
  }

  /// Get last modified timestamp
  static Future<String?> getLastModified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastModifiedKey);
    } catch (e) {
      debugPrint('CacheService: Error getting last modified: $e');
      return null;
    }
  }

  /// Set last modified timestamp
  static Future<void> setLastModified(String lastModified) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastModifiedKey, lastModified);
    } catch (e) {
      debugPrint('CacheService: Error setting last modified: $e');
    }
  }

  /// Clear items cache
  static Future<void> clearItemsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_itemsKey);
      debugPrint('CacheService: Cleared items cache');
    } catch (e) {
      debugPrint('CacheService: Error clearing items cache: $e');
    }
  }

  /// Clear item properties cache
  static Future<void> clearItemPropertiesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_itemPropertiesKey);
      debugPrint('CacheService: Cleared item properties cache');
    } catch (e) {
      debugPrint('CacheService: Error clearing item properties cache: $e');
    }
  }

  /// Clear item images cache
  static Future<void> clearItemImagesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_itemImagesKey);
      debugPrint('CacheService: Cleared item images cache');
    } catch (e) {
      debugPrint('CacheService: Error clearing item images cache: $e');
    }
  }

  /// Clear events cache
  static Future<void> clearEventsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_eventsKey);
      debugPrint('CacheService: Cleared events cache');
    } catch (e) {
      debugPrint('CacheService: Error clearing events cache: $e');
    }
  }

  /// Clear prefetch cache
  static Future<void> clearPrefetchCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefetchDataKey);
      debugPrint('CacheService: Cleared prefetch cache');
    } catch (e) {
      debugPrint('CacheService: Error clearing prefetch cache: $e');
    }
  }

  /// Individual image caching methods
  static Future<String?> getCachedImage(int itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_itemImagesKey}_$itemId');
      if (cached == null) return null;

      final entry = jsonDecode(cached) as Map<String, dynamic>;
      if (_isExpired(entry, _defaultTtlMs)) {
        await prefs.remove('${_itemImagesKey}_$itemId');
        return null;
      }

      return entry['data'] as String;
    } catch (e) {
      debugPrint('CacheService: Error getting cached image for $itemId: $e');
      return null;
    }
  }

  static Future<void> setCachedImage(int itemId, String imageData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = _createCacheEntry(imageData);
      await prefs.setString('${_itemImagesKey}_$itemId', jsonEncode(entry));
      debugPrint('CacheService: Cached image for item $itemId');
    } catch (e) {
      debugPrint('CacheService: Error setting cached image for $itemId: $e');
    }
  }

  static Future<void> clearImageCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final imageKeys = keys.where((key) => key.startsWith('${_itemImagesKey}_')).toList();
      await Future.wait(imageKeys.map((key) => prefs.remove(key)));
      debugPrint('CacheService: Cleared image cache');
    } catch (e) {
      debugPrint('CacheService: Error clearing image cache: $e');
    }
  }

  /// Clear all caches
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_itemsKey),
        prefs.remove(_itemPropertiesKey),
        prefs.remove(_itemImagesKey),
        prefs.remove(_eventsKey),
        prefs.remove(_prefetchDataKey),
        prefs.remove(_lastModifiedKey),
      ]);
      // Also clear individual image caches
      await clearImageCache();
      debugPrint('CacheService: Cleared all caches');
    } catch (e) {
      debugPrint('CacheService: Error clearing all caches: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int totalSize = 0;
      int itemCount = 0;
      int propertyCount = 0;
      int imageCount = 0;
      int eventCount = 0;
      
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length;
            
            if (key == _itemsKey) {
              try {
                final entry = jsonDecode(value) as Map<String, dynamic>;
                final items = entry['data'] as List<dynamic>?;
                itemCount = items?.length ?? 0;
              } catch (e) {
                // Ignore parsing errors
              }
            } else if (key == _itemPropertiesKey) {
              try {
                final entry = jsonDecode(value) as Map<String, dynamic>;
                final properties = entry['data'] as Map<String, dynamic>?;
                propertyCount = properties?.length ?? 0;
              } catch (e) {
                // Ignore parsing errors
              }
            } else if (key == _itemImagesKey) {
              try {
                final entry = jsonDecode(value) as Map<String, dynamic>;
                final images = entry['data'] as Map<String, dynamic>?;
                imageCount = images?.length ?? 0;
              } catch (e) {
                // Ignore parsing errors
              }
            } else if (key == _eventsKey) {
              try {
                final entry = jsonDecode(value) as Map<String, dynamic>;
                final events = entry['data'] as List<dynamic>?;
                eventCount = events?.length ?? 0;
              } catch (e) {
                // Ignore parsing errors
              }
            }
          }
        }
      }
      
      return {
        'totalSize': totalSize,
        'itemCount': itemCount,
        'propertyCount': propertyCount,
        'imageCount': imageCount,
        'eventCount': eventCount,
        'lastModified': await getLastModified(),
      };
    } catch (e) {
      debugPrint('CacheService: Error getting cache stats: $e');
      return {
        'totalSize': 0,
        'itemCount': 0,
        'propertyCount': 0,
        'imageCount': 0,
        'eventCount': 0,
        'lastModified': null,
      };
    }
  }
}
