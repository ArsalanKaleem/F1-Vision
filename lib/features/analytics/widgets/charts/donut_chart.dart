import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One slice of a [DonutChart].
class PieDatum {
  const PieDatum({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;
}

/// A reusable pie / donut chart. Slices lift on hover (desktop) and tap
/// (mobile); the centre shows the focused slice (or a default title), and a
/// legend lists every slice with its share. Set [centerSpaceRadius] to 0 for a
/// solid pie.
class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.data,
    this.size = 168,
    this.centerSpaceRadius = 46,
    this.centerTitle,
    this.centerValue,
    this.showLegend = true,
  });

  final List<PieDatum> data;
  final double size;
  final double centerSpaceRadius;
  final String? centerTitle;
  final String? centerValue;
  final bool showLegend;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();
    final total = widget.data.fold<double>(0, (a, b) => a + b.value);
    final safeTotal = total <= 0 ? 1.0 : total;
    final baseRadius = widget.centerSpaceRadius > 0
        ? widget.size * 0.18
        : widget.size * 0.42;

    final focused = _touched >= 0 && _touched < widget.data.length
        ? widget.data[_touched]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: [
                    for (var i = 0; i < widget.data.length; i++)
                      PieChartSectionData(
                        value: widget.data[i].value,
                        color: widget.data[i].color,
                        radius: _touched == i ? baseRadius + 8 : baseRadius,
                        title: '',
                      ),
                  ],
                  centerSpaceRadius: widget.centerSpaceRadius,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touched = -1;
                          return;
                        }
                        _touched =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
              _Center(
                title: focused?.label ?? widget.centerTitle ?? '',
                value: focused != null
                    ? '${(focused.value / safeTotal * 100).round()}%'
                    : widget.centerValue ?? '',
                color: focused?.color ?? AppColors.textPrimary,
                visible: widget.centerSpaceRadius > 0,
              ),
            ],
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < widget.data.length; i++)
                _LegendItem(
                  datum: widget.data[i],
                  share: widget.data[i].value / safeTotal,
                  active: _touched == i,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Center extends StatelessWidget {
  const _Center({
    required this.title,
    required this.value,
    required this.color,
    this.visible = true,
  });
  final String title;
  final String value;
  final Color color;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value.isNotEmpty)
          Text(value, style: AppTextStyles.numeric.copyWith(fontSize: 22)),
        if (title.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.overline.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.datum,
    required this.share,
    required this.active,
  });

  final PieDatum datum;
  final double share;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: datum.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          datum.label,
          style: AppTextStyles.label.copyWith(
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(share * 100).round()}%',
          style: AppTextStyles.overline.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
