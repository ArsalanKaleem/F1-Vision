import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/data_panel.dart';
import '../../../models/comparison.dart';
import '../../analytics/widgets/charts/analytics_line_chart.dart';
import '../../analytics/widgets/charts/radar_comparison_chart.dart';

/// Side-by-side driver identity cards with the season headline numbers.
class ComparisonProfiles extends StatelessWidget {
  const ComparisonProfiles({super.key, required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    final a = _ProfileCard(side: comparison.a, alignEnd: false);
    final b = _ProfileCard(side: comparison.b, alignEnd: context.isMobile ? false : true);

    return DataPanel(
      title: 'Driver Comparison',
      subtitle: '${comparison.season} season'
          '${comparison.raceMeta != null ? ' · ${comparison.raceMeta!.raceName}' : ''}',
      glow: true,
      child: context.isMobile
          ? Column(
              children: [
                a,
                const SizedBox(height: AppSpacing.md),
                const _VersusBadge(),
                const SizedBox(height: AppSpacing.md),
                b,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: a),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _VersusBadge(),
                ),
                Expanded(child: b),
              ],
            ),
    );
  }
}

class _VersusBadge extends StatelessWidget {
  const _VersusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceStroke),
      ),
      child: Text('VS',
          style: AppTextStyles.overline.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          )),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.side, required this.alignEnd});
  final ComparisonSide side;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cross =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final align = alignEnd ? TextAlign.right : TextAlign.left;

    return Semantics(
      label: '${side.name}, ${side.constructorName}, '
          'championship position ${side.season.championshipPosition}, '
          '${side.season.points} points',
      child: Column(
        crossAxisAlignment: cross,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: side.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: side.color.withValues(alpha: 0.6)),
            ),
            child: Text(
              side.code,
              style: AppTextStyles.titleSmall.copyWith(
                color: side.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(side.name, textAlign: align, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.xs / 2),
          Text(side.constructorName,
              textAlign: align, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _Mini(label: 'Pos', value: 'P${side.season.championshipPosition}'),
              _Mini(
                label: 'Points',
                value: side.season.points == side.season.points.roundToDouble()
                    ? side.season.points.toStringAsFixed(0)
                    : side.season.points.toStringAsFixed(1),
                color: side.color,
              ),
              _Mini(label: 'Wins', value: '${side.season.wins}'),
              _Mini(label: 'Podiums', value: '${side.season.podiums}'),
              if (side.hasRace)
                _Mini(
                  label: 'Race',
                  value: side.race!.finishPosition == 0
                      ? 'DNF'
                      : 'P${side.race!.finishPosition}',
                  color: side.race!.finishPosition == 0
                      ? AppColors.negative
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs / 2),
        Text(value,
            style: AppTextStyles.numeric
                .copyWith(fontSize: 18, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}

/// Paired bars: one row per metric, each driver's value growing from the
/// centre so the advantage is obvious at a glance.
class MetricBars extends StatelessWidget {
  const MetricBars({
    super.key,
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.comparison,
  });

  final String title;
  final String subtitle;
  final List<ComparisonMetric> metrics;
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return DataPanel(
        title: title,
        subtitle: subtitle,
        child: const PanelEmptyNote(
          message: 'Select a race where both drivers took part.',
          icon: Icons.compare_arrows_rounded,
        ),
      );
    }

    return DataPanel(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(comparison.a.code,
                    style: AppTextStyles.overline
                        .copyWith(color: comparison.a.color)),
              ),
              Expanded(
                child: Text(comparison.b.code,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.overline
                        .copyWith(color: comparison.b.color)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final metric in metrics)
            _MetricRow(metric: metric, comparison: comparison),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric, required this.comparison});
  final ComparisonMetric metric;
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    final winner = metric.winner;

    return Semantics(
      label: '${metric.label}: ${comparison.a.code} '
          '${metric.display(metric.a)}, ${comparison.b.code} '
          '${metric.display(metric.b)}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(
                    metric.display(metric.a),
                    style: AppTextStyles.numeric.copyWith(
                      fontSize: 13,
                      color: winner == -1
                          ? comparison.a.color
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(metric.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.label),
                ),
                SizedBox(
                  width: 62,
                  child: Text(
                    metric.display(metric.b),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.numeric.copyWith(
                      fontSize: 13,
                      color: winner == 1
                          ? comparison.b.color
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs + 1),
            Row(
              children: [
                Expanded(
                  child: _Bar(
                    fraction: metric.fraction(metric.a),
                    color: comparison.a.color,
                    fromRight: true,
                    dim: winner == 1,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _Bar(
                    fraction: metric.fraction(metric.b),
                    color: comparison.b.color,
                    fromRight: false,
                    dim: winner == -1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.fromRight,
    required this.dim,
  });

  final double fraction;
  final Color color;
  final bool fromRight;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Align(
        alignment: fromRight ? Alignment.centerRight : Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: AppDurations.chart,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: dim ? 0.35 : 0.95),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Normalised six-axis radar of the two seasons.
class ComparisonRadar extends StatelessWidget {
  const ComparisonRadar({super.key, required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    final vectors = comparison.radarVectors;
    return DataPanel(
      title: 'Performance Radar',
      subtitle: 'Season profile · normalised to the stronger driver',
      child: Center(
        child: RadarComparisonChart(
          axes: vectors.axes,
          size: 260,
          series: [
            RadarSeriesData(
              label: comparison.a.code,
              color: comparison.a.color,
              values: vectors.a,
            ),
            RadarSeriesData(
              label: comparison.b.code,
              color: comparison.b.color,
              values: vectors.b,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cumulative championship points across the season for both drivers.
class ChampionshipComparison extends StatelessWidget {
  const ChampionshipComparison({super.key, required this.comparison});
  final DriverComparison comparison;

  @override
  Widget build(BuildContext context) {
    return DataPanel(
      title: 'Championship Points',
      subtitle: 'Cumulative across the season',
      child: AnalyticsLineChart(
        xLabels: comparison.roundLabels,
        height: 240,
        enableZoom: true,
        series: [
          LineSeries(
            label: comparison.a.code,
            color: comparison.a.color,
            values: comparison.a.season.cumulativePoints,
          ),
          LineSeries(
            label: comparison.b.code,
            color: comparison.b.color,
            values: comparison.b.season.cumulativePoints,
          ),
        ],
      ),
    );
  }
}
