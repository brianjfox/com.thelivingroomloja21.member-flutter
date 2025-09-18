import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'cache_service.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ApiService _apiService = ApiService();
  final Map<int, String> _imageCache = {};
  final Set<int> _loadingItems = {};

  /// Get image for an item, checking cache first, then fetching if needed
  Future<String?> getImageForItem(int itemId) async {
    // Check memory cache first
    if (_imageCache.containsKey(itemId)) {
      debugPrint('ImageService: Found image in memory cache for item $itemId');
      return _imageCache[itemId];
    }

    // Check persistent cache
    final cachedImage = await CacheService.getCachedImage(itemId);
    if (cachedImage != null) {
      debugPrint('ImageService: Found image in persistent cache for item $itemId');
      _imageCache[itemId] = cachedImage;
      return cachedImage;
    }

    // If not loading already, start background fetch
    if (!_loadingItems.contains(itemId)) {
      _fetchImageInBackground(itemId);
    }

    return null;
  }

  /// Fetch image in background and update cache
  Future<void> _fetchImageInBackground(int itemId) async {
    if (_loadingItems.contains(itemId)) return;
    
    _loadingItems.add(itemId);
    debugPrint('ImageService: Starting background fetch for item $itemId');

    try {
      final imageData = await _apiService.getWineLabelImage(itemId);
      if (imageData != null && _isValidImageData(imageData)) {
        // Update memory cache
        _imageCache[itemId] = imageData;
        
        // Update persistent cache
        await CacheService.setCachedImage(itemId, imageData);
        
        debugPrint('ImageService: Successfully cached image for item $itemId');
      } else {
        debugPrint('ImageService: Invalid image data for item $itemId');
      }
    } catch (e) {
      debugPrint('ImageService: Error fetching image for item $itemId: $e');
    } finally {
      _loadingItems.remove(itemId);
    }
  }

  /// Preload images for multiple items in background
  Future<void> preloadImages(List<int> itemIds) async {
    debugPrint('ImageService: Preloading images for ${itemIds.length} items');
    
    // Process in batches to avoid overwhelming the system
    const batchSize = 3;
    for (int i = 0; i < itemIds.length; i += batchSize) {
      final batch = itemIds.skip(i).take(batchSize).toList();
      await Future.wait(batch.map((itemId) => _fetchImageInBackground(itemId)));
      
      // Small delay between batches
      if (i + batchSize < itemIds.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    debugPrint('ImageService: Completed preloading images');
  }

  /// Check if image is currently loading
  bool isImageLoading(int itemId) {
    return _loadingItems.contains(itemId);
  }

  /// Check if image is cached (memory or persistent)
  Future<bool> isImageCached(int itemId) async {
    if (_imageCache.containsKey(itemId)) return true;
    final cachedImage = await CacheService.getCachedImage(itemId);
    return cachedImage != null;
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _imageCache.clear();
    debugPrint('ImageService: Cleared memory cache');
  }

  /// Clear all caches (memory and persistent)
  Future<void> clearAllCaches() async {
    _imageCache.clear();
    await CacheService.clearImageCache();
    debugPrint('ImageService: Cleared all caches');
  }

  /// Validate image data
  bool _isValidImageData(String imageData) {
    try {
      if (imageData.isEmpty) return false;
      
      // Try to decode the base64 data
      final bytes = base64Decode(imageData);
      if (bytes.isEmpty) return false;
      
      // Check if it looks like image data (basic validation)
      if (bytes.length < 100) return false; // Too small to be a real image
      
      return true;
    } catch (e) {
      debugPrint('ImageService: Image validation error: $e');
      return false;
    }
  }

  /// Build image widget with error handling
  Widget buildImageWidget(String imageData, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
    try {
      // Try to decode the base64 data
      final bytes = base64Decode(imageData);
      
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ImageService: Image display error: $error');
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[400],
                size: width != null ? width * 0.5 : 32,
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('ImageService: Image decoding error: $e');
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.broken_image,
            color: Colors.grey[400],
            size: width != null ? width * 0.5 : 32,
          ),
        ),
      );
    }
  }

  /// Build image widget for item with fallback
  Widget buildItemImageWidget(int itemId, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
    final imageData = _imageCache[itemId];
    
    if (imageData != null) {
      return buildImageWidget(imageData, width: width, height: height, fit: fit);
    }
    
    // Show loading indicator if currently loading
    if (_loadingItems.contains(itemId)) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[100],
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ),
      );
    }
    
    // Show placeholder if no image
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.wine_bar,
          color: Colors.grey[400],
          size: width != null ? width * 0.5 : 32,
        ),
      ),
    );
  }
}
