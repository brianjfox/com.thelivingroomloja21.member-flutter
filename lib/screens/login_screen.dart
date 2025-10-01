import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/username_service.dart';

class LoginScreen extends StatefulWidget {
  final String? unauthorizedMessage;
  
  const LoginScreen({super.key, this.unauthorizedMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showBiometricAlert = false;
  UsernameService? _usernameService;

  @override
  void initState() {
    super.initState();
    _initializeUsernameService();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeUsernameService() async {
    try {
      _usernameService = await UsernameService.getInstance();
      await _loadSavedUsername();
    } catch (e) {
      debugPrint('LoginScreen: Error initializing username service: $e');
    }
  }

  Future<void> _loadSavedUsername() async {
    try {
      if (_usernameService != null) {
        final savedUsername = await _usernameService!.getSavedUsername();
        if (savedUsername != null && savedUsername.isNotEmpty) {
          debugPrint('LoginScreen: Loading saved username: $savedUsername');
          if (mounted) {
            _usernameController.text = savedUsername;
          }
        }
      }
    } catch (e) {
      debugPrint('LoginScreen: Error loading saved username: $e');
    }
  }

  String _getBiometricLabel() {
    if (Platform.isIOS) {
      return 'Login with Face ID';
    } else if (Platform.isAndroid) {
      return 'Login with Touch ID';
    } else {
      return 'Login with Biometrics';
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final success = await authProvider.login(
      username,
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        debugPrint('🔐 LoginScreen: Login successful');
        debugPrint('🔐 LoginScreen: biometricAvailable: ${authProvider.biometricAvailable}');
        debugPrint('🔐 LoginScreen: biometricEnabled: ${authProvider.biometricEnabled}');
        
        // Save username for future logins
        try {
          if (_usernameService != null) {
            await _usernameService!.saveUsername(username);
            debugPrint('🔐 LoginScreen: Username saved for future logins');
          }
        } catch (e) {
          debugPrint('🔐 LoginScreen: Error saving username: $e');
        }
        
        // Check if biometric is available and not enabled
        if (authProvider.biometricAvailable && !authProvider.biometricEnabled) {
          debugPrint('🔐 LoginScreen: Showing biometric setup alert');
          setState(() {
            _showBiometricAlert = true;
          });
        } else {
          debugPrint('🔐 LoginScreen: Navigating to dashboard');
          context.go('/tabs/dashboard');
        }
      } else {
        _showErrorDialog('Invalid credentials. Please try again.');
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      debugPrint('🔐 LoginScreen: Starting biometric login');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.loginWithBiometric();

      debugPrint('🔐 LoginScreen: Biometric login result: $success');

      if (mounted) {
        if (success) {
          debugPrint('🔐 LoginScreen: Biometric login successful, navigating to dashboard');
          context.go('/tabs/dashboard');
        } else {
          debugPrint('🔐 LoginScreen: Biometric login failed, showing error');
          _showErrorDialog('Biometric authentication failed. Please try again or use your password.');
        }
      }
    } catch (e) {
      debugPrint('🔐 LoginScreen: Biometric login error: $e');
      if (mounted) {
        _showErrorDialog('Biometric authentication error: $e');
      }
    }
  }

  Future<void> _setupBiometric() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final result = await authProvider.setupBiometric(
      username,
      _passwordController.text,
    );

    if (mounted) {
      if (result['success']) {
        // Save username for future logins
        try {
          if (_usernameService != null) {
            await _usernameService!.saveUsername(username);
            debugPrint('🔐 LoginScreen: Username saved after biometric setup');
          }
        } catch (e) {
          debugPrint('🔐 LoginScreen: Error saving username after biometric setup: $e');
        }
        
        _showSuccessSnackBar('Biometric authentication enabled! You can use ${Platform.isIOS ? 'Face ID' : Platform.isAndroid ? 'Touch ID' : 'biometric authentication'} next time.');
        context.go('/tabs/dashboard');
      } else {
        _showErrorDialog(result['message']);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF388E3C),
                  Color(0xFF2E7D32),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wine_bar,
                              size: 64,
                              color: Color(0xFF388E3C),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome to The Living Room',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF388E3C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.unauthorizedMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(color: Colors.red.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.unauthorizedMessage!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _usernameController,
			      autofillHints: const [AutofillHints.email],
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading ? null : _handleLogin,
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Login'),
                                  ),
                                );
                              },
                            ),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                if (authProvider.biometricAvailable && authProvider.biometricEnabled) {
                                  return Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      const Row(
                                        children: [
                                          Expanded(child: Divider()),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16),
                                            child: Text('OR'),
                                          ),
                                          Expanded(child: Divider()),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: authProvider.isLoading ? null : _handleBiometricLogin,
                                          icon: const Icon(Icons.fingerprint),
                                          label: Text(_getBiometricLabel()),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              child: const Text('Forgot your password?'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'If you are not a member,\nplease send us a message!',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () {
                                // Open email client
                                // You can use url_launcher package for this
                              },
                              child: const Text('admin@theLivingRoomLoja.com'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Biometric setup dialog
          if (_showBiometricAlert)
            Container(
              color: Colors.black54,
              child: Center(
                child: AlertDialog(
                  title: const Text('Enable Biometric Authentication'),
                  content: Text(
                    'Would you like to enable biometric authentication for quick login? You can use ${Platform.isIOS ? 'Face ID' : Platform.isAndroid ? 'Touch ID' : 'biometric authentication'} instead of entering your password.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showBiometricAlert = false;
                        });
                        context.go('/tabs/dashboard');
                      },
                      child: const Text('Not Now'),
                    ),
                    TextButton(
                      onPressed: _setupBiometric,
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
