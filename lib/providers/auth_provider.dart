import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
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
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _handleUnauthorized() {
    debugPrint('🔐 AuthProvider: Handling unauthorized access');
    _user = null;
    _isAuthenticated = false;
    _biometricEnabled = false;
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
