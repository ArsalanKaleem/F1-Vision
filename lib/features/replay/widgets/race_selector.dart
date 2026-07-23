import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_widgets.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'studio_panel.dart';

/// Season · Grand Prix · Session pickers. Changing the season clears the
/// selected round so the studio never shows a mismatched event.
class RaceSelector extends ConsumerWidget {
  const RaceSelector({super.key, required this.races});
  final List<RaceListing> races;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(replaySeasonProvider);
    final seasons = ref.watch(replaySeasonOptionsProvider);
    final round = ref.watch(replayRoundProvider);
    final session = ref.watch(replaySessionProvider);

    RaceListing? selected;
    for (final r in races) {
      if (r.round == round) selected = r;
    }

    return StudioPanel(
      title: 'Race Selection',
      subtitle: 'Choose an event to replay',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Dropdown<String>(
            label: 'Season',
            value: season,
            items: [
              for (final s in seasons) DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (value) {
              if (value == null) return;
              ref.read(replaySeasonProvider.notifier).state = value;
              ref.read(replayRoundProvider.notifier).state = null;
              ref.read(replaySessionProvider.notifier).state =
                  ReplaySession.race;
            },
          ),
          const SizedBox(height: 12),
          _Dropdown<int>(
            label: 'Grand Prix',
            value: round,
            hint: races.isEmpty ? 'No completed races' : 'Select a race',
            items: [
              for (final r in races)
                DropdownMenuItem(
                  value: r.round,
                  child: Text(
                    'R${r.round} · ${r.shortName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              ref.read(replayRoundProvider.notifier).state = value;
              ref.read(replaySessionProvider.notifier).state =
                  ReplaySession.race;
            },
          ),
          const SizedBox(height: 12),
          _Dropdown<ReplaySession>(
            label: 'Session',
            value: session,
            items: [
              const DropdownMenuItem(
                value: ReplaySession.race,
                child: Text('Race'),
              ),
              if (selected?.hasSprint ?? false)
                const DropdownMenuItem(
                  value: ReplaySession.sprint,
                  child: Text('Sprint'),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              ref.read(replaySessionProvider.notifier).state = value;
            },
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Guard against a stale value that isn't in the current item list.
    final values = items.map((e) => e.value).toList();
    final safeValue = values.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.overline),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceStroke),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: safeValue,
              isExpanded: true,
              isDense: true,
              hint: Text(
                hint ?? 'Select',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textTertiary),
              ),
              dropdownColor: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textSecondary),
              style: AppTextStyles.titleSmall,
              padding: const EdgeInsets.symmetric(vertical: 10),
              items: items.isEmpty ? null : items,
              onChanged: items.isEmpty ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Headline facts for the loaded event: circuit, date, winner, pole and
/// fastest lap, plus a badge showing which telemetry provider enriched it.
class RaceMetaHeader extends StatelessWidget {
  const RaceMetaHeader({
    super.key,
    required this.meta,
    required this.totalLaps,
    required this.hasTelemetry,
  });

  final RaceMeta meta;
  final int totalLaps;
  final bool hasTelemetry;

  @override
  Widget build(BuildContext context) {
    final date = meta.date;
    return StudioPanel(
      title: meta.raceName,
      subtitle:
          '${meta.season} · Round ${meta.round} · ${meta.session.label}',
      glow: true,
      trailing: StudioPill(
        label: hasTelemetry ? 'TELEMETRY' : 'TIMING ONLY',
        color: hasTelemetry ? AppColors.positive : AppColors.textTertiary,
      ),
      child: Wrap(
        spacing: 28,
        runSpacing: 16,
        children: [
          StatTile(
            label: 'Circuit',
            value: meta.circuitName.isEmpty ? '—' : meta.circuitName,
            icon: Icons.place_outlined,
          ),
          StatTile(
            label: 'Date',
            value: date == null ? '—' : Formatters.dayMonth(date),
            icon: Icons.event_outlined,
          ),
          StatTile(
            label: 'Laps',
            value: totalLaps == 0 ? '—' : '$totalLaps',
            icon: Icons.repeat_rounded,
          ),
          StatTile(
            label: 'Winner',
            value: meta.winner.isEmpty ? '—' : meta.winner,
            icon: Icons.emoji_events_outlined,
            valueColor: AppColors.accentSoft,
          ),
          StatTile(
            label: 'Pole',
            value: meta.pole.isEmpty ? '—' : meta.pole,
            icon: Icons.timer_outlined,
          ),
          StatTile(
            label: 'Fastest lap',
            value: meta.fastestLapDriver.isEmpty
                ? '—'
                : '${meta.fastestLapDriver}  ${meta.fastestLapTime}'.trim(),
            icon: Icons.bolt_rounded,
            valueColor: const Color(0xFFB388FF),
          ),
        ],
      ),
    );
  }
}
