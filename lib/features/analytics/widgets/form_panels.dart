import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../models/analytics.dart';
import 'charts/radar_comparison_chart.dart';
import 'charts/sparkline.dart';
import 'analytics_panel.dart';

/// Recent form: each leading driver's last-5 finishing positions as an inverted
/// sparkline (higher = better result).
class DriverFormPanel extends StatelessWidget {
  const DriverFormPanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    final top = data.drivers.take(6).toList();
    return AnalyticsPanel(
      title: 'Driver Form',
      subtitle: 'Finishing positions · last 5',
      child: Column(
        children: [
          for (final d in top)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(d.shortName,
                        style: AppTextStyles.label
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Sparkline(
                      values: d.last5.map((e) => e.toDouble()).toList(),
                      color: d.color,
                      invert: true,
                      width: double.infinity,
                      height: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 40,
                    child: Text(
                      d.last5.isEmpty ? '—' : 'P${d.last5.last}',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.numeric.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Multi-axis radar comparing the season's title contenders across normalised
/// performance metrics.
class HistoricalComparisonPanel extends StatelessWidget {
  const HistoricalComparisonPanel({super.key, required this.data});
  final SeasonAnalytics data;

  static const _axes = [
    'Points',
    'Wins',
    'Podiums',
    'Poles',
    'Fast Laps',
    'Finish',
  ];

  @override
  Widget build(BuildContext context) {
    final top = data.drivers.take(3).toList();
    if (top.length < 2) {
      return const AnalyticsPanel(
        title: 'Historical Comparison',
        subtitle: 'Title contenders',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text('Not enough classified drivers to compare.'),
        ),
      );
    }

    double finishScore(DriverAggregate d) =>
        d.avgFinish > 0 ? 1 / d.avgFinish : 0;

    final vectors = <List<double>>[
      for (final d in top)
        [
          d.points,
          d.wins.toDouble(),
          d.podiums.toDouble(),
          d.poles.toDouble(),
          d.fastestLaps.toDouble(),
          finishScore(d),
        ],
    ];
    final maxima = List<double>.filled(_axes.length, 0);
    for (final v in vectors) {
      for (var i = 0; i < _axes.length; i++) {
        if (v[i] > maxima[i]) maxima[i] = v[i];
      }
    }
    final series = [
      for (var j = 0; j < top.length; j++)
        RadarSeriesData(
          label: top[j].shortName,
          color: top[j].color,
          values: [
            for (var i = 0; i < _axes.length; i++)
              maxima[i] > 0 ? vectors[j][i] / maxima[i] * 100 : 0.0,
          ],
        ),
    ];

    return AnalyticsPanel(
      title: 'Historical Comparison',
      subtitle: 'Title contenders · normalised',
      child: Center(
        child: RadarComparisonChart(axes: _axes, series: series, size: 260),
      ),
    );
  }
}
