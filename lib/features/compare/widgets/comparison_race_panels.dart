import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/data_panel.dart';
import '../../../models/comparison.dart';
import '../../../models/replay.dart';

/// Shared axis helpers so every race chart lines up on the same lap grid.
double _lapInterval(int totalLaps) {
  if (totalLaps <= 20) return 5;
  if (totalLaps <= 40) return 10;
  return 15;
}

AxisTitles _lapAxis(int totalLaps) => AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        interval: _lapInterval(totalLaps),
        getTitlesWidget: (value, meta) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(value.round().toString(),
              style: AppTextStyles.overline.copyWith(fontSize: 9)),
        ),
      ),
    );

const _hiddenAxis = AxisTitles(sideTitles: SideTitles(showTitles: false));

/// Lap-by-lap pace for both drivers, with pit laps and outliers filtered so
/// the racing laps stay readable.
class LapTimeComparison extends StatelessWidget {
  const LapTimeComparison({super.key, required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    if (!comparison.bothInRace) {
      return const DataPanel(
        title: 'Lap Time Comparison',
        subtitle: 'Racing laps only',
        child: PanelEmptyNote(
          message: 'Pick a race both drivers started.',
          icon: Icons.timer_outlined,
        ),
      );
    }

    final seriesA = _spots(comparison.a);
    final seriesB = _spots(comparison.b);
    if (seriesA.isEmpty && seriesB.isEmpty) {
      return const DataPanel(
        title: 'Lap Time Comparison',
        subtitle: 'Racing laps only',
        child: PanelEmptyNote(
          message: 'No lap timing published for this race.',
          icon: Icons.timer_off_outlined,
        ),
      );
    }

    double lo = double.infinity, hi = 0;
    for (final s in [...seriesA, ...seriesB]) {
      if (s.y < lo) lo = s.y;
      if (s.y > hi) hi = s.y;
    }
    final pad = ((hi - lo) * 0.12).clamp(0.3, 8.0).toDouble();

    return DataPanel(
      title: 'Lap Time Comparison',
      subtitle: 'Racing laps · pit and outlier laps removed',
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            minX: 1,
            maxX: comparison.totalLaps.toDouble(),
            minY: lo - pad,
            maxY: hi + pad,
            clipData: const FlClipData.all(),
            lineBarsData: [
              _bar(seriesA, comparison.a.color),
              _bar(seriesB, comparison.b.color),
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
              topTitles: _hiddenAxis,
              rightTitles: _hiddenAxis,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return const SizedBox.shrink();
                    return Text(Formatters.lapTime(value),
                        style: AppTextStyles.overline.copyWith(fontSize: 8));
                  },
                ),
              ),
              bottomTitles: _lapAxis(comparison.totalLaps),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.surfaceHigh,
                tooltipRoundedRadius: 8,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                maxContentWidth: 180,
                getTooltipItems: (spots) => spots.map((spot) {
                  final side =
                      spot.barIndex == 0 ? comparison.a : comparison.b;
                  return LineTooltipItem(
                    '${side.code}  ${Formatters.lapTime(spot.y)}',
                    AppTextStyles.label.copyWith(
                      color: side.color,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static LineChartBarData _bar(List<FlSpot> spots, Color color) =>
      LineChartBarData(
        spots: spots,
        isCurved: false,
        color: color,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );

  static List<FlSpot> _spots(ComparisonSide side) {
    final clean = side.cleanLapTimes;
    if (clean.isEmpty) return const [];
    final cutoff = clean.reduce((a, b) => a > b ? a : b);
    return [
      for (final l in side.laps)
        if (!l.inPit &&
            l.lapSeconds != null &&
            l.lapSeconds! > 0 &&
            l.lapSeconds! <= cutoff)
          FlSpot(l.lap.toDouble(), l.lapSeconds!),
    ];
  }
}

/// Track position across the race for both drivers (P1 on top).
class PositionComparison extends StatelessWidget {
  const PositionComparison({super.key, required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    if (!comparison.bothInRace) {
      return const DataPanel(
        title: 'Position Changes',
        subtitle: 'Track position every lap',
        child: PanelEmptyNote(
          message: 'Pick a race both drivers started.',
          icon: Icons.swap_vert_rounded,
        ),
      );
    }

    var deepest = 0;
    for (final side in [comparison.a, comparison.b]) {
      for (final l in side.laps) {
        if (l.position > deepest) deepest = l.position;
      }
    }
    final maxY = (deepest + 1).toDouble();

    return DataPanel(
      title: 'Position Changes',
      subtitle: 'Grid to flag · P1 on top',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GainChip(side: comparison.a),
          const SizedBox(width: AppSpacing.sm),
          _GainChip(side: comparison.b),
        ],
      ),
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minX: 1,
            maxX: comparison.totalLaps.toDouble(),
            minY: 0.5,
            maxY: maxY,
            clipData: const FlClipData.all(),
            lineBarsData: [
              _positions(comparison.a),
              _positions(comparison.b),
            ],
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: deepest <= 10 ? 2 : 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.surfaceStroke.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: _hiddenAxis,
              rightTitles: _hiddenAxis,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: deepest <= 10 ? 2 : 4,
                  getTitlesWidget: (value, meta) {
                    if (value < 1 || value > deepest) {
                      return const SizedBox.shrink();
                    }
                    return Text('P${value.round()}',
                        style: AppTextStyles.overline.copyWith(fontSize: 9));
                  },
                ),
              ),
              bottomTitles: _lapAxis(comparison.totalLaps),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.surfaceHigh,
                tooltipRoundedRadius: 8,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (spots) => spots.map((spot) {
                  final side =
                      spot.barIndex == 0 ? comparison.a : comparison.b;
                  return LineTooltipItem(
                    '${side.code}  P${spot.y.round()}',
                    AppTextStyles.label.copyWith(
                      color: side.color,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static LineChartBarData _positions(ComparisonSide side) => LineChartBarData(
        spots: [
          for (final l in side.laps)
            FlSpot(l.lap.toDouble(), l.position.toDouble()),
        ],
        isCurved: false,
        color: side.color,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
}

class _GainChip extends StatelessWidget {
  const _GainChip({required this.side});
  final ComparisonSide side;

  @override
  Widget build(BuildContext context) {
    final gained = side.positionsGained;
    if (gained == null) return const SizedBox.shrink();
    final positive = gained > 0;
    final color = gained == 0
        ? AppColors.textSecondary
        : positive
            ? AppColors.positive
            : AppColors.negative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${side.code} ${gained > 0 ? '+' : ''}$gained',
        style: AppTextStyles.overline.copyWith(fontSize: 9, color: color),
      ),
    );
  }
}

/// Tyre strategy for the two drivers, drawn on a shared lap axis.
class TyreStrategyComparison extends StatelessWidget {
  const TyreStrategyComparison({super.key, required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    final sides = [comparison.a, comparison.b];
    final anyStints = sides.any((s) => s.stints.isNotEmpty);
    if (!anyStints) {
      return const DataPanel(
        title: 'Tyre Strategy',
        subtitle: 'Stints side by side',
        child: PanelEmptyNote(
          message: 'No stint or pit-stop data for this race.',
          icon: Icons.donut_large_outlined,
        ),
      );
    }

    return DataPanel(
      title: 'Tyre Strategy',
      subtitle: 'Stints side by side',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final side in sides) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 46,
                    child: Text(side.code,
                        style: AppTextStyles.label
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StintRow(
                      stints: side.stints,
                      totalLaps: comparison.totalLaps,
                      fallbackColor: side.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            comparison.hasTelemetry
                ? 'Block width is stint length; the number is laps on that set.'
                : 'Compounds need a telemetry provider — windows below come '
                    'from pit-stop laps.',
            style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _StintRow extends StatelessWidget {
  const _StintRow({
    required this.stints,
    required this.totalLaps,
    required this.fallbackColor,
  });

  final List<TyreStint> stints;
  final int totalLaps;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    if (stints.isEmpty) {
      return Text('No stint data',
          style: AppTextStyles.label.copyWith(color: AppColors.textTertiary));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final safeTotal = totalLaps <= 0 ? 1 : totalLaps;
        double widthFor(int laps) => (laps / safeTotal) * width;

        return SizedBox(
          height: 20,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              for (final stint in stints)
                Positioned(
                  left: widthFor(stint.startLap - 1),
                  width: widthFor(stint.duration).clamp(3.0, width).toDouble(),
                  top: 0,
                  bottom: 0,
                  child: _StintBlock(
                      stint: stint, fallbackColor: fallbackColor),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StintBlock extends StatelessWidget {
  const _StintBlock({required this.stint, required this.fallbackColor});
  final TyreStint stint;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final known = stint.compound.toUpperCase() != 'UNKNOWN';
    final color = known ? stint.color : fallbackColor;
    final detail = StringBuffer()
      ..write(known ? stint.compound.toUpperCase() : 'Compound unknown')
      ..write('\nLaps ${stint.startLap}–${stint.endLap} (${stint.duration})');
    if (stint.positionBefore != null && stint.positionAfter != null) {
      detail.write('\nPit: P${stint.positionBefore} → P${stint.positionAfter}');
    }

    return Tooltip(
      message: detail.toString(),
      waitDuration: const Duration(milliseconds: 150),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: known ? 0.85 : 0.45),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text('${stint.duration}',
                style: AppTextStyles.overline.copyWith(
                  fontSize: 9,
                  color: Colors.black.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w800,
                )),
          ),
        ),
      ),
    );
  }
}

/// Every pit stop each driver made, with stationary time where published.
class PitStopComparison extends StatelessWidget {
  const PitStopComparison({super.key, required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    final sides = [comparison.a, comparison.b];
    if (sides.every((s) => s.pitStops.isEmpty)) {
      return const DataPanel(
        title: 'Pit Stops',
        subtitle: 'Stationary time per stop',
        child: PanelEmptyNote(
          message: 'No pit-stop data published for this race.',
          icon: Icons.build_circle_outlined,
        ),
      );
    }

    return DataPanel(
      title: 'Pit Stops',
      subtitle: 'Stationary time per stop',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sides.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            Expanded(child: _PitColumn(side: sides[i])),
          ],
        ],
      ),
    );
  }
}

class _PitColumn extends StatelessWidget {
  const _PitColumn({required this.side});
  final ComparisonSide side;

  @override
  Widget build(BuildContext context) {
    final stops = side.pitStops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: side.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm - 2),
            Text(side.code,
                style: AppTextStyles.label
                    .copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${stops.length}', style: AppTextStyles.overline),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (stops.isEmpty)
          Text('No stops',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textTertiary))
        else
          for (final stop in stops)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('L${stop.lap}',
                        style: AppTextStyles.overline.copyWith(fontSize: 9)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    stop.seconds == null
                        ? '—'
                        : '${stop.seconds!.toStringAsFixed(1)}s',
                    style: AppTextStyles.numeric.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
        if (side.averagePitTime != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('Avg ${side.averagePitTime!.toStringAsFixed(1)}s',
              style: AppTextStyles.overline),
        ],
      ],
    );
  }
}

/// Pace against tyre age — the classic degradation view. Each point is one
/// racing lap, plotted by how many laps old the tyre was.
class DegradationScatter extends StatelessWidget {
  const DegradationScatter({super.key, required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    if (!comparison.bothInRace) {
      return const DataPanel(
        title: 'Pace vs Tyre Age',
        subtitle: 'Degradation profile',
        child: PanelEmptyNote(
          message: 'Pick a race both drivers started.',
          icon: Icons.scatter_plot_outlined,
        ),
      );
    }

    final pointsA = _points(comparison.a);
    final pointsB = _points(comparison.b);
    if (pointsA.isEmpty && pointsB.isEmpty) {
      return const DataPanel(
        title: 'Pace vs Tyre Age',
        subtitle: 'Degradation profile',
        child: PanelEmptyNote(
          message: 'Stint data is needed to compute tyre age.',
          icon: Icons.scatter_plot_outlined,
        ),
      );
    }

    final all = [...pointsA, ...pointsB];
    double loY = double.infinity, hiY = 0, hiX = 0;
    for (final p in all) {
      if (p.y < loY) loY = p.y;
      if (p.y > hiY) hiY = p.y;
      if (p.x > hiX) hiX = p.x;
    }
    final padY = ((hiY - loY) * 0.12).clamp(0.3, 8.0).toDouble();

    return DataPanel(
      title: 'Pace vs Tyre Age',
      subtitle: 'Each point is a racing lap',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 230,
            child: ScatterChart(
              ScatterChartData(
                minX: 0,
                maxX: hiX + 1,
                minY: loY - padY,
                maxY: hiY + padY,
                scatterSpots: [
                  for (final p in pointsA)
                    ScatterSpot(
                      p.x,
                      p.y,
                      dotPainter: FlDotCirclePainter(
                        color: comparison.a.color.withValues(alpha: 0.75),
                        radius: 4,
                      ),
                    ),
                  for (final p in pointsB)
                    ScatterSpot(
                      p.x,
                      p.y,
                      dotPainter: FlDotCirclePainter(
                        color: comparison.b.color.withValues(alpha: 0.75),
                        radius: 4,
                      ),
                    ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.surfaceStroke.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: AppColors.surfaceStroke.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: _hiddenAxis,
                  rightTitles: _hiddenAxis,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) => Text(
                        Formatters.lapTime(value),
                        style: AppTextStyles.overline.copyWith(fontSize: 8),
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
                            style:
                                AppTextStyles.overline.copyWith(fontSize: 9)),
                      ),
                    ),
                  ),
                ),
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  touchTooltipData: ScatterTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceHigh,
                    getTooltipItems: (spot) => ScatterTooltipItem(
                      'Lap age ${spot.x.round()}\n'
                      '${Formatters.lapTime(spot.y)}',
                      textStyle: AppTextStyles.label
                          .copyWith(color: AppColors.textPrimary),
                      bottomMargin: 8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text('TYRE AGE (LAPS) →', style: AppTextStyles.overline),
              const Spacer(),
              _LegendDot(side: comparison.a),
              const SizedBox(width: AppSpacing.md),
              _LegendDot(side: comparison.b),
            ],
          ),
        ],
      ),
    );
  }

  /// Maps each clean racing lap to (tyre age, lap time).
  static List<({double x, double y})> _points(ComparisonSide side) {
    if (side.stints.isEmpty) return const [];
    final clean = side.cleanLapTimes;
    if (clean.isEmpty) return const [];
    final cutoff = clean.reduce((a, b) => a > b ? a : b);

    int? ageFor(int lap) {
      for (final stint in side.stints) {
        if (lap >= stint.startLap && lap <= stint.endLap) {
          return lap - stint.startLap + 1;
        }
      }
      return null;
    }

    final out = <({double x, double y})>[];
    for (final l in side.laps) {
      final seconds = l.lapSeconds;
      if (l.inPit || seconds == null || seconds <= 0 || seconds > cutoff) {
        continue;
      }
      final age = ageFor(l.lap);
      if (age == null) continue;
      out.add((x: age.toDouble(), y: seconds));
    }
    return out;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.side});
  final ComparisonSide side;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration:
              BoxDecoration(color: side.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(side.code, style: AppTextStyles.label),
      ],
    );
  }
}
