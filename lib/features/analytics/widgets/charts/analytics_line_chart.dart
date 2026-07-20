import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One line/area series.
class LineSeries {
  const LineSeries({
    required this.label,
    required this.color,
    required this.values,
    this.area = false,
  });

  final String label;
  final Color color;
  final List<double> values; // aligned to the chart's x labels
  final bool area;
}

/// A reusable multi-series line (or area) chart: animated, with a legend,
/// tooltips, a shared crosshair, and optional button-driven zoom / pan. Used for
/// Championship Progress (lines) and Team Performance Trends (area).
class AnalyticsLineChart extends StatefulWidget {
  const AnalyticsLineChart({
    super.key,
    required this.series,
    required this.xLabels,
    this.height = 240,
    this.maxY,
    this.yInterval,
    this.enableZoom = false,
  });

  final List<LineSeries> series;
  final List<String> xLabels;
  final double height;
  final double? maxY;
  final double? yInterval;
  final bool enableZoom;

  @override
  State<AnalyticsLineChart> createState() => _AnalyticsLineChartState();
}

class _AnalyticsLineChartState extends State<AnalyticsLineChart> {
  double? _hover;
  double? _start;
  double? _end;

  int get _n => widget.xLabels.length;

  void _zoom(double factor) {
    final maxX = (_n - 1).toDouble();
    var start = _start ?? 0.0;
    var end = _end ?? maxX;
    final center = (start + end) / 2;
    var half = (end - start) / 2 * factor;
    if (half < 1) half = 1;
    start = (center - half).clamp(0, maxX).toDouble();
    end = (center + half).clamp(0, maxX).toDouble();
    if (end - start < 1) return;
    setState(() {
      _start = start;
      _end = end;
    });
  }

  void _pan(double dir) {
    final maxX = (_n - 1).toDouble();
    var start = _start ?? 0.0;
    var end = _end ?? maxX;
    final width = end - start;
    final shift = width * 0.3 * dir;
    start += shift;
    end += shift;
    if (start < 0) {
      start = 0;
      end = width;
    }
    if (end > maxX) {
      end = maxX;
      start = maxX - width;
    }
    setState(() {
      _start = start;
      _end = end;
    });
  }

  void _reset() => setState(() {
        _start = null;
        _end = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_n < 2 || widget.series.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text('Not enough data yet',
              style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
        ),
      );
    }

    final maxX = (_n - 1).toDouble();
    final minX = _start ?? 0.0;
    final maxXView = _end ?? maxX;

    var computedMax = widget.maxY ?? 0.0;
    if (widget.maxY == null) {
      for (final s in widget.series) {
        for (final v in s.values) {
          if (v > computedMax) computedMax = v;
        }
      }
      computedMax = computedMax <= 0 ? 1 : computedMax * 1.1;
    }
    final interval = widget.yInterval ?? (computedMax / 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Legend(series: widget.series),
        const SizedBox(height: 10),
        SizedBox(
          height: widget.height,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxXView,
              minY: 0,
              maxY: computedMax,
              clipData: const FlClipData.all(),
              lineBarsData: [
                for (final s in widget.series)
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < s.values.length; i++)
                        FlSpot(i.toDouble(), s.values[i]),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.2,
                    preventCurveOverShooting: true,
                    color: s.color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: s.area,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          s.color.withValues(alpha: 0.30),
                          s.color.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
              ],
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval <= 0 ? 1 : interval,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.surfaceStroke.withValues(alpha: 0.4),
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
                    reservedSize: 34,
                    interval: interval <= 0 ? 1 : interval,
                    getTitlesWidget: (value, meta) {
                      if (value > computedMax - (interval * 0.1)) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.round().toString(),
                        style: AppTextStyles.overline.copyWith(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: ((maxXView - minX) / 5).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= widget.xLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(widget.xLabels[i],
                            style: AppTextStyles.overline.copyWith(fontSize: 9)),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: _hover == null
                    ? const []
                    : [
                        VerticalLine(
                          x: _hover!,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          strokeWidth: 1,
                          dashArray: const [4, 4],
                        ),
                      ],
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceHigh,
                  tooltipRoundedRadius: 8,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final s = spot.barIndex < widget.series.length
                        ? widget.series[spot.barIndex]
                        : null;
                    return LineTooltipItem(
                      '${s?.label ?? ''}  ${spot.y.round()}',
                      AppTextStyles.label.copyWith(
                        color: s?.color ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                touchCallback: (event, response) {
                  if (event is FlPointerExitEvent || event is FlTapUpEvent) {
                    setState(() => _hover = null);
                    return;
                  }
                  final spots = response?.lineBarSpots;
                  if (spots != null && spots.isNotEmpty) {
                    setState(() => _hover = spots.first.x);
                  }
                },
              ),
            ),
          ),
        ),
        if (widget.enableZoom) ...[
          const SizedBox(height: 6),
          _ZoomBar(
            onZoomIn: () => _zoom(0.6),
            onZoomOut: () => _zoom(1.6),
            onPanLeft: () => _pan(-1),
            onPanRight: () => _pan(1),
            onReset: _reset,
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.series});
  final List<LineSeries> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final s in series)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 3,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(s.label, style: AppTextStyles.label),
            ],
          ),
      ],
    );
  }
}

class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onPanLeft,
    required this.onPanRight,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onPanLeft;
  final VoidCallback onPanRight;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback onTap) => IconButton(
          onPressed: onTap,
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          color: AppColors.textSecondary,
          icon: Icon(icon),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        btn(Icons.chevron_left_rounded, onPanLeft),
        btn(Icons.remove_rounded, onZoomOut),
        btn(Icons.add_rounded, onZoomIn),
        btn(Icons.chevron_right_rounded, onPanRight),
        btn(Icons.refresh_rounded, onReset),
      ],
    );
  }
}
