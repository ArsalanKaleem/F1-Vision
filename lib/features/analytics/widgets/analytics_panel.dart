import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';

/// The consistent card wrapper for every analytics panel: a titled glass card
/// with an optional subtitle and trailing widget.
class AnalyticsPanel extends StatelessWidget {
  const AnalyticsPanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.glow = false,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final bool glow;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
                    Text(title,
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.overline),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// A compact metric read-out (label + big value + optional caption).
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.color,
    this.icon,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overline),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.numeric
              .copyWith(fontSize: 22, color: color ?? AppColors.textPrimary),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body
                  .copyWith(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ],
    );
  }
}

/// A small colour dot + label used in bespoke legends.
class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}
