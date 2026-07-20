import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One point on a [ScatterPlot].
class ScatterPoint {
  const ScatterPoint({
    required this.x,
    required this.y,
    required this.color,
    required this.label,
    this.radius = 6,
  });
  final double x;
  final double y;
  final Color color;
  final String label;
  final double radius;
}

/// A reusable scatter chart with team-coloured dots and per-point tooltips.
/// Used for relationships like grid position vs finishing position.
class ScatterPlot extends StatelessWidget {
  const ScatterPlot({
    super.key,
    required this.points,
    required this.xTitle,
    required this.yTitle,
    this.height = 240,
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
    this.invertY = false,
  });

  final List<ScatterPoint> points;
  final String xTitle;
  final String yTitle;
  final double height;
  final double? minX;
  final double? maxX;
  final double? minY;
  final double? maxY;

  /// When true the Y axis is flipped by caller-supplied values (caller should
  /// pre-transform); kept for API symmetry.
  final bool invertY;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No data',
              style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
        ),
      );
    }

    var loX = minX ?? points.first.x;
    var hiX = maxX ?? points.first.x;
    var loY = minY ?? points.first.y;
    var hiY = maxY ?? points.first.y;
    for (final p in points) {
      if (p.x < loX) loX = p.x;
      if (p.x > hiX) hiX = p.x;
      if (p.y < loY) loY = p.y;
      if (p.y > hiY) hiY = p.y;
    }
    final padX = ((hiX - loX).abs() * 0.1).clamp(1.0, 100.0);
    final padY = ((hiY - loY).abs() * 0.1).clamp(1.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(yTitle, style: AppTextStyles.overline),
        ),
        SizedBox(
          height: height,
          child: ScatterChart(
            ScatterChartData(
              minX: (minX ?? loX) - padX,
              maxX: (maxX ?? hiX) + padX,
              minY: (minY ?? loY) - padY,
              maxY: (maxY ?? hiY) + padY,
              scatterSpots: [
                for (final p in points)
                  ScatterSpot(
                    p.x,
                    p.y,
                    dotPainter: FlDotCirclePainter(
                      color: p.color.withValues(alpha: 0.85),
                      radius: p.radius,
                    ),
                  ),
              ],
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.surfaceStroke.withValues(alpha: 0.35),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: AppColors.surfaceStroke.withValues(alpha: 0.35),
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
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(
                      value.round().toString(),
                      style: AppTextStyles.overline.copyWith(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(value.round().toString(),
                          style: AppTextStyles.overline.copyWith(fontSize: 10)),
                    ),
                  ),
                ),
              ),
              scatterTouchData: ScatterTouchData(
                enabled: true,
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceHigh,
                  getTooltipItems: (spot) {
                    ScatterPoint? match;
                    for (final p in points) {
                      if ((p.x - spot.x).abs() < 1e-6 &&
                          (p.y - spot.y).abs() < 1e-6) {
                        match = p;
                        break;
                      }
                    }
                    return ScatterTooltipItem(
                      match?.label ?? '',
                      textStyle: AppTextStyles.label.copyWith(
                        color: match?.color ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      bottomMargin: 8,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 4),
          child: Text(xTitle,
              textAlign: TextAlign.right, style: AppTextStyles.overline),
        ),
      ],
    );
  }
}
