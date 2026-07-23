import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/live_badge.dart';
import '../../models/analytics.dart';
import '../../providers/analytics_providers.dart';
import 'widgets/analytics_states.dart';
import 'widgets/championship_panels.dart';
import 'widgets/distribution_panels.dart';
import 'widgets/form_panels.dart';
import 'widgets/overview_panels.dart';
import 'widgets/ranking_panels.dart';
import 'widgets/tally_panels.dart';

/// The flagship analytics dashboard — a Bloomberg-terminal-style multi-panel
/// board built from Jolpica historical data (auto-refreshed for the current
/// season). The provider is watched exactly once here and the resulting
/// immutable [SeasonAnalytics] flows down to pure panel widgets, so rebuilds
/// stay minimal.
class AnalyticsCommandCenter extends ConsumerWidget {
  const AnalyticsCommandCenter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(analyticsSeasonProvider);
    final async = ref.watch(analyticsProvider(season));
    final pad = context.responsive(mobile: 16.0, desktop: 28.0);
    final cols = context.responsive(mobile: 1, tablet: 2, desktop: 3);
    final isCurrent = season == DateTime.now().year.toString();
    final generatedAt = async.valueOrNull?.dataOrNull?.generatedAt;

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            season: season,
            isCurrent: isCurrent,
            generatedAt: generatedAt,
            onRefresh: () => ref.invalidate(analyticsProvider(season)),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: async.when(
              loading: () => AnalyticsLoading(columns: cols),
              error: (e, _) => AnalyticsError(
                message: '$e',
                onRetry: () => ref.invalidate(analyticsProvider(season)),
              ),
              data: (result) => result.when(
                success: (data) => data.isEmpty
                    ? AnalyticsEmpty(season: season)
                    : _Dashboard(data: data, columns: cols),
                failure: (f) => AnalyticsError(
                  message: f.message,
                  onRetry: () => ref.invalidate(analyticsProvider(season)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.data, required this.columns});
  final SeasonAnalytics data;
  final int columns;

  @override
  Widget build(BuildContext context) {
    // Ordered so the hero panels lead; distributed round-robin into columns.
    final panels = <Widget>[
      SeasonStatsPanel(data: data),
      ChampionshipProgressPanel(data: data),
      DriverRankingsPanel(data: data),
      ConstructorPerformancePanel(data: data),
      TeamTrendsPanel(data: data),
      DnfPanel(data: data),
      PodiumsPanel(data: data),
      PolePositionsPanel(data: data),
      FastestLapsPanel(data: data),
      AverageFinishPanel(data: data),
      RacePacePanel(data: data),
      DriverFormPanel(data: data),
      HistoricalComparisonPanel(data: data),
      PitStopPanel(data: data),
    ];

    final buckets = List.generate(columns, (_) => <Widget>[]);
    for (var i = 0; i < panels.length; i++) {
      buckets[i % columns].add(panels[i]);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < buckets.length; c++) ...[
                if (c > 0) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (var p = 0; p < buckets[c].length; p++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: buckets[c][p]
                              .animate()
                              .fadeIn(
                                duration: 320.ms,
                                delay: (60 * p).ms,
                              )
                              .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.season,
    required this.isCurrent,
    required this.generatedAt,
    required this.onRefresh,
  });

  final String season;
  final bool isCurrent;
  final DateTime? generatedAt;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On phones the title and the controls can't share a row without
    // overflowing, so the controls drop onto their own line.
    final compact = context.isMobile;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                compact ? 'ANALYTICS' : 'ANALYTICS COMMAND CENTER',
                style: AppTextStyles.overline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 10),
              const LiveBadge(label: 'LIVE'),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Season $season',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: compact
              ? AppTextStyles.headlineMedium
              : AppTextStyles.displayLarge,
        ),
        if (generatedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Updated ${_hhmmss(generatedAt!)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ],
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SeasonSelector(),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onRefresh,
          tooltip: 'Refresh analytics',
          icon: const Icon(Icons.refresh_rounded),
          color: AppColors.textSecondary,
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          controls,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        controls,
      ],
    );
  }

  static String _hhmmss(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }
}

class _SeasonSelector extends ConsumerWidget {
  const _SeasonSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(analyticsSeasonProvider);
    final options = ref.watch(analyticsSeasonOptionsProvider);

    return PopupMenuButton<String>(
      tooltip: 'Select season',
      initialValue: season,
      onSelected: (value) =>
          ref.read(analyticsSeasonProvider.notifier).state = value,
      color: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        for (final s in options)
          PopupMenuItem<String>(
            value: s,
            child: Text(s,
                style: AppTextStyles.body.copyWith(
                  color: s == season
                      ? AppColors.accent
                      : AppColors.textPrimary,
                )),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceStroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(season,
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Icon(Icons.expand_more_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
