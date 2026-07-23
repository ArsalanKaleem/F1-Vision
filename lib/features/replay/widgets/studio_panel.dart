import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/data_panel.dart';

/// The consistent card wrapper for every panel in the replay studio.
class StudioPanel extends StatelessWidget {
  const StudioPanel({
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
    // Delegates to the shared core panel so spacing, typography and header
    // layout stay identical across Analytics, Replay and Comparison.
    return DataPanel(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      glow: glow,
      padding: padding,
      child: child,
    );
  }
}

/// A short "no data" note used when a feed isn't available for an event.
class PanelNotice extends StatelessWidget {
  const PanelNotice({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 26, color: AppColors.textTertiary),
            const SizedBox(height: 10),
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

/// A compact pill used for tyre compounds and status chips.
class StudioPill extends StatelessWidget {
  const StudioPill({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          fontSize: 9,
          color: filled ? Colors.black : color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Tyre-compound chip with the compound's brand colour.
class CompoundChip extends StatelessWidget {
  const CompoundChip({super.key, required this.compound});
  final String compound;

  @override
  Widget build(BuildContext context) {
    final known = compound.toUpperCase() != 'UNKNOWN' && compound.isNotEmpty;
    final color = known ? AppColors.tyreColor(compound) : AppColors.textTertiary;
    final label = known ? compound.toUpperCase().substring(0, 1) : '?';
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        color: color.withValues(alpha: 0.18),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
