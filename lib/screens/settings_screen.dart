import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/development_mode_service.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DevelopmentModeService? _devModeService;
  String _currentApiServer = '';

  @override
  void initState() {
    super.initState();
    _initializeDevModeService();
  }

  Future<void> _initializeDevModeService() async {
    _devModeService = await DevelopmentModeService.getInstance();
    _currentApiServer = _devModeService!.currentApiServer;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleDevelopmentMode() async {
    if (_devModeService == null) return;
    
    await _devModeService!.toggleDevelopmentMode();
    _currentApiServer = _devModeService!.currentApiServer;
    
    // Update the API service base URL
    await ApiService().updateBaseUrl();
    
    if (mounted) {
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
            children: [
              // User Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (authProvider.user != null) ...[
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Name'),
                          subtitle: Text(authProvider.user!.fullName),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(authProvider.user!.email),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Phone'),
                          subtitle: Text(authProvider.user!.phone),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Biometric Status (Read-only)
              if (authProvider.biometricAvailable) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: Icon(
                            authProvider.biometricEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                            color: authProvider.biometricEnabled ? Colors.green : Colors.grey,
                          ),
                          title: const Text('Biometric Authentication'),
                          subtitle: Text(
                            authProvider.biometricEnabled
                                ? 'Face ID or Touch ID is enabled for quick login'
                                : 'Biometric authentication is not set up. Enable it on the login screen.',
                          ),
                          trailing: authProvider.biometricEnabled
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.info_outline, color: Colors.orange),
                        ),
                        if (authProvider.biometricEnabled) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextButton.icon(
                              onPressed: () async {
                                final result = await authProvider.disableBiometric();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message']),
                                      backgroundColor: result['success'] ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.fingerprint_outlined, size: 16),
                              label: const Text('Disable Biometric Authentication'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Push Notifications
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<bool>(
                        future: PushNotificationService.areNotificationsEnabled(),
                        builder: (context, snapshot) {
                          final isEnabled = snapshot.data ?? false;
                          return SwitchListTile(
                            title: const Text('Push Notifications'),
                            subtitle: Text(
                              isEnabled 
                                ? 'Receive notifications about new events and updates'
                                : 'Enable to receive notifications about new events and updates',
                            ),
                            value: isEnabled,
                            onChanged: (value) async {
                              if (value) {
                                // Show loading indicator
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Requesting notification permissions...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                                
                                try {
                                  // Initialize push notifications (only if user is authenticated)
                                  if (authProvider.isAuthenticated) {
                                    final result = await PushNotificationService.initAfterLogin();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['success'] 
                                              ? 'Push notifications enabled successfully!'
                                              : 'Failed to enable push notifications: ${result['error'] ?? 'Unknown error'}'
                                          ),
                                          backgroundColor: result['success'] ? Colors.green : Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    // If not authenticated, just request permissions
                                    await PushNotificationService.initialize();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Push notification permissions requested'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error enabling push notifications: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                // Open app settings to disable notifications
                                await PushNotificationService.openAppSettings();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please disable notifications in your device settings'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          );
                        },
                      ),
                      if (PushNotificationService.fcmToken != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Device Token: ${PushNotificationService.fcmToken?.substring(0, 20)}...',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Development Mode (Admin Only)
              if (authProvider.user?.isAdmin == true) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Development',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            (_devModeService?.isDevelopmentMode ?? false) 
                              ? 'Use Local API' 
                              : 'Use Production API'
                          ),
                          subtitle: const Text('Switch between local and production API servers'),
                          value: _devModeService?.isDevelopmentMode ?? false,
                          onChanged: _devModeService != null ? (value) => _toggleDevelopmentMode() : null,
                        ),
                        if (_currentApiServer.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Current API Server: $_currentApiServer',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // App Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Language'),
                        subtitle: const Text('English'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implement language selection
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        subtitle: const Text('Push notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Implement notification settings
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Logout
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ),
            ],
            );
          },
        ),
      ),
    );
  }
}
