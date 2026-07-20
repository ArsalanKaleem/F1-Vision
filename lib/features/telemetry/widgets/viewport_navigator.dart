import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// The chart "navigator": a range slider to zoom the visible window, pan
/// buttons to slide it, and a LIVE button that re-enables auto-follow of the
/// newest data. All charts share the [start]/[end] window it produces.
class ViewportNavigator extends StatelessWidget {
  const ViewportNavigator({
    super.key,
    required this.count,
    required this.start,
    required this.end,
    required this.following,
    required this.onViewport,
    required this.onFollow,
  });

  final int count;
  final double start;
  final double end;
  final bool following;
  final void Function(double start, double end) onViewport;
  final VoidCallback onFollow;

  void _pan(double delta) {
    final maxX = (count - 1).toDouble();
    final width = end - start;
    var newStart = start + delta;
    var newEnd = end + delta;
    if (newStart < 0) {
      newStart = 0;
      newEnd = width;
    }
    if (newEnd > maxX) {
      newEnd = maxX;
      newStart = maxX - width;
    }
    onViewport(newStart, newEnd);
  }

  @override
  Widget build(BuildContext context) {
    final maxX = (count - 1).toDouble();
    final double m = maxX <= 0 ? 1 : maxX;
    final enabled = count > 2;
    final width = end - start;

    return Row(
      children: [
        _IconBtn(
          icon: Icons.chevron_left_rounded,
          onTap: enabled ? () => _pan(-width * 0.25) : null,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceStroke,
              thumbColor: AppColors.textPrimary,
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: RangeSlider(
              min: 0,
              max: m,
              values: RangeValues(
                start.clamp(0, m).toDouble(),
                end.clamp(0, m).toDouble(),
              ),
              onChanged: enabled
                  ? (v) {
                      if (v.end - v.start >= 2) onViewport(v.start, v.end);
                    }
                  : null,
            ),
          ),
        ),
        _IconBtn(
          icon: Icons.chevron_right_rounded,
          onTap: enabled ? () => _pan(width * 0.25) : null,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onFollow,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: following
                  ? AppColors.accent.withValues(alpha: 0.16)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: following ? AppColors.accent : AppColors.surfaceStroke,
              ),
            ),
            child: Text(
              'LIVE',
              style: AppTextStyles.overline.copyWith(
                color: following ? AppColors.accentSoft : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      iconSize: 22,
      color: AppColors.textSecondary,
      icon: Icon(icon),
      splashRadius: 18,
    );
  }
}
