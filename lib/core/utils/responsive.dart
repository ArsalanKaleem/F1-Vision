import 'package:flutter/widgets.dart';

/// Screen-size classification used to switch between mobile, tablet and desktop
/// layouts. Kept deliberately simple — three buckets cover the brief's
/// "adaptive for every screen size" requirement without a heavy dependency.
enum ScreenSize { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize {
    final w = width;
    if (w >= 1100) return ScreenSize.desktop;
    if (w >= 720) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Picks a value per breakpoint, falling back upward when one is omitted.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (screenSize) {
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}
