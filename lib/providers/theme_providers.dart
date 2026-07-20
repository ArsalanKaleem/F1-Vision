import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';

/// Injected in `main()` after the instance is loaded, so theme persistence is
/// synchronous everywhere else.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

/// The persisted theme preference plus the concrete brightness it resolves to
/// right now (System follows the OS and updates live).
class ThemeState {
  const ThemeState({required this.mode, required this.brightness});
  final ThemeMode mode;
  final Brightness brightness;

  bool get isLight => brightness == Brightness.light;
}

class ThemeController extends StateNotifier<ThemeState> {
  ThemeController(this._prefs) : super(_initial(_prefs)) {
    // Follow live OS changes while in System mode.
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _onPlatformBrightness;
    AppColors.brightness = state.brightness;
  }

  static const _key = 'theme_mode';
  final SharedPreferences _prefs;

  static ThemeState _initial(SharedPreferences prefs) {
    final mode = switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // the app's signature look stays the default
    };
    return ThemeState(mode: mode, brightness: _resolve(mode));
  }

  static Brightness _resolve(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
      };

  void _onPlatformBrightness() {
    if (state.mode == ThemeMode.system) {
      _apply(state.mode);
    }
  }

  void setMode(ThemeMode mode) {
    _prefs.setString(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    _apply(mode);
  }

  void _apply(ThemeMode mode) {
    final brightness = _resolve(mode);
    AppColors.brightness = brightness; // swap the static palette first
    state = ThemeState(mode: mode, brightness: brightness);
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeState>(
  (ref) => ThemeController(ref.watch(sharedPreferencesProvider)),
);
