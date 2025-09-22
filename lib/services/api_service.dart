import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../models/item.dart';
import '../models/purchase.dart';
import '../models/event.dart';
import 'cache_service.dart';

class ApiService {
  static const String _baseUrl = 'https://api.thelivingroomloja21.com/api';
  late final Dio _dio;
  String? _authToken;
  Function()? _onUnauthorized;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Log the 401 error with endpoint details
          final endpoint = error.requestOptions.path;
          debugPrint('401 auth failure in call to /api$endpoint');
          
          // Don't trigger unauthorized callback for login/authentication endpoints
          // as these are expected to return 401 for invalid credentials
          if (!endpoint.contains('/auth/authenticate') && 
              !endpoint.contains('/auth/authenticate-biometric')) {
            // Clear token
            _authToken = null;
            
            // Call the unauthorized callback if set
            _onUnauthorized?.call();
          }
        }
        handler.next(error);
      },
    ));
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  void setOnUnauthorizedCallback(Function() callback) {
    _onUnauthorized = callback;
  }

  // Auth API
  Future<AuthResponse> login(String username, String password) async {
    debugPrint('🌐 ApiService: Making login request to /auth/authenticate');
    debugPrint('🌐 ApiService: Base URL: $_baseUrl');
    debugPrint('🌐 ApiService: Username: $username');
    
    final response = await _dio.post('/auth/authenticate', data: {
      'username': username,
      'password': password,
    });
    
    debugPrint('🌐 ApiService: Response status: ${response.statusCode}');
    debugPrint('🌐 ApiService: Response data: ${response.data}');
    debugPrint('🌐 ApiService: Response data type: ${response.data.runtimeType}');
    
    // Check if response is successful
    if (response.statusCode == 200) {
      debugPrint('🌐 ApiService: Login successful, parsing response...');
      try {
        final authResponse = AuthResponse.fromJson(response.data);
        debugPrint('🌐 ApiService: Parsed AuthResponse - success: ${authResponse.success}, message: ${authResponse.message}');
        return authResponse;
      } catch (e) {
        debugPrint('🌐 ApiService: Error parsing AuthResponse: $e');
        debugPrint('🌐 ApiService: Raw response data: ${response.data}');
        rethrow;
      }
    } else {
      debugPrint('🌐 ApiService: Login failed with status: ${response.statusCode}');
      throw Exception('Login failed with status: ${response.statusCode}');
    }
  }

  Future<BiometricEnrollmentResponse> initiateBiometricEnrollment(String email, String password) async {
    final response = await _dio.post('/auth/initiate-biometric-enrollment', data: {
      'email': email,
      'password': password,
    });
    return BiometricEnrollmentResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> completeBiometricEnrollment({
    required String email,
    required String enrollmentToken,
    required String biometricHash,
    required String deviceId,
    required String platform,
  }) async {
    final response = await _dio.post('/auth/complete-biometric-enrollment', data: {
      'email': email,
      'enrollmentToken': enrollmentToken,
      'biometricHash': biometricHash,
      'deviceId': deviceId,
      'platform': platform,
    });
    return response.data;
  }

  Future<AuthResponse> authenticateWithBiometric({
    required String email,
    required String enrollmentToken,
    required String deviceId,
    required String platform,
  }) async {
    debugPrint('ApiService: Authenticating with biometric - email: $email, enrollmentToken: $enrollmentToken, deviceId: $deviceId, platform: $platform');
    final response = await _dio.post('/auth/authenticate-biometric', data: {
      'email': email,
      'enrollmentToken': enrollmentToken,
      'deviceId': deviceId,
      'platform': platform,
    });
    debugPrint('ApiService: Biometric authentication response: ${response.data}');
    return AuthResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> revokeBiometricEnrollment({
    required String email,
    required String enrollmentToken,
    required String deviceId,
    required String platform,
  }) async {
    final response = await _dio.post('/auth/revoke-biometric-enrollment', data: {
      'email': email,
      'enrollmentToken': enrollmentToken,
      'deviceId': deviceId,
      'platform': platform,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> enableBiometric(String email) async {
    final response = await _dio.post('/auth/enable-biometric', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> disableBiometric(String email) async {
    final response = await _dio.post('/auth/disable-biometric', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> listBiometricEnrollments(String email) async {
    final response = await _dio.get('/auth/biometric-enrollments', queryParameters: {
      'email': email,
    });
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
    clearAuthToken();
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post('/auth/forgot-password', data: {
      'email': email,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> changePassword(String token, String newPassword) async {
    final response = await _dio.post('/auth/change_password', data: {
      'token': token,
      'password': newPassword,
    });
    return response.data;
  }

  // Users API
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return User.fromJson(response.data['data']);
  }

  Future<User> getUserById(int userId) async {
    final response = await _dio.get('/users/$userId');
    return User.fromJson(response.data['data']);
  }

  Future<User> getUserByEmail(String email) async {
    final response = await _dio.get('/users/$email');
    return User.fromJson(response.data['data']);
  }

  Future<User> updateUser(String email, Map<String, dynamic> userData) async {
    final response = await _dio.put('/users/$email', data: userData);
    return User.fromJson(response.data['data']);
  }

  // Items API
  Future<List<Item>> getItems({bool inStockOnly = false}) async {
    final queryParams = <String, dynamic>{};
    if (inStockOnly) {
      queryParams['inStock'] = 'true';
    }
    
    final response = await _dio.get('/items', queryParameters: queryParams);
    final List<dynamic> itemsJson = response.data['data'];
    return itemsJson.map((json) => Item.fromJson(json)).toList();
  }

  Future<List<Item>> getAlcoholItems() async {
    final response = await _dio.get('/items', queryParameters: {'is_alcohol': 'true'});
    final List<dynamic> itemsJson = response.data['data'];
    return itemsJson.map((json) => Item.fromJson(json)).toList();
  }

  Future<Item> getItem(int id) async {
    try {
      final response = await _dio.get('/items/$id');
      return Item.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('ApiService: Error getting item $id: $e');
      rethrow;
    }
  }

  Future<Item> getItemByBarcode(String barcode) async {
    try {
      debugPrint('ApiService: Getting item by barcode: $barcode');
      final response = await _dio.get('/items/barcode/${Uri.encodeComponent(barcode)}');
      debugPrint('ApiService: Barcode response: ${response.data}');
      
      Item item;
      // Handle different response formats
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('data')) {
          item = Item.fromJson(data['data']);
        } else {
          // Direct item response
          item = Item.fromJson(data);
        }
      } else {
        throw Exception('Unexpected response format: ${response.data.runtimeType}');
      }
      
      // Update cache with the new item
      debugPrint('ApiService: Updating cache with item from barcode: ${item.name} (ID: ${item.id})');
      final cachedItems = await CacheService.getCachedItems() ?? <Item>[];
      final updatedItems = List<Item>.from(cachedItems);
      
      // Remove existing item with same ID if it exists
      updatedItems.removeWhere((cachedItem) => cachedItem.id == item.id);
      // Add the new item
      updatedItems.add(item);
      
      await CacheService.setCachedItems(updatedItems);
      debugPrint('ApiService: Cache updated with ${updatedItems.length} items');
      
      return item;
    } catch (e) {
      debugPrint('ApiService: Error getting item by barcode $barcode: $e');
      
      // Check if this is a DioException with 404 status
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Item not found for barcode: $barcode');
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> incrementOnHand(int id) async {
    try {
      final response = await _dio.patch('/items/$id/increment-on-hand');
      return response.data['data'];
    } catch (e) {
      debugPrint('ApiService: Error incrementing on hand for item $id: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTastingNotes(int id) async {
    final response = await _dio.get('/items/$id/tasting-notes');
    final data = response.data['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createTastingNote(int itemId, String notes) async {
    await _dio.post('/tasting-notes', data: {
      'item_id': itemId,
      'notes': notes,
    });
  }

  Future<void> updateTastingNote(int noteId, String notes) async {
    await _dio.put('/tasting-notes/$noteId', data: {
      'notes': notes,
    });
  }

  Future<void> deleteTastingNote(int noteId) async {
    await _dio.delete('/tasting-notes/$noteId');
  }

  Future<Map<String, dynamic>> fetchTastingNotes(int id, {Map<String, dynamic>? wineDetails}) async {
    try {
      debugPrint('ApiService: Fetching tasting notes for item $id with details: $wineDetails');
      final response = await _dio.post('/tasting-notes/fetch/$id', data: wineDetails ?? {});
      debugPrint('ApiService: Fetch tasting notes response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('ApiService: Error fetching tasting notes for item $id: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> makeLabelImage(int id, {String? mode}) async {
    final queryParams = <String, dynamic>{};
    if (mode != null) {
      queryParams['mode'] = mode;
    }
    
    final response = await _dio.post('/items/$id/make-label', queryParameters: queryParams);
    return response.data;
  }

  Future<Item> updateItem(int id, Map<String, dynamic> updates) async {
    final response = await _dio.put('/items/$id', data: updates);
    return Item.fromJson(response.data['data']);
  }

  // Purchases API
  Future<List<Purchase>> getUserPurchases() async {
    final response = await _dio.get('/purchases');
    final List<dynamic> purchasesJson = response.data['data'];
    return purchasesJson.map((json) => Purchase.fromJson(json)).toList();
  }

  Future<Purchase> createPurchase({
    required String userEmail,
    required int itemId,
    required double priceAsked,
    required double pricePaid,
    String? purchasedOn,
    String? barcode,
  }) async {
    final data = {
      'user_email': userEmail,
      'item_id': itemId,
      'price_asked': priceAsked,
      'price_paid': pricePaid,
      'purchased_on': purchasedOn ?? DateTime.now().toIso8601String(),
      if (barcode != null) 'barcode': barcode,
    };
    
    final response = await _dio.post('/purchases', data: data);
    return Purchase.fromJson(response.data['data']);
  }

  Future<double> getOutstandingBalance() async {
    final response = await _dio.get('/purchases/mybalance');
    return response.data['data']['balance'].toDouble();
  }

  Future<Purchase?> getLastPurchase() async {
    final response = await _dio.get('/purchases', queryParameters: {'limit': 1});
    final List<dynamic> purchasesJson = response.data['data'];
    if (purchasesJson.isNotEmpty) {
      return Purchase.fromJson(purchasesJson.first);
    }
    return null;
  }

  Future<int> getMyPurchaseCountForItem(int itemId) async {
    final response = await _dio.get('/purchases', queryParameters: {
      'itemId': itemId,
      'limit': 1,
    });
    return response.data['pagination']['total'] ?? 0;
  }

  // Events API
  Future<List<Event>> getUpcomingEvents() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // Prepare headers for conditional request
      final headers = <String, String>{};
      final lastModified = await CacheService.getLastModified();
      if (lastModified != null) {
        headers['If-Modified-Since'] = lastModified;
      }
      
      final response = await _dio.get('/events', 
        queryParameters: {
          'starting_at[gte]': now,
          'sort': 'starting_at:asc',
        },
        options: Options(headers: headers),
      );
      
      final data = response.data['data'];
      
      if (data is List) {
        final events = data.map((json) => Event.fromJson(json)).toList();
        
        // Cache the events with response headers
        final lastModifiedHeader = response.headers.value('last-modified');
        final etagHeader = response.headers.value('etag');
        await CacheService.setCachedEvents(events, 
          lastModified: lastModifiedHeader, 
          etag: etagHeader
        );
        
        return events;
      } else {
        debugPrint('ApiService: Unexpected data format for events: ${data.runtimeType}');
        return [];
      }
    } catch (e) {
      debugPrint('ApiService: Error getting upcoming events: $e');
      rethrow;
    }
  }

  Future<List<Event>> getAllEvents() async {
    try {
      // Prepare headers for conditional request
      final headers = <String, String>{};
      final lastModified = await CacheService.getLastModified();
      if (lastModified != null) {
        headers['If-Modified-Since'] = lastModified;
      }
      
      final response = await _dio.get('/events', options: Options(headers: headers));
      final List<dynamic> eventsJson = response.data['data'];
      final events = eventsJson.map((json) => Event.fromJson(json)).toList();
      
      // Cache the events with response headers
      final lastModifiedHeader = response.headers.value('last-modified');
      final etagHeader = response.headers.value('etag');
      await CacheService.setCachedEvents(events, 
        lastModified: lastModifiedHeader, 
        etag: etagHeader
      );
      
      return events;
    } catch (e) {
      debugPrint('ApiService: Error getting all events: $e');
      rethrow;
    }
  }

  Future<Event> getEvent(int id) async {
    final response = await _dio.get('/events/$id');
    return Event.fromJson(response.data['data']);
  }

  Future<EventAttendance?> getMyAttendance(int eventId) async {
    try {
      final response = await _dio.get('/events/$eventId/attendance/my');
      return EventAttendance.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }

  Future<EventAttendance> upsertMyAttendance(int eventId, AttendanceStatus status) async {
    final response = await _dio.post('/events/$eventId/attendance', data: {
      'status': status.name,
    });
    return EventAttendance.fromJson(response.data['data']);
  }

  // Device info helper
  Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String platform;
    String deviceId;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      platform = 'android';
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      platform = 'ios';
      deviceId = iosInfo.identifierForVendor ?? 'unknown';
    } else {
      platform = 'unknown';
      deviceId = 'unknown';
    }

    return {
      'platform': platform,
      'deviceId': deviceId,
    };
  }

  // Items API - Additional methods
  Future<List<Item>> getAllItems({bool inStockOnly = false}) async {
    try {
      final queryParams = inStockOnly ? '?inStock=true' : '';
      final response = await _dio.get('/items$queryParams');
      final List<dynamic> itemsJson = response.data['data'] ?? [];
      return itemsJson.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      debugPrint('ApiService: Error getting all items: $e');
      rethrow;
    }
  }

  // Item Properties API
  Future<List<Map<String, dynamic>>> getItemProperties(int itemId) async {
    try {
      final response = await _dio.get('/item-properties?item_id=$itemId');
      final List<dynamic> propertiesJson = response.data['data'] ?? [];
      return propertiesJson.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ApiService: Error getting item properties for $itemId: $e');
      rethrow;
    }
  }

  Future<Map<int, List<Map<String, dynamic>>>> getAllItemProperties() async {
    try {
      final response = await _dio.get('/item-properties');
      final List<dynamic> propertiesJson = response.data['data'] ?? [];
      
      final Map<int, List<Map<String, dynamic>>> result = {};
      for (final prop in propertiesJson) {
        final itemId = prop['item_id'] as int;
        if (!result.containsKey(itemId)) {
          result[itemId] = [];
        }
        result[itemId]!.add(prop);
      }
      
      return result;
    } catch (e) {
      debugPrint('ApiService: Error getting all item properties: $e');
      rethrow;
    }
  }

  // Wine Learning API (for label images)
  Future<String?> getWineLabelImage(int itemId) async {
    try {
      debugPrint('ApiService: Getting label image for item $itemId using new endpoint');
      
      // Use the new direct label image endpoint
      final response = await _dio.get('/wine-learning/label-image/$itemId');
      
      // The new endpoint returns JSON with base64 data
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as String;
        }
      } else if (response.data is String) {
        // Fallback for direct string response
        return response.data;
      } else if (response.data is List<int>) {
        // If it's binary data, convert to base64
        return base64Encode(response.data);
      }
      
      return null;
    } catch (e) {
      debugPrint('ApiService: Error getting wine label image for $itemId: $e');
      
      // Fallback to the old method if the new endpoint fails
      try {
        debugPrint('ApiService: Falling back to old wine-images endpoint for item $itemId');
        final response = await _dio.get('/wine-learning/wine-images/$itemId');
        final data = response.data['data'] as List<dynamic>?;
        if (data != null && data.isNotEmpty) {
          // Look for label image first, then front image
          for (final image in data) {
            if (image['image_type'] == 'label') {
              return image['image_data'] as String?;
            }
          }
          for (final image in data) {
            if (image['image_type'] == 'front') {
              return image['image_data'] as String?;
            }
          }
          // If no specific type, return the first image
          return data.first['image_data'] as String?;
        }
      } catch (fallbackError) {
        debugPrint('ApiService: Fallback also failed for item $itemId: $fallbackError');
      }
      
      return null;
    }
  }

  // Generate label image from front image (admin only)
  Future<String?> generateLabelImage(int itemId) async {
    try {
      final response = await _dio.post('/items/$itemId/make-label');
      final data = response.data['data'];
      if (data is String) {
        return data;
      } else if (data is Map<String, dynamic>) {
        return data['image_data'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService: Error generating label image for $itemId: $e');
      return null;
    }
  }

  // Wine Learning API
  Future<Map<String, dynamic>> learnWineFromImages({
    required String frontImage,
    String? backImage,
    String? scannedBarcode,
  }) async {
    try {
      debugPrint('ApiService: Learning wine from images with barcode: $scannedBarcode');
      
      final requestData = <String, dynamic>{
        'frontImage': frontImage,
      };
      
      if (backImage != null) {
        requestData['backImage'] = backImage;
      }
      
      if (scannedBarcode != null) {
        requestData['scannedBarcode'] = scannedBarcode;
      }
      
      final response = await _dio.post('/wine-learning/learn-wine', data: requestData);
      debugPrint('ApiService: Wine learning response: ${response.data}');
      return response.data;
    } catch (e) {
      debugPrint('ApiService: Error learning wine from images: $e');
      rethrow;
    }
  }

  // Prefetch API
  Future<Map<String, dynamic>> getPrefetchData({Map<String, String>? headers}) async {
    try {
      debugPrint('ApiService: Fetching prefetch data with headers: $headers');
      final response = await _dio.get('/prefetch/items', options: Options(headers: headers));
      
      final data = response.data['data'] as Map<String, dynamic>;
      final lastModified = response.headers.value('last-modified');
      final etag = response.headers.value('etag');
      
      debugPrint('ApiService: Prefetch data received - items: ${data['items']?.length ?? 0}, properties: ${data['properties']?.length ?? 0}, labels: ${data['labels']?.length ?? 0}');
      
      return {
        'data': data,
        'lastModified': lastModified,
        'etag': etag,
      };
    } catch (e) {
      debugPrint('ApiService: Error getting prefetch data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPrefetchStats() async {
    try {
      final response = await _dio.get('/prefetch/items/stats');
      return response.data['data'];
    } catch (e) {
      debugPrint('ApiService: Error getting prefetch stats: $e');
      rethrow;
    }
  }

  // Dashboard API methods
  Future<double> getUserBalance() async {
    try {
      final response = await _dio.get('/purchases/mybalance');
      final data = response.data['data'];
      
      // Handle different possible data types
      if (data is num) {
        return data.toDouble();
      } else if (data is String) {
        return double.tryParse(data) ?? 0.0;
      } else if (data is Map<String, dynamic>) {
        // If it's a map, look for common balance field names
        final balance = data['balance'] ?? data['amount'] ?? data['total'] ?? 0.0;
        if (balance is num) {
          return balance.toDouble();
        } else if (balance is String) {
          return double.tryParse(balance) ?? 0.0;
        }
      }
      
      return 0.0;
    } catch (e) {
      debugPrint('ApiService: Error getting user balance: $e');
      rethrow;
    }
  }

  Future<List<Purchase>> getRecentPurchases({int limit = 5}) async {
    try {
      final response = await _dio.get('/purchases', queryParameters: {
        'limit': limit,
      });
      final data = response.data['data'];
      
      if (data is List) {
        return data.map((json) => Purchase.fromJson(json)).toList();
      } else {
        debugPrint('ApiService: Unexpected data format for purchases: ${data.runtimeType}');
        return [];
      }
    } catch (e) {
      debugPrint('ApiService: Error getting recent purchases: $e');
      rethrow;
    }
  }

}
