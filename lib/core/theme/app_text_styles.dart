import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographic scale for F1 Vision.
///
/// We pair a slightly condensed display face (Sora) for headings and numerics
/// with a clean grotesque (Inter) for body copy — a combination that reads as
/// modern and data-dense without feeling sterile.
abstract final class AppTextStyles {
  static TextStyle get _display => GoogleFonts.sora();
  static TextStyle get _body => GoogleFonts.inter();

  static TextStyle get displayLarge => _display.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => _display.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => _display.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => _body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => _body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => _body.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  /// Monospaced-feel numeric style for telemetry & timing read-outs.
  static TextStyle get numeric => _display.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.textPrimary,
      );

  static TextStyle get overline => _body.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: AppColors.textTertiary,
      );
}
