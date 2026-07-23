import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'studio_panel.dart';

/// The classification at the current lap. Rows keep their identity and slide
/// to new positions with [AnimatedPositioned] — the list is never rebuilt from
/// scratch, so overtakes read as movement rather than a flicker.
class AnimatedLeaderboard extends ConsumerWidget {
  const AnimatedLeaderboard({super.key, required this.replay});
  final RaceReplay replay;

  static const _rowHeight = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lap = ref.watch(
      replayPlaybackProvider(replay.totalLaps).select((s) => s.lap),
    );
    final snapshot = replay.snapshotAt(lap);
    final entries = snapshot?.entries ?? const <LapEntry>[];

    final running = {for (final e in entries) e.driverId: e};
    final retired = replay.drivers
        .where((d) => !running.containsKey(d.driverId))
        .toList()
      ..sort((a, b) {
        final ap = a.finishPosition == 0 ? 999 : a.finishPosition;
        final bp = b.finishPosition == 0 ? 999 : b.finishPosition;
        return ap.compareTo(bp);
      });

    final slots = <String, int>{};
    for (final e in entries) {
      slots[e.driverId] = e.position - 1;
    }
    for (var i = 0; i < retired.length; i++) {
      slots[retired[i].driverId] = entries.length + i;
    }

    return StudioPanel(
      title: 'Classification',
      subtitle: 'Lap $lap of ${replay.totalLaps}',
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      child: SizedBox(
        height: replay.drivers.length * _rowHeight,
        child: Stack(
          children: [
            for (final driver in replay.drivers)
              AnimatedPositioned(
                key: ValueKey(driver.driverId),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                top: (slots[driver.driverId] ?? 0) * _rowHeight,
                left: 0,
                right: 0,
                height: _rowHeight,
                child: _LeaderboardRow(
                  driver: driver,
                  entry: running[driver.driverId],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.driver, required this.entry});
  final ReplayDriver driver;
  final LapEntry? entry;

  @override
  Widget build(BuildContext context) {
    final out = entry == null;
    final position = entry?.position ?? 0;
    final delta = out || driver.grid == 0 ? 0 : driver.grid - position;
    final compact = context.isMobile;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: out ? 0.42 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: driver.color, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  out ? '—' : '$position',
                  style: AppTextStyles.numeric.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(width: 6),
              _DeltaBadge(delta: delta, hidden: out),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  driver.shortName,
                  style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    driver.constructorName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label,
                  ),
                ),
              ] else
                const Spacer(),
              if (entry?.compound != null) ...[
                CompoundChip(compound: entry!.compound!),
                const SizedBox(width: 8),
              ],
              if (entry?.inPit ?? false) ...[
                const StudioPill(label: 'PIT', color: AppColors.info),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: 66,
                child: Text(
                  out
                      ? 'OUT'
                      : position == 1
                          ? 'LEADER'
                          : Formatters.gap(entry!.gapToLeader),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.label.copyWith(
                    color: out ? AppColors.negative : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Places gained (green) or lost (red) relative to the starting grid.
class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta, required this.hidden});
  final int delta;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (hidden || delta == 0) return const SizedBox(width: 26);
    final gained = delta > 0;
    final color = gained ? AppColors.positive : AppColors.negative;
    return SizedBox(
      width: 26,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gained ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: 16,
            color: color,
          ),
          Text(
            '${delta.abs()}',
            style: AppTextStyles.overline.copyWith(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}
