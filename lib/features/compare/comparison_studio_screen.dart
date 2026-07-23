import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/data_panel.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_widgets.dart';
import '../../models/comparison.dart';
import '../../providers/comparison_providers.dart';
import 'widgets/comparison_controls.dart';
import 'widgets/comparison_overview.dart';
import 'widgets/comparison_race_panels.dart';

/// Phase 5 — Driver Comparison Studio.
///
/// Head-to-head analysis of any two drivers, season-wide and (optionally)
/// drilled into a single race. The screen performs no I/O of its own: it
/// composes the Analytics aggregate and the Replay payload the app has already
/// cached, so swapping drivers is instant.
class ComparisonStudioScreen extends ConsumerWidget {
  const ComparisonStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comparisonProvider);
    final pad = context.responsive(
      mobile: AppSpacing.pagePadMobile,
      desktop: AppSpacing.pagePadDesktop,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: AppSpacing.lg + 2),
          Expanded(
            child: state.when(
              loading: () => const _Loading(),
              error: (error, _) => _ErrorView(
                message: '$error',
                onRetry: () => ref.invalidate(comparisonProvider),
              ),
              data: (comparison) => comparison == null
                  ? const _NoDrivers()
                  : _Body(comparison: comparison),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HEAD TO HEAD', style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs),
        Text('Comparison Studio', style: AppTextStyles.displayLarge),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    final controls = const ComparisonControls();

    final sectorMetrics = <ComparisonMetric>[
      ComparisonMetric(
        label: 'Best sector 1',
        a: comparison.a.bestSector1,
        b: comparison.b.bestSector1,
        format: (v) => '${v.toStringAsFixed(3)}s',
        lowerIsBetter: true,
      ),
      ComparisonMetric(
        label: 'Best sector 2',
        a: comparison.a.bestSector2,
        b: comparison.b.bestSector2,
        format: (v) => '${v.toStringAsFixed(3)}s',
        lowerIsBetter: true,
      ),
      ComparisonMetric(
        label: 'Best sector 3',
        a: comparison.a.bestSector3,
        b: comparison.b.bestSector3,
        format: (v) => '${v.toStringAsFixed(3)}s',
        lowerIsBetter: true,
      ),
    ].where((m) => m.hasBoth).toList();

    final speedMetrics = <ComparisonMetric>[
      ComparisonMetric(
        label: 'Top speed',
        a: comparison.a.topSpeed,
        b: comparison.b.topSpeed,
        format: (v) => '${v.toStringAsFixed(0)} km/h',
      ),
      ComparisonMetric(
        label: 'Average speed',
        a: comparison.a.averageSpeed,
        b: comparison.b.averageSpeed,
        format: (v) => '${v.toStringAsFixed(1)} km/h',
      ),
    ].where((m) => m.hasBoth).toList();

    final profiles = ComparisonProfiles(comparison: comparison);
    final seasonBars = MetricBars(
      title: 'Season Head to Head',
      subtitle: 'Championship form',
      metrics: comparison.seasonMetrics,
      comparison: comparison,
    );
    final radar = ComparisonRadar(comparison: comparison);
    final championship = ChampionshipComparison(comparison: comparison);

    final raceBars = MetricBars(
      title: 'Race Head to Head',
      subtitle: comparison.raceMeta?.raceName ?? 'Select a race',
      metrics: comparison.raceMetrics,
      comparison: comparison,
    );
    final sectors = sectorMetrics.isEmpty
        ? const DataPanel(
            title: 'Sector Times',
            subtitle: 'Personal best per sector',
            child: PanelEmptyNote(
              message:
                  'Sector detail needs a telemetry provider (2023 onward).',
              icon: Icons.timeline_outlined,
            ),
          )
        : MetricBars(
            title: 'Sector Times',
            subtitle: 'Personal best per sector',
            metrics: sectorMetrics,
            comparison: comparison,
          );
    final speed = speedMetrics.isEmpty
        ? const DataPanel(
            title: 'Speed',
            subtitle: 'Top and average',
            child: PanelEmptyNote(
              message: 'Speed data needs a telemetry provider (2023 onward).',
              icon: Icons.speed_outlined,
            ),
          )
        : MetricBars(
            title: 'Speed',
            subtitle: 'Top and average',
            metrics: speedMetrics,
            comparison: comparison,
          );

    final lapTimes = LapTimeComparison(comparison: comparison);
    final positions = PositionComparison(comparison: comparison);
    final tyres = TyreStrategyComparison(comparison: comparison);
    final pits = PitStopComparison(comparison: comparison);
    final degradation = DegradationScatter(comparison: comparison);

    Widget gap() => const SizedBox(height: AppSpacing.panelGap);

    final analysisPanels = <Widget>[
      seasonBars,
      championship,
      radar,
      if (comparison.hasRace) ...[
        raceBars,
        lapTimes,
        positions,
        sectors,
        speed,
        tyres,
        pits,
        degradation,
      ],
    ];

    if (context.isDesktop) {
      // Controls pinned left; analysis flows in two balanced columns.
      final left = <Widget>[];
      final right = <Widget>[];
      for (var i = 0; i < analysisPanels.length; i++) {
        (i.isEven ? left : right).add(analysisPanels[i]);
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profiles,
                gap(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: controls),
                    const SizedBox(width: AppSpacing.panelGap),
                    Expanded(child: _Column(panels: left)),
                    const SizedBox(width: AppSpacing.panelGap),
                    Expanded(child: _Column(panels: right)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: AppDurations.medium);
    }

    if (context.isTablet) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          children: [
            profiles,
            gap(),
            controls,
            gap(),
            for (final panel in analysisPanels) ...[panel, gap()],
          ],
        ),
      ).animate().fadeIn(duration: AppDurations.medium);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        children: [
          controls,
          gap(),
          profiles,
          gap(),
          for (final panel in analysisPanels) ...[panel, gap()],
        ],
      ),
    ).animate().fadeIn(duration: AppDurations.medium);
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.panels});
  final List<Widget> panels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < panels.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.panelGap),
          panels[i],
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 18, width: 220),
                SizedBox(height: AppSpacing.md),
                SkeletonBox(height: 12, width: 150),
                SizedBox(height: AppSpacing.xl),
                SkeletonBox(height: 60),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.panelGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(child: _SkeletonPanel(height: 240)),
              SizedBox(width: AppSpacing.panelGap),
              Expanded(child: _SkeletonPanel(height: 240)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 14, width: 130),
          const SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: height - 60),
        ],
      ),
    );
  }
}

class _NoDrivers extends StatelessWidget {
  const _NoDrivers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_rounded,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text('Not enough drivers to compare',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This season has fewer than two classified drivers. Pick another '
              'season from the setup panel.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(width: 320, child: ComparisonControls()),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.negative),
            const SizedBox(height: AppSpacing.lg),
            Text('Couldn’t build the comparison',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonal(
                onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
