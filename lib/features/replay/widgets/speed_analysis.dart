import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'driver_filter.dart';
import 'studio_panel.dart';

/// Speed analysis from the per-lap speed-trap readings: each selected driver's
/// top and average speed, plus a distribution of the field's speed-trap values.
/// Requires an enrichment provider (OpenF1 supplies `st_speed`).
class SpeedAnalysis extends ConsumerWidget {
  const SpeedAnalysis({super.key, required this.replay});
  final RaceReplay replay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!replay.hasTelemetry) {
      return const StudioPanel(
        title: 'Speed Analysis',
        subtitle: 'Speed-trap readings',
        child: PanelNotice(
          message: 'Speed data needs a telemetry provider (2023 onward).',
          icon: Icons.speed_outlined,
        ),
      );
    }

    final focused = ref.watch(focusedDriversProvider);
    final drivers = effectiveDrivers(replay, focused, fallback: 6);

    final stats = <_SpeedStat>[];
    final allSpeeds = <double>[];
    for (final driver in drivers) {
      final entries = replay.byDriver[driver.driverId] ?? const <LapEntry>[];
      final speeds = [
        for (final e in entries)
          if (e.topSpeed != null && e.topSpeed! > 0) e.topSpeed!,
      ];
      if (speeds.isEmpty) continue;
      allSpeeds.addAll(speeds);
      final top = speeds.reduce((a, b) => a > b ? a : b);
      final avg = speeds.reduce((a, b) => a + b) / speeds.length;
      stats.add(_SpeedStat(driver: driver, top: top, average: avg));
    }

    if (stats.isEmpty) {
      return const StudioPanel(
        title: 'Speed Analysis',
        subtitle: 'Speed-trap readings',
        child: PanelNotice(
          message: 'No speed-trap data for the selected drivers.',
          icon: Icons.speed_outlined,
        ),
      );
    }

    stats.sort((a, b) => b.top.compareTo(a.top));

    return StudioPanel(
      title: 'Speed Analysis',
      subtitle: 'Top & average speed (km/h)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DriverFilterBar(replay: replay),
          const SizedBox(height: 16),
          _SpeedBars(stats: stats),
          const SizedBox(height: 20),
          Text('SPEED DISTRIBUTION', style: AppTextStyles.overline),
          const SizedBox(height: 10),
          _Distribution(speeds: allSpeeds),
        ],
      ),
    );
  }
}

class _SpeedStat {
  const _SpeedStat({
    required this.driver,
    required this.top,
    required this.average,
  });
  final ReplayDriver driver;
  final double top;
  final double average;
}

class _SpeedBars extends StatelessWidget {
  const _SpeedBars({required this.stats});
  final List<_SpeedStat> stats;

  @override
  Widget build(BuildContext context) {
    var maxSpeed = 0.0;
    var minSpeed = double.infinity;
    for (final s in stats) {
      if (s.top > maxSpeed) maxSpeed = s.top;
      if (s.average < minSpeed) minSpeed = s.average;
    }
    // Zoom the axis into the meaningful band so small differences read clearly.
    final floor = (minSpeed - 15).clamp(0.0, maxSpeed).toDouble();

    return Column(
      children: [
        for (final s in stats)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(s.driver.shortName,
                      style: AppTextStyles.label
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DualBar(
                    top: s.top,
                    average: s.average,
                    floor: floor,
                    ceil: maxSpeed,
                    color: s.driver.color,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${s.top.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.numeric.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Two overlaid bars: a translucent "average" bar behind a solid "top" cap.
class _DualBar extends StatelessWidget {
  const _DualBar({
    required this.top,
    required this.average,
    required this.floor,
    required this.ceil,
    required this.color,
  });

  final double top;
  final double average;
  final double floor;
  final double ceil;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final span = (ceil - floor) <= 0 ? 1 : (ceil - floor);
    final topFraction = ((top - floor) / span).clamp(0.0, 1.0).toDouble();
    final avgFraction = ((average - floor) / span).clamp(0.0, 1.0).toDouble();

    return Tooltip(
      message:
          'Top ${top.toStringAsFixed(1)} · Avg ${average.toStringAsFixed(1)} km/h',
      child: SizedBox(
        height: 16,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: topFraction),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: avgFraction),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.7), color],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Histogram of speed-trap readings across the selected drivers.
class _Distribution extends StatelessWidget {
  const _Distribution({required this.speeds});
  final List<double> speeds;

  @override
  Widget build(BuildContext context) {
    if (speeds.length < 5) {
      return const PanelNotice(message: 'Not enough samples to bin.');
    }
    var lo = speeds.first, hi = speeds.first;
    for (final s in speeds) {
      if (s < lo) lo = s;
      if (s > hi) hi = s;
    }
    const bins = 10;
    final width = (hi - lo) <= 0 ? 1 : (hi - lo) / bins;
    final counts = List<int>.filled(bins, 0);
    for (final s in speeds) {
      var idx = ((s - lo) / width).floor();
      if (idx < 0) idx = 0;
      if (idx >= bins) idx = bins - 1;
      counts[idx]++;
    }
    final maxCount = counts.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 130,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount * 1.15,
          barGroups: [
            for (var i = 0; i < bins; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: counts[i].toDouble(),
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.accent.withValues(alpha: 0.5),
                        AppColors.accentSoft,
                      ],
                    ),
                  ),
                ],
              ),
          ],
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final speed = lo + value * width;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(speed.toStringAsFixed(0),
                        style: AppTextStyles.overline.copyWith(fontSize: 8)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceHigh,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final from = (lo + group.x * width).toStringAsFixed(0);
                final to = (lo + (group.x + 1) * width).toStringAsFixed(0);
                return BarTooltipItem(
                  '$from–$to km/h\n${rod.toY.round()} laps',
                  AppTextStyles.label.copyWith(color: AppColors.textPrimary),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
