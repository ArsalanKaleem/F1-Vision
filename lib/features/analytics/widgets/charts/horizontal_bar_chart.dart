import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One row of a [HorizontalBarChart].
class BarDatum {
  const BarDatum({
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
    this.tooltip,
  });

  final String label;
  final double value;
  final Color color;
  final String? trailing; // right-aligned value text (defaults to value)
  final String? tooltip;
}

/// A Bloomberg-terminal style ranked horizontal bar chart. Bars grow on entry,
/// rows highlight on hover (desktop) and show a tooltip on hover / long-press
/// (mobile). Fully self-contained — no fl_chart dependency.
class HorizontalBarChart extends StatefulWidget {
  const HorizontalBarChart({
    super.key,
    required this.data,
    this.labelWidth = 46,
    this.rowHeight = 30,
    this.barHeight = 12,
  });

  final List<BarDatum> data;
  final double labelWidth;
  final double rowHeight;
  final double barHeight;

  @override
  State<HorizontalBarChart> createState() => _HorizontalBarChartState();
}

class _HorizontalBarChartState extends State<HorizontalBarChart> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();
    final maxValue = widget.data
        .map((d) => d.value)
        .fold<double>(0, (a, b) => b > a ? b : a);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.data.length; i++)
          _row(widget.data[i], i, safeMax),
      ],
    );
  }

  Widget _row(BarDatum d, int index, double safeMax) {
    final active = _hovered == index;
    final fraction = (d.value / safeMax).clamp(0.0, 1.0).toDouble();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = index),
      onExit: (_) => setState(() => _hovered = null),
      child: Tooltip(
        message: d.tooltip ?? '${d.label}: ${_fmt(d.value)}',
        waitDuration: const Duration(milliseconds: 200),
        child: Container(
          height: widget.rowHeight,
          color: Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                width: widget.labelWidth,
                child: Text(
                  d.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: active ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: widget.barHeight,
                        color: AppColors.surfaceHigh,
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: fraction),
                        duration: const Duration(milliseconds: 850),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) => FractionallySizedBox(
                          widthFactor: t,
                          child: Container(
                            height: widget.barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  d.color.withValues(alpha: active ? 0.95 : 0.75),
                                  d.color,
                                ],
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: d.color.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        spreadRadius: -2,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 46,
                child: Text(
                  d.trailing ?? _fmt(d.value),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.numeric.copyWith(
                    fontSize: 13,
                    color: active ? d.color : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
