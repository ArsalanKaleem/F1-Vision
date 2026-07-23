import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'driver_filter.dart';
import 'studio_panel.dart';

/// Every selected driver's track position across the race. The Y axis is
/// inverted (P1 on top); a crosshair marks the current replay lap and hovering
/// reveals each driver's position on that lap.
class PositionHistoryChart extends ConsumerWidget {
  const PositionHistoryChart({super.key, required this.replay});
  final RaceReplay replay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(focusedDriversProvider);
    final lap = ref.watch(
      replayPlaybackProvider(replay.totalLaps).select((s) => s.lap),
    );
    final drivers = effectiveDrivers(replay, focused, fallback: 8);
    final fieldSize = replay.drivers.length;
    final maxY = (fieldSize + 1).toDouble();

    return StudioPanel(
      title: 'Position History',
      subtitle: 'Track position every lap · P1 on top',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DriverFilterBar(replay: replay),
          const SizedBox(height: 14),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: replay.totalLaps.toDouble(),
                minY: 0.5,
                maxY: maxY,
                clipData: const FlClipData.all(),
                lineBarsData: [
                  for (final driver in drivers)
                    _series(driver, replay),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: fieldSize <= 10 ? 2 : 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.surfaceStroke.withValues(alpha: 0.35),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: fieldSize <= 10 ? 2 : 4,
                      getTitlesWidget: (value, meta) {
                        if (value < 1 || value > fieldSize) {
                          return const SizedBox.shrink();
                        }
                        return Text('P${value.round()}',
                            style:
                                AppTextStyles.overline.copyWith(fontSize: 9));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: _lapInterval(replay.totalLaps),
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(value.round().toString(),
                            style:
                                AppTextStyles.overline.copyWith(fontSize: 9)),
                      ),
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: lap.toDouble(),
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: const [4, 4],
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceHigh,
                    tooltipRoundedRadius: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    maxContentWidth: 160,
                    getTooltipItems: (spots) => spots.map((spot) {
                      final driver = spot.barIndex < drivers.length
                          ? drivers[spot.barIndex]
                          : null;
                      return LineTooltipItem(
                        '${driver?.shortName ?? ''}  P${spot.y.round()}',
                        AppTextStyles.label.copyWith(
                          color: driver?.color ?? AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _series(ReplayDriver driver, RaceReplay replay) {
    final entries = replay.byDriver[driver.driverId] ?? const <LapEntry>[];
    final spots = <FlSpot>[
      for (final e in entries) FlSpot(e.lap.toDouble(), e.position.toDouble()),
    ];
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: driver.color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  static double _lapInterval(int totalLaps) {
    if (totalLaps <= 20) return 5;
    if (totalLaps <= 40) return 10;
    return 15;
  }
}
