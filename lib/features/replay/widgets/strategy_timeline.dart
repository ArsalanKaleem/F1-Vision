import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'studio_panel.dart';

/// Tyre strategy for the whole field: one row per driver, one block per stint,
/// coloured by compound and sized by stint length. Hovering (or long-pressing)
/// a block reveals the stint window, its duration and the places gained or
/// lost across the stop that started it.
class StrategyTimeline extends ConsumerWidget {
  const StrategyTimeline({super.key, required this.replay});
  final RaceReplay replay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lap = ref.watch(
      replayPlaybackProvider(replay.totalLaps).select((s) => s.lap),
    );
    final total = replay.totalLaps;
    final withStints =
        replay.drivers.where((d) => d.stints.isNotEmpty).toList();

    if (withStints.isEmpty) {
      return const StudioPanel(
        title: 'Tyre Strategy',
        subtitle: 'Stints by driver',
        child: PanelNotice(
          message: 'No pit-stop or stint data is published for this event.',
          icon: Icons.donut_large_outlined,
        ),
      );
    }

    final knownCompounds = <String>{
      for (final d in withStints)
        for (final s in d.stints)
          if (s.compound.toUpperCase() != 'UNKNOWN') s.compound.toUpperCase(),
    };

    return StudioPanel(
      title: 'Tyre Strategy',
      subtitle: knownCompounds.isEmpty
          ? 'Stint windows from pit-stop laps'
          : 'Stints by driver',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (knownCompounds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Compound data needs a telemetry provider (2023 onward). '
                'Stint windows below are derived from pit-stop laps.',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),
          for (final driver in withStints)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      driver.shortName,
                      style: AppTextStyles.label
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StintBar(
                      driver: driver,
                      totalLaps: total,
                      currentLap: lap,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final compound in _legendOrder(knownCompounds))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.tyreColor(compound),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(_pretty(compound), style: AppTextStyles.overline),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static List<String> _legendOrder(Set<String> present) {
    const order = ['SOFT', 'MEDIUM', 'HARD', 'INTERMEDIATE', 'WET'];
    final out = order.where(present.contains).toList();
    return out.isEmpty ? const [] : out;
  }

  static String _pretty(String compound) =>
      compound[0] + compound.substring(1).toLowerCase();
}

class _StintBar extends StatelessWidget {
  const _StintBar({
    required this.driver,
    required this.totalLaps,
    required this.currentLap,
  });

  final ReplayDriver driver;
  final int totalLaps;
  final int currentLap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final safeTotal = totalLaps <= 0 ? 1 : totalLaps;
        double widthFor(int laps) => (laps / safeTotal) * width;

        return SizedBox(
          height: 18,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              for (final stint in driver.stints)
                Positioned(
                  left: widthFor(stint.startLap - 1),
                  width: widthFor(stint.duration).clamp(2.0, width).toDouble(),
                  top: 0,
                  bottom: 0,
                  child: _StintBlock(stint: stint, driver: driver),
                ),
              // Playhead across every driver row keeps the strategy view in
              // sync with the rest of the studio.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                left: (widthFor(currentLap) - 1).clamp(0.0, width - 2).toDouble(),
                top: -2,
                bottom: -2,
                child: Container(
                  width: 2,
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StintBlock extends StatelessWidget {
  const _StintBlock({required this.stint, required this.driver});
  final TyreStint stint;
  final ReplayDriver driver;

  @override
  Widget build(BuildContext context) {
    final known = stint.compound.toUpperCase() != 'UNKNOWN';
    final color = known ? stint.color : driver.color;
    final delta = stint.positionDelta;

    final detail = StringBuffer()
      ..write('${driver.shortName} · ')
      ..write(known ? stint.compound.toUpperCase() : 'Compound unknown')
      ..write('\nLaps ${stint.startLap}–${stint.endLap} (${stint.duration})');
    if (stint.positionBefore != null && stint.positionAfter != null) {
      detail.write(
        '\nPit: P${stint.positionBefore} → P${stint.positionAfter}',
      );
      if (delta != null && delta != 0) {
        detail.write(delta > 0 ? ' (+$delta)' : ' ($delta)');
      }
    }

    return Tooltip(
      message: detail.toString(),
      waitDuration: const Duration(milliseconds: 150),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: known ? 0.85 : 0.45),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 1),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '${stint.duration}',
              style: AppTextStyles.overline.copyWith(
                fontSize: 9,
                color: Colors.black.withValues(alpha: 0.8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
