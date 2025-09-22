import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/main_tabs_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/items_screen.dart';
import '../screens/events_screen.dart';
import '../screens/purchases_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/item_detail_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../screens/wine_learning_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // If still loading, don't redirect
        if (authProvider.isLoading) {
          return null;
        }
        
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login' || 
                            state.matchedLocation == '/forgot-password';
      
        // If not authenticated and not on login/forgot-password, redirect to login
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }
        
        // If authenticated and on login/forgot-password, redirect to dashboard
        if (isAuthenticated && isLoginRoute) {
          return '/tabs/dashboard';
        }
        
        return null;
      } catch (e) {
        // If there's an error accessing AuthProvider, default to login
        debugPrint('AppRouter: Error in redirect: $e');
        return '/login';
      }
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final unauthorizedMessage = state.uri.queryParameters['message'];
          return LoginScreen(unauthorizedMessage: unauthorizedMessage);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/tabs',
        builder: (context, state) => const MainTabsScreen(),
        routes: [
          GoRoute(
            path: 'dashboard',
            builder: (context, state) => const MainTabsScreen(initialIndex: 0),
          ),
          GoRoute(
            path: 'items',
            builder: (context, state) => const MainTabsScreen(initialIndex: 2),
          ),
          GoRoute(
            path: 'events',
            builder: (context, state) => const MainTabsScreen(initialIndex: 1),
          ),
          GoRoute(
            path: 'purchases',
            builder: (context, state) => const MainTabsScreen(initialIndex: 3),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/item/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ItemDetailScreen(key: ValueKey('item_$id'), itemId: id);
        },
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) {
          final returnResult = state.uri.queryParameters['return'] == 'true';
          return BarcodeScannerScreen(returnResult: returnResult);
        },
      ),
      GoRoute(
        path: '/wine-learning',
        builder: (context, state) {
          final barcode = state.uri.queryParameters['barcode'];
          return WineLearningScreen(initialBarcode: barcode);
        },
      ),
    ],
  );
}
