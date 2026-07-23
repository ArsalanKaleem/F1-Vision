import 'package:flutter/widgets.dart';

/// Spacing, radius and motion tokens.
///
/// Every value is a multiple of 4 so panels, gaps and paddings line up on a
/// shared rhythm across screens. New UI should use these rather than raw
/// numbers; existing screens already follow the same scale by hand.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double huge = 40;

  /// Outer page padding per breakpoint.
  static const double pagePadMobile = 16;
  static const double pagePadDesktop = 28;

  /// Gap between stacked panels.
  static const double panelGap = 16;

  static const EdgeInsets panelPadding = EdgeInsets.all(18);

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;

  /// Widest a centred content column ever grows.
  static const double maxContentWidth = 1500;
}

/// Shared motion durations, so micro-interactions feel like one system.
abstract final class AppDurations {
  static const Duration micro = Duration(milliseconds: 160);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 520);
  static const Duration chart = Duration(milliseconds: 700);
}
