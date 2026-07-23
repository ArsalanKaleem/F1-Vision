import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'driver_filter.dart';
import 'studio_panel.dart';

/// Which series the lap-analysis chart is plotting.
enum LapMetric {
  lapTime('Lap Time'),
  sector1('Sector 1'),
  sector2('Sector 2'),
  sector3('Sector 3'),
  averagePace('Avg Pace'),
  deltaToLeader('Delta to Leader');

  const LapMetric(this.label);
  final String label;

  bool get needsTelemetry =>
      this == LapMetric.sector1 ||
      this == LapMetric.sector2 ||
      this == LapMetric.sector3;
}

final _lapMetricProvider =
    StateProvider.autoDispose<LapMetric>((ref) => LapMetric.lapTime);

/// Lap-time and pace analysis. A segmented control switches between lap time,
/// the three sectors, a rolling average pace and the delta to the leader.
/// Sector metrics require an enrichment provider; when none is present the
/// chart says so instead of drawing an empty frame.
class LapAnalysisChart extends ConsumerWidget {
  const LapAnalysisChart({super.key, required this.replay});
  final RaceReplay replay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(_lapMetricProvider);
    final focused = ref.watch(focusedDriversProvider);
    final drivers = effectiveDrivers(replay, focused, fallback: 5);

    return StudioPanel(
      title: 'Lap Time Analysis',
      subtitle: metric.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricSelector(
            selected: metric,
            hasTelemetry: replay.hasTelemetry,
            onSelected: (m) =>
                ref.read(_lapMetricProvider.notifier).state = m,
          ),
          const SizedBox(height: 12),
          DriverFilterBar(replay: replay),
          const SizedBox(height: 14),
          if (metric.needsTelemetry && !replay.hasTelemetry)
            const PanelNotice(
              message:
                  'Sector times need a telemetry provider (2023 onward).',
              icon: Icons.timeline_outlined,
            )
          else
            _Chart(replay: replay, drivers: drivers, metric: metric),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.replay,
    required this.drivers,
    required this.metric,
  });

  final RaceReplay replay;
  final List<ReplayDriver> drivers;
  final LapMetric metric;

  @override
  Widget build(BuildContext context) {
    final series = <_Series>[];
    for (final driver in drivers) {
      final values = _values(driver);
      if (values.any((v) => v != null)) {
        series.add(_Series(driver, values));
      }
    }

    if (series.isEmpty) {
      return const PanelNotice(
        message: 'No timing available for the selected drivers.',
        icon: Icons.query_stats_outlined,
      );
    }

    double? lo, hi;
    for (final s in series) {
      for (final v in s.values) {
        if (v == null) continue;
        lo = lo == null ? v : (v < lo ? v : lo);
        hi = hi == null ? v : (v > hi ? v : hi);
      }
    }
    lo ??= 0;
    hi ??= 1;
    final pad = ((hi - lo) * 0.1).clamp(0.2, 20.0);
    final minY = metric == LapMetric.deltaToLeader ? 0.0 : (lo - pad);
    final maxY = hi + pad;

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: replay.totalLaps.toDouble(),
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          lineBarsData: [
            for (final s in series)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < s.values.length; i++)
                    if (s.values[i] != null)
                      FlSpot((i + 1).toDouble(), s.values[i]!),
                ],
                isCurved: false,
                color: s.driver.color,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.surfaceStroke.withValues(alpha: 0.3),
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    metric == LapMetric.deltaToLeader
                        ? '+${value.toStringAsFixed(0)}'
                        : _short(value),
                    style: AppTextStyles.overline.copyWith(fontSize: 9),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: replay.totalLaps <= 20
                    ? 5
                    : replay.totalLaps <= 40
                        ? 10
                        : 15,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(value.round().toString(),
                      style: AppTextStyles.overline.copyWith(fontSize: 9)),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceHigh,
              tooltipRoundedRadius: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              maxContentWidth: 180,
              getTooltipItems: (spots) => spots.map((spot) {
                final s = spot.barIndex < series.length
                    ? series[spot.barIndex]
                    : null;
                final label = metric == LapMetric.deltaToLeader
                    ? '+${spot.y.toStringAsFixed(1)}s'
                    : Formatters.lapTime(spot.y);
                return LineTooltipItem(
                  '${s?.driver.shortName ?? ''}  $label',
                  AppTextStyles.label.copyWith(
                    color: s?.driver.color ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<double?> _values(ReplayDriver driver) {
    final entries = replay.byDriver[driver.driverId] ?? const <LapEntry>[];
    final total = replay.totalLaps;
    final byLap = List<LapEntry?>.filled(total, null);
    for (final e in entries) {
      if (e.lap >= 1 && e.lap <= total) byLap[e.lap - 1] = e;
    }

    switch (metric) {
      case LapMetric.lapTime:
        return [for (final e in byLap) _sane(e?.lapSeconds)];
      case LapMetric.sector1:
        return [for (final e in byLap) e?.sector1];
      case LapMetric.sector2:
        return [for (final e in byLap) e?.sector2];
      case LapMetric.sector3:
        return [for (final e in byLap) e?.sector3];
      case LapMetric.deltaToLeader:
        return [for (final e in byLap) e == null ? null : e.gapToLeader];
      case LapMetric.averagePace:
        final out = <double?>[];
        final window = <double>[];
        for (final e in byLap) {
          final v = _sane(e?.lapSeconds);
          if (v != null) {
            window.add(v);
            if (window.length > 5) window.removeAt(0);
          }
          out.add(window.isEmpty
              ? null
              : window.reduce((a, b) => a + b) / window.length);
        }
        return out;
    }
  }

  /// Filters out in/out laps and safety-car laps that would blow up the axis.
  double? _sane(double? seconds) {
    if (seconds == null) return null;
    if (seconds <= 0 || seconds > 600) return null;
    return seconds;
  }

  static String _short(double seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return s.toStringAsFixed(0);
    return '$m:${s.toStringAsFixed(0).padLeft(2, '0')}';
  }
}

class _Series {
  const _Series(this.driver, this.values);
  final ReplayDriver driver;
  final List<double?> values;
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.selected,
    required this.hasTelemetry,
    required this.onSelected,
  });

  final LapMetric selected;
  final bool hasTelemetry;
  final ValueChanged<LapMetric> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final metric in LapMetric.values) ...[
            _Chip(
              label: metric.label,
              selected: metric == selected,
              disabled: metric.needsTelemetry && !hasTelemetry,
              onTap: () => onSelected(metric),
            ),
            if (metric != LapMetric.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.18)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.surfaceStroke,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 11,
              color:
                  selected ? AppColors.accentSoft : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
