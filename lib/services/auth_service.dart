import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user_data';
  static const String _biometricKey = 'biometric_enabled';
  static const String _biometricDataKey = 'biometric_data';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final ApiService _apiService = ApiService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _biometricEnabled = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> initialize() async {
    debugPrint('🔐 AuthService: Initializing...');
    try {
      await _loadStoredAuth();
    } catch (e) {
      debugPrint('🔐 AuthService: Error loading stored auth: $e');
      // Reset to safe state on error
      _currentUser = null;
      _isAuthenticated = false;
    }
    
    try {
      debugPrint('🔐 AuthService: Checking biometric availability...');
      await _checkBiometricAvailability();
      debugPrint('🔐 AuthService: Initialization complete - biometric enabled: $_biometricEnabled');
    } catch (e) {
      debugPrint('🔐 AuthService: Error checking biometric availability: $e');
      _biometricEnabled = false;
    }
  }

  Future<void> _loadStoredAuth() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null) {
        _apiService.setAuthToken(token);
        
        // Try to validate token with backend (with timeout)
        try {
          final user = await _apiService.getCurrentUser().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Token validation timeout');
            },
          );
          _currentUser = user;
          _isAuthenticated = true;
          
          // Cache user data
          await _secureStorage.write(
            key: _userKey,
            value: jsonEncode(user.toJson()),
          );
        } catch (e) {
          // Token is invalid, try to load cached user data as fallback
          final cachedUserData = await _secureStorage.read(key: _userKey);
          if (cachedUserData != null) {
            try {
              final userJson = jsonDecode(cachedUserData);
              _currentUser = User.fromJson(userJson);
              _isAuthenticated = true;
            } catch (parseError) {
              // Clear invalid data
              await _secureStorage.delete(key: _tokenKey);
              await _secureStorage.delete(key: _userKey);
            }
          } else {
            // Clear invalid token
            await _secureStorage.delete(key: _tokenKey);
          }
        }
      }
    } catch (e) {
      // Handle any storage errors
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
    }

    // Check biometric status
    final biometricEnabled = await _secureStorage.read(key: _biometricKey);
    _biometricEnabled = biometricEnabled == 'true';
  }

  Future<bool> login(String username, String password) async {
    try {
      debugPrint('🔐 AuthService: Attempting login for $username');
      final response = await _apiService.login(username, password);
      debugPrint('🔐 AuthService: Login response - success: ${response.success}, message: ${response.message}');
      
      if (response.success) {
        debugPrint('🔐 AuthService: Login successful, setting user and token');
        _apiService.setAuthToken(response.data.token);
        _currentUser = response.data.user;
        _isAuthenticated = true;
        
        // Store token and user data
        await _secureStorage.write(key: _tokenKey, value: response.data.token);
        await _secureStorage.write(
          key: _userKey,
          value: jsonEncode(response.data.user.toJson()),
        );
        
        debugPrint('🔐 AuthService: User data stored, returning true');
        return true;
      }
      debugPrint('🔐 AuthService: Login failed - success was false');
      return false;
    } catch (e) {
      debugPrint('🔐 AuthService: Login error: $e');
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    try {
      debugPrint('🔐 AuthService: Starting biometric login');
      debugPrint('🔐 AuthService: Biometric enabled: $_biometricEnabled');
      
      if (!_biometricEnabled) {
        debugPrint('🔐 AuthService: Biometric not enabled, returning false');
        return false;
      }
      
      // Get stored biometric data
      final biometricData = await _secureStorage.read(key: _biometricDataKey);
      debugPrint('🔐 AuthService: Biometric data found: ${biometricData != null}');
      if (biometricData == null) {
        debugPrint('🔐 AuthService: No biometric data found, returning false');
        return false;
      }
      
      debugPrint('🔐 AuthService: Found biometric data, parsing...');
      final data = jsonDecode(biometricData);
      final email = data['email'] as String;
      final enrollmentToken = data['enrollmentToken'] as String;
      final deviceId = data['deviceId'] as String;
      final platform = data['platform'] as String;
      
      debugPrint('🔐 AuthService: Starting local biometric authentication...');
      // Authenticate with biometric
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      debugPrint('🔐 AuthService: Local biometric result: $isAuthenticated');
      if (!isAuthenticated) {
        debugPrint('🔐 AuthService: Local biometric authentication failed');
        return false;
      }
      
      debugPrint('🔐 AuthService: Authenticating with server...');
      // Authenticate with server
      final response = await _apiService.authenticateWithBiometric(
        email: email,
        enrollmentToken: enrollmentToken,
        deviceId: deviceId,
        platform: platform,
      );
      
      debugPrint('🔐 AuthService: Server response - success: ${response.success}, message: ${response.message}');
      
      if (response.success) {
        debugPrint('🔐 AuthService: Biometric login successful, setting user and token');
        _apiService.setAuthToken(response.data.token);
        _currentUser = response.data.user;
        _isAuthenticated = true;
        
        // Store token and user data
        await _secureStorage.write(key: _tokenKey, value: response.data.token);
        await _secureStorage.write(
          key: _userKey,
          value: jsonEncode(response.data.user.toJson()),
        );
        
        debugPrint('🔐 AuthService: Biometric login completed successfully');
        return true;
      } else if (response.revoked == true) {
        debugPrint('🔐 AuthService: Biometric enrollment was revoked');
        // Biometric enrollment was revoked
        await disableBiometric();
        return false;
      }
      
      debugPrint('🔐 AuthService: Biometric login failed - success was false');
      return false;
    } catch (e) {
      debugPrint('🔐 AuthService: Biometric login error: $e');
      
      // If it's a 401 error, the biometric enrollment is invalid
      if (e.toString().contains('401')) {
        debugPrint('🔐 AuthService: Biometric enrollment invalid (401), disabling biometric');
        await disableBiometric();
      }
      
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      _apiService.clearAuthToken();
      _currentUser = null;
      _isAuthenticated = false;
      
      // Clear stored data
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
    }
  }

  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;
    
    try {
      final user = await _apiService.getCurrentUser();
      _currentUser = user;
      
      // Update cached user data
      await _secureStorage.write(
        key: _userKey,
        value: jsonEncode(user.toJson()),
      );
    } catch (e) {
      // Handle error - user might need to re-authenticate
    }
  }

  // Biometric authentication methods
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if biometrics are available
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        debugPrint('🔐 AuthService: Biometric check - canCheckBiometrics: false');
        return false;
      }
      
      // Check if device supports biometrics
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final result = isAvailable && isDeviceSupported;
      
      debugPrint('🔐 AuthService: Biometric check - canCheckBiometrics: $isAvailable, isDeviceSupported: $isDeviceSupported, result: $result');
      
      return result;
    } catch (e) {
      debugPrint('🔐 AuthService: Biometric availability error: $e');
      return false;
    }
  }

  Future<bool> _checkBiometricAvailability() async {
    final isAvailable = await isBiometricAvailable();
    if (isAvailable) {
      // Check if biometric data is stored (meaning biometric is enabled)
      final biometricData = await _secureStorage.read(key: _biometricDataKey);
      _biometricEnabled = biometricData != null;
      debugPrint('🔐 AuthService: Biometric available: $isAvailable, enabled: $_biometricEnabled');
    } else {
      _biometricEnabled = false;
    }
    return isAvailable;
  }

  Future<Map<String, dynamic>> setupBiometric(String email, String password) async {
    try {
      if (!await isBiometricAvailable()) {
        return {
          'success': false,
          'message': 'Biometric authentication is not available on this device',
        };
      }
      
      // Initiate biometric enrollment
      final enrollmentResponse = await _apiService.initiateBiometricEnrollment(email, password);
      
      if (!enrollmentResponse.success) {
        return {
          'success': false,
          'message': enrollmentResponse.message,
        };
      }
      
      // Get device info
      final deviceInfo = await _apiService.getDeviceInfo();
      final deviceId = deviceInfo['deviceId']!;
      final platform = deviceInfo['platform']!;
      
      // Create biometric hash (simplified - in real app, this would be more secure)
      final biometricData = '$email:$deviceId:$platform';
      final biometricHash = biometricData.hashCode.toString();
      
      // Complete biometric enrollment
      await _apiService.completeBiometricEnrollment(
        email: email,
        enrollmentToken: enrollmentResponse.data.enrollmentToken,
        biometricHash: biometricHash,
        deviceId: deviceId,
        platform: platform,
      );
      
      // Store biometric data
      final biometricDataToStore = {
        'email': email,
        'enrollmentToken': enrollmentResponse.data.enrollmentToken,
        'deviceId': deviceId,
        'platform': platform,
      };
      
      await _secureStorage.write(
        key: _biometricDataKey,
        value: jsonEncode(biometricDataToStore),
      );
      await _secureStorage.write(key: _biometricKey, value: 'true');
      
      _biometricEnabled = true;
      
      return {
        'success': true,
        'message': 'Biometric authentication enabled successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to setup biometric authentication: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> disableBiometric() async {
    try {
      if (!_biometricEnabled) {
        return {
          'success': true,
          'message': 'Biometric authentication is already disabled',
        };
      }
      
      // Get stored biometric data
      final biometricData = await _secureStorage.read(key: _biometricDataKey);
      if (biometricData != null) {
        final data = jsonDecode(biometricData);
        final email = data['email'] as String;
        final enrollmentToken = data['enrollmentToken'] as String;
        final deviceId = data['deviceId'] as String;
        final platform = data['platform'] as String;
        
        // Revoke biometric enrollment on server
        try {
          await _apiService.revokeBiometricEnrollment(
            email: email,
            enrollmentToken: enrollmentToken,
            deviceId: deviceId,
            platform: platform,
          );
        } catch (e) {
          // Continue with local cleanup even if server call fails
        }
      }
      
      // Clear biometric data
      await _secureStorage.delete(key: _biometricDataKey);
      await _secureStorage.delete(key: _biometricKey);
      
      _biometricEnabled = false;
      
      return {
        'success': true,
        'message': 'Biometric authentication disabled successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to disable biometric authentication: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiService.forgotPassword(email);
      return response;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send password reset email: ${e.toString()}',
      };
    }
  }
}
