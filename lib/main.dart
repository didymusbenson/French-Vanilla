import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/heart_customization_screen.dart';
import 'services/iap_service.dart';
import 'services/data_preloader.dart';
import 'services/content_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Android navigation bar to use edge-to-edge mode (slide up/gesture navigation)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  // Make navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize IAP service
  await IAPService().initialize();

  // Start preloading data in the background (non-blocking)
  DataPreloader().preloadAll();

  // Silently check for over-the-air content updates so the Credits tab and
  // Content Updates card can badge availability. Fire-and-forget; fails
  // silently when offline.
  ContentUpdateService.instance.refreshUpdateFlag();

  runApp(const FrenchVanillaApp());
}

class FrenchVanillaApp extends StatefulWidget {
  const FrenchVanillaApp({super.key});

  @override
  State<FrenchVanillaApp> createState() => _FrenchVanillaAppState();
}

class _FrenchVanillaAppState extends State<FrenchVanillaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    IAPService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle events if needed in the future
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'French Vanilla - MTG Rules',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      routes: {
        '/heart-customization': (context) => const HeartCustomizationScreen(),
      },
    );
  }
}
