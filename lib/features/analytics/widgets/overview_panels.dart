import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/analytics.dart';
import 'charts/progress_ring.dart';
import 'analytics_panel.dart';

/// High-level season summary: finish/DNF rings plus headline metric tiles.
class SeasonStatsPanel extends StatelessWidget {
  const SeasonStatsPanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    // Use the repository's untruncated totals; fall back to the display
    // slices only if an older payload didn't carry them.
    final totalStatus = data.statusTotal > 0
        ? data.statusTotal
        : data.statusSlices.fold<int>(0, (a, b) => a + b.count);
    final finished = data.statusTotal > 0
        ? data.classifiedCount
        : data.statusSlices
            .where((s) => s.label == 'Finished' || s.label.startsWith('+'))
            .fold<int>(0, (a, b) => a + b.count);
    final finishRate = totalStatus > 0 ? finished / totalStatus : 0.0;
    final totalDnfs = data.drivers.fold<int>(0, (a, b) => a + b.dnfs);
    final leader = data.drivers.isNotEmpty ? data.drivers.first : null;

    return AnalyticsPanel(
      title: 'Season Statistics',
      subtitle: '${data.season} · ${data.totalRounds} rounds',
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 16,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              ProgressRing(
                fraction: finishRate,
                label: 'Finish rate',
                color: AppColors.positive,
              ),
              ProgressRing(
                fraction: totalStatus > 0 ? 1 - finishRate : 0,
                label: 'Retirement rate',
                color: AppColors.negative,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 26,
            runSpacing: 16,
            children: [
              MetricTile(label: 'Rounds', value: '${data.totalRounds}'),
              MetricTile(label: 'Drivers', value: '${data.drivers.length}'),
              MetricTile(label: 'Teams', value: '${data.constructors.length}'),
              MetricTile(
                  label: 'Total DNFs',
                  value: '$totalDnfs',
                  color: AppColors.negative),
              if (leader != null)
                MetricTile(
                  label: 'Leader',
                  value: leader.shortName,
                  caption: '${leader.points.toStringAsFixed(0)} pts',
                  color: leader.color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pit-stop analytics for the most recent race of the season.
class PitStopPanel extends StatelessWidget {
  const PitStopPanel({super.key, required this.data});
  final SeasonAnalytics data;

  @override
  Widget build(BuildContext context) {
    final pit = data.pit;
    return AnalyticsPanel(
      title: 'Average Pit Stop Time',
      subtitle: pit != null ? pit.raceName : 'Latest race',
      child: pit == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Pit-stop data unavailable for this season.'),
            )
          : Wrap(
              spacing: 26,
              runSpacing: 16,
              children: [
                MetricTile(
                  label: 'Avg stop',
                  value: '${pit.avgSeconds.toStringAsFixed(2)}s',
                  icon: Icons.timer_outlined,
                ),
                MetricTile(
                  label: 'Fastest',
                  value: '${pit.fastestSeconds.toStringAsFixed(2)}s',
                  caption: pit.fastestLabel,
                  color: AppColors.positive,
                  icon: Icons.bolt_rounded,
                ),
                MetricTile(
                  label: 'Stops',
                  value: '${pit.stops}',
                  icon: Icons.tune_rounded,
                ),
              ],
            ),
    );
  }
}
