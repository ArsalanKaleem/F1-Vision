import 'package:flutter/material.dart';

/// Centralised colour palette for F1 Vision.
///
/// Dark-mode first, with a full light palette behind the same member names.
/// Surfaces and text swap with the active [brightness]; brand colours (F1 red,
/// tyre compounds, semantic green/amber/blue) stay identical in both modes so
/// charts and team identities remain recognisable.
abstract final class AppColors {
  // ── Mode switch (driven by ThemeController; see theme_providers.dart) ──
  static bool _isLight = false;
  static bool get isLight => _isLight;
  static set brightness(Brightness value) {
    _isLight = value == Brightness.light;
  }

  // ── Canvas & surfaces (theme-dependent) ───────────────────────────────
  static Color get background => _isLight ? _Light.background : _Dark.background;
  static Color get surface => _isLight ? _Light.surface : _Dark.surface;
  static Color get surfaceHigh => _isLight ? _Light.surfaceHigh : _Dark.surfaceHigh;
  static Color get surfaceStroke =>
      _isLight ? _Light.surfaceStroke : _Dark.surfaceStroke;

  // ── Text (theme-dependent) ─────────────────────────────────────────────
  static Color get textPrimary => _isLight ? _Light.textPrimary : _Dark.textPrimary;
  static Color get textSecondary =>
      _isLight ? _Light.textSecondary : _Dark.textSecondary;
  static Color get textTertiary =>
      _isLight ? _Light.textTertiary : _Dark.textTertiary;

  /// Subtle gradient used on hero cards (theme-dependent).
  static LinearGradient get heroGradient =>
      _isLight ? _Light.heroGradient : _Dark.heroGradient;

  // ── Accents (identical in both modes) ──────────────────────────────────
  static const Color accent = Color(0xFFE10600); // F1 red
  static const Color accentSoft = Color(0xFFFF2D20);
  static const Color positive = Color(0xFF2ECC71);
  static const Color negative = Color(0xFFFF4D4F);
  static const Color warning = Color(0xFFF5A623);
  static const Color info = Color(0xFF3B82F6);

  // ── Tyre compounds (used across timeline / strategy widgets) ───────────
  static const Color tyreSoft = Color(0xFFE8002D);
  static const Color tyreMedium = Color(0xFFFFD12E);
  static const Color tyreHard = Color(0xFFF0F0F0);
  static const Color tyreIntermediate = Color(0xFF43B02A);
  static const Color tyreWet = Color(0xFF0067AD);

  /// Red glow gradient for accent surfaces.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE10600), Color(0xFF8E0400)],
  );

  /// Maps an OpenF1 / Jolpica tyre compound label to its brand colour.
  static Color tyreColor(String? compound) {
    switch (compound?.toUpperCase()) {
      case 'SOFT':
        return tyreSoft;
      case 'MEDIUM':
        return tyreMedium;
      case 'HARD':
        return _isLight ? const Color(0xFF8A8A8A) : tyreHard;
      case 'INTERMEDIATE':
        return tyreIntermediate;
      case 'WET':
        return tyreWet;
      default:
        return textTertiary;
    }
  }
}

/// The original near-black cockpit palette.
abstract final class _Dark {
  static const Color background = Color(0xFF090909);
  static const Color surface = Color(0xFF161616);
  static const Color surfaceHigh = Color(0xFF1F1F1F);
  static const Color surfaceStroke = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9A9A9A);
  static const Color textTertiary = Color(0xFF5E5E5E);
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C1C), Color(0xFF101010)],
  );
}

/// A warm paper-white palette tuned to keep the F1 red punchy.
abstract final class _Light {
  static const Color background = Color(0xFFF6F5F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceHigh = Color(0xFFEFEDEA);
  static const Color surfaceStroke = Color(0xFFE1DED8);
  static const Color textPrimary = Color(0xFF161616);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textTertiary = Color(0xFF9B9B9B);
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0EEEA)],
  );
}
