import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/analytics.dart';
import 'charts/donut_chart.dart';
import 'charts/scatter_plot.dart';
import 'analytics_panel.dart';

/// Season finish-status breakdown (Finished / lapped / mechanical / crashes)
/// as a donut — the reliability & DNF picture.
class DnfPanel extends StatelessWidget {
  const DnfPanel({super.key, required this.data});
  final SeasonAnalytics data;

  static const _palette = [
    AppColors.warning,
    AppColors.negative,
    AppColors.accent,
    Color(0xFF9B59B6),
    Color(0xFF00BCD4),
    Color(0xFFEC407A),
  ];

  Color _colorFor(String label, int index) {
    if (label == 'Finished') return AppColors.positive;
    if (label.startsWith('+')) return AppColors.info;
    return _palette[index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final total = data.statusSlices.fold<int>(0, (a, b) => a + b.count);
    final pie = [
      for (var i = 0; i < data.statusSlices.length; i++)
        PieDatum(
          label: data.statusSlices[i].label,
          value: data.statusSlices[i].count.toDouble(),
          color: _colorFor(data.statusSlices[i].label, i),
        ),
    ];
    return AnalyticsPanel(
      title: 'DNFs & Reliability',
      subtitle: 'Finish-status breakdown',
      child: Center(
        child: DonutChart(
          data: pie,
          centerTitle: 'Results',
          centerValue: '$total',
        ),
      ),
    );
  }
}

/// Average finishing position vs championship points — a scatter that shows how
/// efficiently each driver converts race pace into points. Team-coloured dots.
class AverageFinishPanel extends StatelessWidget {
  const AverageFinishPanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    final points = [
      for (final d in data.drivers.where((d) => d.avgFinish > 0))
        ScatterPoint(
          x: d.avgFinish,
          y: d.points,
          color: d.color,
          label: '${d.shortName} · avg P${d.avgFinish.toStringAsFixed(1)}',
        ),
    ];
    return AnalyticsPanel(
      title: 'Average Finish Position',
      subtitle: 'Avg finish vs points earned',
      child: ScatterPlot(
        points: points,
        xTitle: 'Average finish position →',
        yTitle: 'Points',
      ),
    );
  }
}
