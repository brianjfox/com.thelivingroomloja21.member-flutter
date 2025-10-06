import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/username_service.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';
import '../utils/app_router.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get biometricEnabled => _biometricEnabled;
  bool get biometricAvailable => _biometricAvailable;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _authService.initialize();
      _user = _authService.currentUser;
      _isAuthenticated = _authService.isAuthenticated;
      _biometricEnabled = _authService.biometricEnabled;
      _biometricAvailable = await _authService.isBiometricAvailable();
      
      // Set up unauthorized callback for API service
      ApiService().setOnUnauthorizedCallback(_handleUnauthorized);
      
      debugPrint('🔐 AuthProvider: Initialized');
      debugPrint('🔐 AuthProvider: biometricAvailable: $_biometricAvailable');
      debugPrint('🔐 AuthProvider: biometricEnabled: $_biometricEnabled');
      debugPrint('🔐 AuthProvider: isAuthenticated: $_isAuthenticated');
      
      // If not authenticated but biometric is enabled, try biometric login
      if (!_isAuthenticated && _biometricEnabled && _biometricAvailable) {
        debugPrint('🔐 AuthProvider: Attempting automatic biometric login');
        try {
          final biometricSuccess = await _authService.loginWithBiometric();
          if (biometricSuccess) {
            _user = _authService.currentUser;
            _isAuthenticated = _authService.isAuthenticated;
            debugPrint('🔐 AuthProvider: Automatic biometric login successful');
            notifyListeners();
          } else {
            debugPrint('🔐 AuthProvider: Automatic biometric login failed');
          }
        } catch (e) {
          debugPrint('🔐 AuthProvider: Automatic biometric login error: $e');
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _handleUnauthorized() async {
    debugPrint('🔐 AuthProvider: Handling unauthorized access');
    _user = null;
    _isAuthenticated = false;
    _biometricEnabled = false;
    
    // Recheck biometric availability after unauthorized access
    _biometricAvailable = await _authService.isBiometricAvailable();
    
    notifyListeners();
    
    // Navigate to login screen with unauthorized message
    try {
      const message = 'You\'re currently unauthorized. Please login again.';
      final encodedMessage = Uri.encodeComponent(message);
      AppRouter.router.go('/login?message=$encodedMessage');
    } catch (e) {
      debugPrint('Error navigating to login: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    try {
      final success = await _authService.login(username, password);
      if (success) {
        _user = _authService.currentUser;
        _isAuthenticated = _authService.isAuthenticated;
        _biometricAvailable = await _authService.isBiometricAvailable();
        notifyListeners();
        
        // Initialize push notifications after successful login (non-blocking)
        // This matches the Ionic app's pattern
        Future.delayed(Duration.zero, () async {
          try {
            debugPrint('🚀 Starting push notification initialization after login');
            final result = await PushNotificationService.initAfterLogin();
            if (result['success'] == true && result['granted'] == true && result['token'] != null) {
              debugPrint('📲 Push token acquired (login): ${result['token'].toString().substring(0, 12)}…');
            } else {
              debugPrint('📲 Push not granted or no token');
            }
          } catch (error) {
            debugPrint('⚠️ Push notification initialization failed, continuing: $error');
          }
        });
      }
      return success;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithBiometric() async {
    _setLoading(true);
    try {
      debugPrint('🔐 AuthProvider: Starting biometric login');
      final success = await _authService.loginWithBiometric();
      debugPrint('🔐 AuthProvider: Biometric login result: $success');
      
      if (success) {
        _user = _authService.currentUser;
        _isAuthenticated = _authService.isAuthenticated;
        debugPrint('🔐 AuthProvider: Biometric login successful, user set');
        notifyListeners();
        
        // Initialize push notifications after successful biometric login (non-blocking)
        // This matches the Ionic app's pattern
        Future.delayed(Duration.zero, () async {
          try {
            debugPrint('🚀 Starting push notification initialization after biometric login');
            final result = await PushNotificationService.initAfterLogin();
            if (result['success'] == true && result['granted'] == true && result['token'] != null) {
              debugPrint('📲 Push token acquired (biometric): ${result['token'].toString().substring(0, 12)}…');
            } else {
              debugPrint('📲 Push not granted or no token');
            }
          } catch (error) {
            debugPrint('⚠️ Push notification initialization failed, continuing: $error');
          }
        });
      } else {
        // Check if biometric was revoked
        _biometricEnabled = _authService.biometricEnabled;
        debugPrint('🔐 AuthProvider: Biometric login failed, biometric enabled: $_biometricEnabled');
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('🔐 AuthProvider: Biometric login error: $e');
      debugPrint('Biometric login error: $e');
      _biometricEnabled = _authService.biometricEnabled;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      _biometricEnabled = false;
      
      // Clear saved username
      try {
        final usernameService = await UsernameService.getInstance();
        await usernameService.clearUsername();
        debugPrint('AuthProvider: Cleared saved username on logout');
      } catch (e) {
        debugPrint('AuthProvider: Error clearing saved username: $e');
      }
      
      // Recheck biometric availability after logout
      _biometricAvailable = await _authService.isBiometricAvailable();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    try {
      await _authService.refreshUser();
      _user = _authService.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh user error: $e');
    }
  }

  Future<Map<String, dynamic>> setupBiometric(String email, String password) async {
    try {
      final result = await _authService.setupBiometric(email, password);
      if (result['success']) {
        _biometricEnabled = _authService.biometricEnabled;
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to setup biometric authentication: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> disableBiometric() async {
    try {
      final result = await _authService.disableBiometric();
      if (result['success']) {
        _biometricEnabled = _authService.biometricEnabled;
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to disable biometric authentication: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      return await _authService.forgotPassword(email);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send password reset email: ${e.toString()}',
      };
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
