import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'utils/app_router.dart';
import 'services/push_notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase with better error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
      
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('✅ Firebase messaging background handler set up');
    } catch (firebaseError) {
      debugPrint('❌ Firebase initialization failed: $firebaseError');
      debugPrint('⚠️  App will continue without Firebase features');
      // Continue without Firebase - the app should still work for basic functionality
    }
    
    // Add error handling for uncaught exceptions
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
    };
    
    runApp(const TLRMemberApp());
  } catch (e) {
    debugPrint('Critical app initialization error: $e');
    // Still try to run the app even if there's an error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Initialization Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class TLRMemberApp extends StatelessWidget {
  const TLRMemberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = AuthProvider();
            // Initialize asynchronously without blocking the UI
            Future.delayed(Duration.zero, () {
              provider.initialize().catchError((error) {
                debugPrint('AuthProvider initialization error: $error');
              });
            });
            return provider;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Show loading screen while AuthProvider is initializing
          if (authProvider.isLoading) {
            return MaterialApp(
              title: 'The Living Room Member',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF388E3C), // Green theme
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ),
              home: const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              debugShowCheckedModeBanner: false,
            );
          }
          
          return MaterialApp.router(
            title: 'The Living Room Member',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF388E3C), // Green theme
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
