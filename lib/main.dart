import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_providers.dart';
import 'providers/theme_providers.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase (optional) ─────────────────────────────────────────────
  // If the platform config (google-services.json / GoogleService-Info.plist /
  // web options) is missing, initialisation throws and the app simply runs
  // without authentication — so the project works straight after cloning.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase not configured — running without auth. ($e)');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        firebaseReadyProvider.overrideWithValue(firebaseReady),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const F1VisionApp(),
    ),
  );
}

class F1VisionApp extends ConsumerWidget {
  const F1VisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);

    SystemChrome.setSystemUIOverlayStyle(
      theme.isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
    );

    return MaterialApp.router(
      title: 'F1 Vision',
      debugShowCheckedModeBanner: false,
      // The controller resolves ThemeMode.system itself (and listens for OS
      // changes), so we always hand MaterialApp one concrete theme that
      // matches the static AppColors palette.
      theme: theme.isLight ? AppTheme.light : AppTheme.dark,
      themeMode: ThemeMode.light, // `theme` above is already the resolved one
      routerConfig: router,
      // The palette lives in static getters, so a brightness change must
      // rebuild every widget — including `const` ones. Swapping this subtree
      // key recreates the element tree, guaranteeing a clean repaint.
      builder: (context, child) => KeyedSubtree(
        key: ValueKey(theme.brightness),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
