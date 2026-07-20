import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the light and dark [ThemeData] used across the app.
///
/// IMPORTANT: these getters read [AppColors], whose surface/text members are
/// brightness-dependent — so `AppColors.brightness` must be set (done by the
/// ThemeController) before the matching theme is built.
abstract final class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    // Keep the static palette in lock-step with the theme being built.
    AppColors.brightness = brightness;
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    final scheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            surface: AppColors.surface,
            primary: AppColors.accent,
            secondary: AppColors.accentSoft,
            error: AppColors.negative,
            onSurface: AppColors.textPrimary,
          )
        : ColorScheme.light(
            surface: AppColors.surface,
            primary: AppColors.accent,
            secondary: AppColors.accentSoft,
            error: AppColors.negative,
            onSurface: AppColors.textPrimary,
          );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      colorScheme: scheme,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleSmall: AppTextStyles.titleSmall,
        bodyMedium: AppTextStyles.body,
        labelMedium: AppTextStyles.label,
      ),
      dividerColor: AppColors.surfaceStroke,
      cardColor: AppColors.surface,
      iconTheme: IconThemeData(color: AppColors.textSecondary, size: 20),
      splashFactory: InkSparkle.splashFactory,
      // Explicit nav-bar theme: guarantees labels stay visible in BOTH the
      // selected and unselected states (fixes labels vanishing on tap, which
      // happened when Material 3 defaults resolved an invisible label colour
      // against the custom scheme).
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.accentSoft
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.label.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceStroke),
        ),
        textStyle: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.textTertiary.withValues(alpha: 0.4),
        ),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(8),
      ),
    );
  }
}
