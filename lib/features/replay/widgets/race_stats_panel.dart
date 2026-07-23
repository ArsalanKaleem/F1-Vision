import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'studio_panel.dart';

/// Live snapshot statistics for the current lap: leader, biggest mover,
/// fastest lap so far, on-track battles and how much of the race has run.
class RaceStatsPanel extends ConsumerWidget {
  const RaceStatsPanel({super.key, required this.replay});
  final RaceReplay replay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = replay.totalLaps;
    final lap = ref.watch(
      replayPlaybackProvider(total).select((s) => s.lap),
    );
    final snapshot = replay.snapshotAt(lap);
    final entries = snapshot?.entries ?? const <LapEntry>[];

    final leaderEntry = entries.isNotEmpty ? entries.first : null;
    final leader =
        leaderEntry == null ? null : replay.driver(leaderEntry.driverId);

    // Biggest mover vs grid at this point in the race.
    ReplayDriver? mover;
    var moverDelta = 0;
    for (final e in entries) {
      final d = replay.driver(e.driverId);
      if (d == null || d.grid == 0) continue;
      final delta = d.grid - e.position;
      if (delta > moverDelta) {
        moverDelta = delta;
        mover = d;
      }
    }

    // Fastest lap set so far.
    String flDriver = '';
    double? flTime;
    for (final snap in replay.laps) {
      if (snap.lap > lap) break;
      for (final e in snap.entries) {
        final s = e.lapSeconds;
        if (s == null || s <= 0) continue;
        if (flTime == null || s < flTime) {
          flTime = s;
          flDriver = replay.driver(e.driverId)?.shortName ?? '';
        }
      }
    }

    // Closest battle on track (smallest interval between adjacent cars).
    String battle = '—';
    double? closest;
    for (var i = 1; i < entries.length; i++) {
      final gap = entries[i].gapToLeader - entries[i - 1].gapToLeader;
      if (gap <= 0) continue;
      if (closest == null || gap < closest) {
        closest = gap;
        final a = replay.driver(entries[i - 1].driverId)?.shortName ?? '';
        final b = replay.driver(entries[i].driverId)?.shortName ?? '';
        battle = '$a / $b';
      }
    }

    final running = entries.length;
    final retired = replay.drivers.length - running;

    return StudioPanel(
      title: 'Race Statistics',
      subtitle: 'Lap $lap · ${(replay.snapshotAt(lap) != null ? (lap / total * 100).round() : 0)}% complete',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatRow(
            icon: Icons.emoji_events_outlined,
            label: 'Leader',
            value: leader?.shortName ?? '—',
            color: leader?.color,
          ),
          _StatRow(
            icon: Icons.trending_up_rounded,
            label: 'Biggest mover',
            value: mover == null ? '—' : '${mover.shortName}  +$moverDelta',
            color: mover?.color ?? AppColors.positive,
          ),
          _StatRow(
            icon: Icons.bolt_rounded,
            label: 'Fastest lap',
            value: flTime == null
                ? '—'
                : '$flDriver  ${Formatters.lapTime(flTime)}',
            color: const Color(0xFFB388FF),
          ),
          _StatRow(
            icon: Icons.sports_kabaddi_rounded,
            label: 'Closest battle',
            value: closest == null
                ? '—'
                : '$battle  ${Formatters.gap(closest)}',
          ),
          _StatRow(
            icon: Icons.directions_car_filled_outlined,
            label: 'Running / out',
            value: '$running / $retired',
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total <= 1 ? 0 : lap / total,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHigh,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.label),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall.copyWith(
                fontSize: 13,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
