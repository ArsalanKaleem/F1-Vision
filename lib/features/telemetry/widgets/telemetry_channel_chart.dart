import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/telemetry.dart';

/// One series within a [TelemetryChannelChart].
class ChannelSeries {
  const ChannelSeries({
    required this.label,
    required this.color,
    required this.selector,
    this.area = true,
  });

  final String label;
  final Color color;
  final double Function(TelemetrySample) selector;
  final bool area;
}

/// A single synchronized telemetry trace (speed, rpm, pedals, …).
///
/// X is the sample index so every chart on the page shares one domain; the
/// parent supplies the visible [minX]/[maxX] viewport (zoom + pan) and the
/// [hoverIndex] crosshair, and is notified back through [onHover]. Charts are
/// wrapped in a [RepaintBoundary] by the parent to isolate repaints.
class TelemetryChannelChart extends StatelessWidget {
  const TelemetryChannelChart({
    super.key,
    required this.samples,
    required this.series,
    required this.minY,
    required this.maxY,
    required this.minX,
    required this.maxX,
    required this.onHover,
    this.hoverIndex,
    this.unit = '',
    this.height = 150,
    this.leftLabel,
  });

  final List<TelemetrySample> samples;
  final List<ChannelSeries> series;
  final double minY;
  final double maxY;
  final double minX;
  final double maxX;
  final ValueChanged<double?> onHover;
  final double? hoverIndex;
  final String unit;
  final double height;
  final String Function(double)? leftLabel;

  String _formatLeft(double v) =>
      leftLabel != null ? leftLabel!(v) : v.round().toString();

  String _timeAt(int index) {
    if (index < 0 || index >= samples.length) return '';
    final d = samples[index].date.toLocal();
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final span = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY);
    final visible = (maxX - minX).abs() < 1 ? 1.0 : (maxX - minX);

    final bars = <LineChartBarData>[
      for (final s in series)
        LineChartBarData(
          spots: [
            for (var i = 0; i < samples.length; i++)
              FlSpot(i.toDouble(), s.selector(samples[i])),
          ],
          isCurved: true,
          curveSmoothness: 0.18,
          preventCurveOverShooting: true,
          color: s.color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: s.area,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.color.withValues(alpha: 0.32),
                s.color.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          lineBarsData: bars,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: span / 2,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.surfaceStroke.withValues(alpha: 0.45),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: span / 2,
                getTitlesWidget: (value, meta) {
                  if (value > maxY - span * 0.05) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      _formatLeft(value),
                      style: AppTextStyles.overline.copyWith(fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (visible / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _timeAt(i),
                      style: AppTextStyles.overline.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: hoverIndex == null
                ? const []
                : [
                    VerticalLine(
                      x: hoverIndex!,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      strokeWidth: 1,
                      dashArray: const [4, 4],
                    ),
                  ],
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (bar, indexes) {
              return indexes.map<TouchedSpotIndicatorData?>((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: bar.color ?? AppColors.accent, strokeWidth: 1),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, _, b, __) => FlDotCirclePainter(
                      radius: 3,
                      color: b.color ?? AppColors.accent,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceHigh,
              tooltipRoundedRadius: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final s = spot.barIndex < series.length
                      ? series[spot.barIndex]
                      : null;
                  final name = s?.label ?? '';
                  final value = spot.y.round();
                  return LineTooltipItem(
                    '$name  $value${unit.isEmpty ? '' : ' $unit'}',
                    AppTextStyles.label.copyWith(
                      color: s?.color ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
            touchCallback: (event, response) {
              if (event is FlPointerExitEvent || event is FlTapUpEvent) {
                onHover(null);
                return;
              }
              final spots = response?.lineBarSpots;
              if (spots != null && spots.isNotEmpty) {
                onHover(spots.first.x);
              }
            },
          ),
        ),
      ),
    );
  }
}
