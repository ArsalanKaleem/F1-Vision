import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../models/analytics.dart';
import 'charts/donut_chart.dart';
import 'charts/horizontal_bar_chart.dart';
import 'analytics_panel.dart';

String _fmtPoints(double p) =>
    p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1);

/// Driver championship points as a ranked horizontal bar chart.
class DriverRankingsPanel extends StatelessWidget {
  const DriverRankingsPanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    final top = data.drivers.take(10).toList();
    final bars = [
      for (final d in top)
        BarDatum(
          label: d.shortName,
          value: d.points,
          color: d.color,
          trailing: _fmtPoints(d.points),
          tooltip:
              '${d.name} · ${_fmtPoints(d.points)} pts · P${d.championshipPosition}',
        ),
    ];
    return AnalyticsPanel(
      title: 'Driver Performance Rankings',
      subtitle: 'Championship points',
      glow: true,
      child: HorizontalBarChart(data: bars),
    );
  }
}

/// Constructor points share as a donut, with the season total in the middle.
class ConstructorPerformancePanel extends StatelessWidget {
  const ConstructorPerformancePanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    final top = data.constructors.take(8).toList();
    final pie = [
      for (final c in top)
        PieDatum(label: _short(c.name), value: c.points, color: c.color),
    ];
    return AnalyticsPanel(
      title: 'Constructor Performance',
      subtitle: 'Points share',
      child: Center(
        child: DonutChart(
          data: pie,
          centerSpaceRadius: 0,
          size: 190,
        ),
      ),
    );
  }

  static String _short(String name) {
    const map = {
      'Red Bull': 'Red Bull',
      'Red Bull Racing': 'Red Bull',
      'Aston Martin': 'Aston',
      'Racing Bulls': 'RB',
      'RB F1 Team': 'RB',
      'Kick Sauber': 'Sauber',
      'Haas F1 Team': 'Haas',
    };
    return map[name] ?? name.split(' ').first;
  }
}

/// Mean fastest-lap speed as a proxy for race pace, ranked. Bars are drawn
/// relative to the slowest of the shown drivers so the small differences at
/// the top of the field stay legible.
class RacePacePanel extends StatelessWidget {
  const RacePacePanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    final withPace = data.drivers.where((d) => d.avgPaceKmh > 0).toList()
      ..sort((a, b) => b.avgPaceKmh.compareTo(a.avgPaceKmh));
    final top = withPace.take(10).toList();

    if (top.isEmpty) {
      return const AnalyticsPanel(
        title: 'Average Race Pace',
        subtitle: 'Mean fastest-lap speed',
        child: _NoData(),
      );
    }

    final slowest = top.map((d) => d.avgPaceKmh).reduce((a, b) => a < b ? a : b);
    final floor = slowest - 1.5;
    final bars = [
      for (final d in top)
        BarDatum(
          label: d.shortName,
          value: (d.avgPaceKmh - floor).clamp(0.1, double.infinity).toDouble(),
          color: d.color,
          trailing: d.avgPaceKmh.toStringAsFixed(0),
          tooltip:
              '${d.name} · ${d.avgPaceKmh.toStringAsFixed(1)} km/h avg fastest lap',
        ),
    ];
    return AnalyticsPanel(
      title: 'Average Race Pace',
      subtitle: 'Mean fastest-lap speed (km/h)',
      child: HorizontalBarChart(data: bars),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text('No data for this season',
            style: AppTextStyles.body, textAlign: TextAlign.center),
      );
}
