import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import 'charts/analytics_line_chart.dart';
import 'analytics_panel.dart';

/// Cumulative championship points per round for the leading drivers — an
/// animated, zoomable multi-line chart. This is the hero panel of the board.
class ChampionshipProgressPanel extends StatelessWidget {
  const ChampionshipProgressPanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    final top = data.drivers.take(6).toList();
    final series = [
      for (final d in top)
        LineSeries(label: d.shortName, color: d.color, values: d.cumulativePoints),
    ];
    return AnalyticsPanel(
      title: 'Championship Progress',
      subtitle: 'Cumulative points · top ${top.length}',
      glow: true,
      child: AnalyticsLineChart(
        series: series,
        xLabels: data.roundLabels,
        height: 260,
        enableZoom: true,
      ),
    );
  }
}

/// Cumulative points per round for the top constructors, drawn as soft area
/// lines to read as "trends".
class TeamTrendsPanel extends StatelessWidget {
  const TeamTrendsPanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    final top = data.constructors.take(4).toList();
    final series = [
      for (final c in top)
        LineSeries(
          label: c.name,
          color: c.color,
          values: c.cumulativePoints,
          area: true,
        ),
    ];
    return AnalyticsPanel(
      title: 'Team Performance Trends',
      subtitle: 'Cumulative constructor points',
      child: AnalyticsLineChart(
        series: series,
        xLabels: data.roundLabels,
        height: 220,
      ),
    );
  }
}
