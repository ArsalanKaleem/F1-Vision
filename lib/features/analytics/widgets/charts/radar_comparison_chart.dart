import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One entrant on the radar (values already normalised to 0..100, aligned to
/// the chart's [axes]).
class RadarSeriesData {
  const RadarSeriesData({
    required this.label,
    required this.color,
    required this.values,
  });
  final String label;
  final Color color;
  final List<double> values;
}

/// A multi-axis radar chart for head-to-head comparison across normalised
/// metrics (wins, podiums, poles, points, …). Values are expected on a 0..100
/// scale so differently-scaled metrics stay comparable.
class RadarComparisonChart extends StatelessWidget {
  const RadarComparisonChart({
    super.key,
    required this.axes,
    required this.series,
    this.size = 250,
  });

  final List<String> axes;
  final List<RadarSeriesData> series;
  final double size;

  @override
  Widget build(BuildContext context) {
    final valid = series
        .where((s) => s.values.length == axes.length && axes.length >= 3)
        .toList();
    if (valid.isEmpty) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text('Not enough data to compare',
              style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              radarBackgroundColor: Colors.transparent,
              radarBorderData:
                  BorderSide(color: AppColors.surfaceStroke, width: 1),
              gridBorderData: BorderSide(
                  color: AppColors.surfaceStroke.withValues(alpha: 0.5),
                  width: 1),
              tickBorderData: const BorderSide(color: Colors.transparent),
              tickCount: 4,
              ticksTextStyle:
                  const TextStyle(color: Colors.transparent, fontSize: 1),
              titlePositionPercentageOffset: 0.16,
              titleTextStyle: AppTextStyles.overline.copyWith(fontSize: 10),
              getTitle: (index, angle) => RadarChartTitle(
                text: index < axes.length ? axes[index] : '',
                angle: 0,
              ),
              radarTouchData: RadarTouchData(enabled: true),
              dataSets: [
                for (final s in valid)
                  RadarDataSet(
                    dataEntries: [
                      for (final v in s.values) RadarEntry(value: v),
                    ],
                    fillColor: s.color.withValues(alpha: 0.14),
                    borderColor: s.color,
                    borderWidth: 2,
                    entryRadius: 2.5,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final s in valid)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: s.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(s.label, style: AppTextStyles.label),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
