import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

/// The canonical titled card used by every analytics-style panel in the app.
///
/// `AnalyticsPanel` (Analytics) and `StudioPanel` (Replay) delegate to this so
/// spacing, type scale and header layout stay identical everywhere.
class DataPanel extends StatelessWidget {
  const DataPanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.glow = false,
    this.padding = AppSpacing.panelPadding,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final bool glow;
  final EdgeInsets padding;

  /// Screen-reader description; defaults to "<title>. <subtitle>".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel ??
          [title, if (subtitle != null) subtitle].whereType<String>().join('. '),
      child: GlassCard(
        glow: glow,
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs / 2),
                        Text(subtitle!, style: AppTextStyles.overline),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.lg - 2),
            child,
          ],
        ),
      ),
    );
  }
}

/// A short, centred "nothing to show" note used inside panels.
class PanelEmptyNote extends StatelessWidget {
  const PanelEmptyNote({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 26, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm + 2),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
