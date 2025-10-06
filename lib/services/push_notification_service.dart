import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../firebase_options.dart';
import 'api_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static bool _isInitialized = false;

  /// Initialize Firebase and push notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if Firebase is already initialized
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase initialized for push notifications');
      } catch (e) {
        debugPrint('❌ Firebase already initialized or failed: $e');
        // Continue anyway - Firebase might already be initialized
      }
      
      // Request notification permissions
      await _requestPermissions();
      
      // Get FCM token
      await _getFCMToken();
      
      // Set up message handlers
      _setupMessageHandlers();
      
      _isInitialized = true;
      debugPrint('✅ Push notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing push notification service: $e');
      debugPrint('⚠️  Push notifications will not be available');
      // Don't rethrow - let the app continue without push notifications
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // Request iOS notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('iOS notification permission status: ${settings.authorizationStatus}');
    } else if (Platform.isAndroid) {
      // Request Android notification permissions
      final status = await Permission.notification.request();
      debugPrint('Android notification permission status: $status');
    }
  }

  /// Get FCM token
  static Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      // Don't automatically register here - wait for explicit call after login
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Set up message handlers
  static void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      debugPrint('Message data: ${message.data}');
      debugPrint('Message notification: ${message.notification?.title}');
      
      // Show local notification or handle the message
      _handleForegroundMessage(message);
    });

    // Handle messages when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.messageId}');
      _handleBackgroundMessage(message);
    });

    // Handle messages when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('Message opened terminated app: ${message.messageId}');
        _handleBackgroundMessage(message);
      }
    });

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      debugPrint('FCM Token refreshed: $token');
      _fcmToken = token;
      sendTokenToServer(token);
    });
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    // You can show a local notification or update the UI here
    // For now, we'll just log the message
    debugPrint('Handling foreground message: ${message.notification?.title}');
  }

  /// Handle background messages
  static void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Handling background message: ${message.notification?.title}');
    // Navigate to specific screen based on message data
    // This would typically involve using a navigation service
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Send token to server
  static Future<void> sendTokenToServer(String? token) async {
    if (token == null) return;
    
    try {
      debugPrint('Sending FCM token to server: $token');
      await ApiService().registerPushToken(token);
    } catch (e) {
      debugPrint('Error sending token to server: $e');
    }
  }

  /// Refresh FCM token
  static Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token refreshed: $_fcmToken');
      
      // Re-register the new token with the server
      if (_fcmToken != null) {
        await sendTokenToServer(_fcmToken);
      }
      
      return _fcmToken;
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return false;
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    await Permission.notification.request();
  }

  /// Initialize push notifications after successful login
  /// This matches the Ionic app's pattern of initializing after login
  static Future<Map<String, dynamic>> initAfterLogin() async {
    try {
      debugPrint('📲 Initializing push notifications after login...');
      
      // Request permissions if not already granted
      await _requestPermissions();
      
      // Get FCM token
      final token = await _getFCMToken();
      
      if (token != null) {
        // Register token with server
        await sendTokenToServer(token);
        debugPrint('📲 Push token registered after login: ${token.substring(0, 12)}...');
        
        return {
          'success': true,
          'granted': true,
          'token': token,
        };
      } else {
        debugPrint('📲 No push token available after login');
        return {
          'success': true,
          'granted': false,
          'token': null,
        };
      }
    } catch (e) {
      debugPrint('📲 Error initializing push notifications after login: $e');
      return {
        'success': false,
        'granted': false,
        'token': null,
        'error': e.toString(),
      };
    }
  }
}

/// Top-level function to handle background messages
/// This function must be top-level and not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized for background message handling');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed in background handler: $e');
    // Continue anyway - the message might still be processable
  }
  
  debugPrint('📱 Handling background message: ${message.messageId}');
  debugPrint('📱 Message data: ${message.data}');
  debugPrint('📱 Message notification: ${message.notification?.title}');
}
