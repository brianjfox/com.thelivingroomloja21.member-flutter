import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevelopmentModeService {
  static const String _devModeKey = 'development_mode_enabled';
  static const String _productionUrl = 'https://api.thelivingroomloja21.com/api';
  static const String _developmentUrl = 'http://localhost:3001/api';
  
  static DevelopmentModeService? _instance;
  static SharedPreferences? _prefs;

  DevelopmentModeService._();

  static Future<DevelopmentModeService> getInstance() async {
    _instance ??= DevelopmentModeService._();
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('DevelopmentModeService: Error getting SharedPreferences instance: $e');
    }
    return _instance!;
  }

  /// Get the current API base URL
  String get currentApiUrl {
    final isDevMode = _prefs?.getBool(_devModeKey) ?? false;
    return isDevMode ? _developmentUrl : _productionUrl;
  }

  /// Get the current API server display name
  String get currentApiServer {
    final isDevMode = _prefs?.getBool(_devModeKey) ?? false;
    return isDevMode ? 'localhost:3001' : 'api.thelivingroomloja21.com';
  }

  /// Check if development mode is enabled
  bool get isDevelopmentMode {
    return _prefs?.getBool(_devModeKey) ?? false;
  }

  /// Toggle development mode
  Future<void> toggleDevelopmentMode() async {
    try {
      if (_prefs == null) {
        debugPrint('DevelopmentModeService: SharedPreferences not initialized');
        return;
      }
      
      final currentMode = _prefs!.getBool(_devModeKey) ?? false;
      final newMode = !currentMode;
      
      await _prefs!.setBool(_devModeKey, newMode);
      debugPrint('DevelopmentModeService: Development mode ${newMode ? 'enabled' : 'disabled'}');
      debugPrint('DevelopmentModeService: API URL changed to: $currentApiUrl');
    } catch (e) {
      debugPrint('DevelopmentModeService: Error toggling development mode: $e');
    }
  }

  /// Set development mode explicitly
  Future<void> setDevelopmentMode(bool enabled) async {
    try {
      if (_prefs == null) {
        debugPrint('DevelopmentModeService: SharedPreferences not initialized');
        return;
      }
      
      await _prefs!.setBool(_devModeKey, enabled);
      debugPrint('DevelopmentModeService: Development mode set to: $enabled');
      debugPrint('DevelopmentModeService: API URL changed to: $currentApiUrl');
    } catch (e) {
      debugPrint('DevelopmentModeService: Error setting development mode: $e');
    }
  }

  /// Get the production URL
  String get productionUrl => _productionUrl;

  /// Get the development URL
  String get developmentUrl => _developmentUrl;
}
