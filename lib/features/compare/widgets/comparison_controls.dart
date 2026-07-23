import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/data_panel.dart';
import '../../../models/analytics.dart';
import '../../../models/replay.dart';
import '../../../providers/analytics_providers.dart';
import '../../../providers/comparison_providers.dart';

/// Season, the two drivers, and an optional race to drill into.
class ComparisonControls extends ConsumerWidget {
  const ComparisonControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(comparisonSeasonProvider);
    final seasons = ref.watch(analyticsSeasonOptionsProvider);
    final drivers = ref.watch(comparisonDriverOptionsProvider);
    final comparison = ref.watch(comparisonProvider).valueOrNull;
    final round = ref.watch(comparisonRoundProvider);

    final scheduleAsync = ref.watch(comparisonScheduleProvider(season));
    final races = scheduleAsync.valueOrNull?.dataOrNull ?? const <RaceListing>[];

    return DataPanel(
      title: 'Comparison Setup',
      subtitle: 'Pick two drivers, then optionally a race',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Labelled(
            label: 'Season',
            child: DropdownButton<String>(
              value: season,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              dropdownColor: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              icon: Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textSecondary),
              style: AppTextStyles.titleSmall,
              items: [
                for (final s in seasons)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (value) {
                if (value == null) return;
                ref.read(comparisonSeasonProvider.notifier).state = value;
                ref.read(comparisonDriverAProvider.notifier).state = null;
                ref.read(comparisonDriverBProvider.notifier).state = null;
                ref.read(comparisonRoundProvider.notifier).state = null;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DriverPicker(
            label: 'Driver A',
            drivers: drivers,
            selected: comparison?.a.driverId,
            exclude: comparison?.b.driverId,
            accent: comparison?.a.color ?? AppColors.accent,
            onChanged: (id) =>
                ref.read(comparisonDriverAProvider.notifier).state = id,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: IconButton(
              tooltip: 'Swap drivers',
              onPressed: comparison == null
                  ? null
                  : () {
                      final a = comparison.a.driverId;
                      final b = comparison.b.driverId;
                      ref.read(comparisonDriverAProvider.notifier).state = b;
                      ref.read(comparisonDriverBProvider.notifier).state = a;
                    },
              icon: Icon(Icons.swap_vert_rounded,
                  size: 20, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DriverPicker(
            label: 'Driver B',
            drivers: drivers,
            selected: comparison?.b.driverId,
            exclude: comparison?.a.driverId,
            accent: comparison?.b.color ?? AppColors.info,
            onChanged: (id) =>
                ref.read(comparisonDriverBProvider.notifier).state = id,
          ),
          const SizedBox(height: AppSpacing.md),
          _Labelled(
            label: 'Race detail (optional)',
            child: DropdownButton<int?>(
              value: races.any((r) => r.round == round) ? round : null,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox.shrink(),
              hint: Text(
                races.isEmpty ? 'No races available' : 'Season only',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textTertiary),
              ),
              dropdownColor: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              icon: Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textSecondary),
              style: AppTextStyles.titleSmall,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Season only'),
                ),
                for (final r in races)
                  DropdownMenuItem<int?>(
                    value: r.round,
                    child: Text('R${r.round} · ${r.shortName}',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: races.isEmpty
                  ? null
                  : (value) =>
                      ref.read(comparisonRoundProvider.notifier).state = value,
            ),
          ),
          if (round != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Race panels use lap-by-lap timing; sector and speed detail '
              'needs a telemetry provider (2023 onward).',
              style:
                  AppTextStyles.label.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            border: Border.all(color: AppColors.surfaceStroke),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
      ],
    );
  }
}

class _DriverPicker extends StatelessWidget {
  const _DriverPicker({
    required this.label,
    required this.drivers,
    required this.selected,
    required this.exclude,
    required this.accent,
    required this.onChanged,
  });

  final String label;
  final List<DriverAggregate> drivers;
  final String? selected;
  final String? exclude;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = drivers.where((d) => d.driverId != exclude).toList();
    final value =
        options.any((d) => d.driverId == selected) ? selected : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm - 2),
            Text(label.toUpperCase(), style: AppTextStyles.overline),
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              hint: Text('Select driver',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textTertiary)),
              dropdownColor: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              icon: Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textSecondary),
              style: AppTextStyles.titleSmall,
              items: [
                for (final d in options)
                  DropdownMenuItem(
                    value: d.driverId,
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 14,
                          decoration: BoxDecoration(
                            color: d.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text('${d.shortName} · ${d.name}',
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: options.isEmpty
                  ? null
                  : (v) {
                      if (v != null) onChanged(v);
                    },
            ),
          ),
        ),
      ],
    );
  }
}
