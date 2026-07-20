import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../models/analytics.dart';
import 'charts/horizontal_bar_chart.dart';
import 'analytics_panel.dart';

/// Shared builder for the "count per driver" bar panels (poles / fastest laps /
/// podiums). Keeps three visually-identical panels DRY.
class _CountPanel extends StatelessWidget {
  const _CountPanel({
    required this.title,
    required this.subtitle,
    required this.data,
    required this.count,
    required this.noun,
  });

  final String title;
  final String subtitle;
  final SeasonAnalytics data;
  final int Function(DriverAggregate) count;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final ranked = data.drivers.where((d) => count(d) > 0).toList()
      ..sort((a, b) => count(b).compareTo(count(a)));
    final top = ranked.take(10).toList();

    if (top.isEmpty) {
      return AnalyticsPanel(
        title: title,
        subtitle: subtitle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text('No $noun recorded yet',
              style: AppTextStyles.body, textAlign: TextAlign.center),
        ),
      );
    }

    final bars = [
      for (final d in top)
        BarDatum(
          label: d.shortName,
          value: count(d).toDouble(),
          color: d.color,
          trailing: count(d).toString(),
          tooltip: '${d.name} · ${count(d)} $noun',
        ),
    ];
    return AnalyticsPanel(
      title: title,
      subtitle: subtitle,
      child: HorizontalBarChart(data: bars),
    );
  }
}

class PolePositionsPanel extends StatelessWidget {
  const PolePositionsPanel({super.key, required this.data});
  final SeasonAnalytics data;
  @override
  Widget build(BuildContext context) => _CountPanel(
        title: 'Pole Positions',
        subtitle: 'Qualifying P1s',
        data: data,
        count: (d) => d.poles,
        noun: 'poles',
      );
}

class FastestLapsPanel extends StatelessWidget {
  const FastestLapsPanel({super.key, required this.data});
  final SeasonAnalytics data;
  @override
  Widget build(BuildContext context) => _CountPanel(
        title: 'Fastest Laps',
        subtitle: 'Race fastest-lap awards',
        data: data,
        count: (d) => d.fastestLaps,
        noun: 'fastest laps',
      );
}

class PodiumsPanel extends StatelessWidget {
  const PodiumsPanel({super.key, required this.data});
  final SeasonAnalytics data;
  @override
  Widget build(BuildContext context) => _CountPanel(
        title: 'Podiums',
        subtitle: 'Top-3 finishes',
        data: data,
        count: (d) => d.podiums,
        noun: 'podiums',
      );
}
