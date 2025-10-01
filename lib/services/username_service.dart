import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UsernameService {
  static const String _usernameKey = 'saved_username';
  static UsernameService? _instance;
  static SharedPreferences? _prefs;

  UsernameService._();

  static Future<UsernameService> getInstance() async {
    _instance ??= UsernameService._();
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('UsernameService: Error getting SharedPreferences instance: $e');
      // Continue with null prefs - methods will handle this gracefully
    }
    return _instance!;
  }

  /// Save username to persistent storage
  Future<void> saveUsername(String username) async {
    try {
      if (_prefs == null) {
        debugPrint('UsernameService: SharedPreferences not initialized, cannot save username');
        return;
      }
      debugPrint('UsernameService: Saving username: $username');
      await _prefs!.setString(_usernameKey, username);
      debugPrint('UsernameService: Username saved successfully');
    } catch (e) {
      debugPrint('UsernameService: Error saving username: $e');
    }
  }

  /// Get saved username from persistent storage
  Future<String?> getSavedUsername() async {
    try {
      if (_prefs == null) {
        debugPrint('UsernameService: SharedPreferences not initialized, cannot retrieve username');
        return null;
      }
      final username = _prefs!.getString(_usernameKey);
      debugPrint('UsernameService: Retrieved saved username: $username');
      return username;
    } catch (e) {
      debugPrint('UsernameService: Error retrieving username: $e');
      return null;
    }
  }

  /// Clear saved username
  Future<void> clearUsername() async {
    try {
      if (_prefs == null) {
        debugPrint('UsernameService: SharedPreferences not initialized, cannot clear username');
        return;
      }
      debugPrint('UsernameService: Clearing saved username');
      await _prefs!.remove(_usernameKey);
      debugPrint('UsernameService: Username cleared successfully');
    } catch (e) {
      debugPrint('UsernameService: Error clearing username: $e');
    }
  }

  /// Check if username is saved
  Future<bool> hasSavedUsername() async {
    try {
      if (_prefs == null) {
        debugPrint('UsernameService: SharedPreferences not initialized, cannot check for saved username');
        return false;
      }
      final hasUsername = _prefs!.containsKey(_usernameKey);
      debugPrint('UsernameService: Has saved username: $hasUsername');
      return hasUsername;
    } catch (e) {
      debugPrint('UsernameService: Error checking for saved username: $e');
      return false;
    }
  }
}
