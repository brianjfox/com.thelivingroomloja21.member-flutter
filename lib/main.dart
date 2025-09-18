import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'utils/app_router.dart';

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
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
          child: Text('App initialization error: $e'),
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
