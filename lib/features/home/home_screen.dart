import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_widgets.dart';
import '../../core/widgets/live_badge.dart';
import '../../models/live_entry.dart';
import '../../models/session.dart';
import '../../models/weather.dart';
import '../../providers/dashboard_providers.dart';

/// The landing dashboard — a Bloomberg-terminal-meets-F1-broadcast overview of
/// the current session.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(latestSessionProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(context.responsive(mobile: 16, desktop: 28)),
          sliver: SliverList.list(
            children: [
              const _DashboardHeader(),
              const SizedBox(height: 20),
              sessionAsync.when(
                loading: () => const _HeroSkeleton(),
                error: (e, _) => _ErrorCard(message: '$e'),
                data: (result) => result.when(
                  success: (session) => _DashboardBody(session: session),
                  failure: (f) => _ErrorCard(message: f.message),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RACE CONTROL', style: AppTextStyles.overline),
              const SizedBox(height: 4),
              Text('Dashboard', style: AppTextStyles.displayLarge),
            ],
          ),
        ),
        const LiveBadge(),
      ],
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.session});
  final F1Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider(session.sessionKey));
    final boardAsync = ref.watch(leaderboardProvider(session.sessionKey));

    final entries = boardAsync.maybeWhen(
      data: (r) => r.dataOrNull,
      orElse: () => null,
    );
    final leader =
        (entries != null && entries.isNotEmpty) ? entries.first : null;
    final weather = weatherAsync.maybeWhen(
      data: (r) => r.dataOrNull,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(session: session, leader: leader)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.04, end: 0),
        const SizedBox(height: 20),
        _StatGrid(weather: weather, leader: leader),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Running Order'),
        boardAsync.when(
          loading: () => const _BoardSkeleton(),
          error: (e, _) => _ErrorCard(message: '$e'),
          data: (r) => r.when(
            success: (entries) => _LeaderboardPreview(entries: entries),
            failure: (f) => _ErrorCard(message: f.message),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.session, required this.leader});
  final F1Session session;
  final LiveEntry? leader;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: true,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(session.sessionName.toUpperCase(),
                  style: AppTextStyles.overline.copyWith(
                      color: AppColors.accentSoft, letterSpacing: 1.4)),
              const Spacer(),
              if (session.year != null)
                Text('${session.year}', style: AppTextStyles.overline),
            ],
          ),
          const SizedBox(height: 14),
          Text(session.circuitShortName.isEmpty
              ? session.location
              : session.circuitShortName,
              style: AppTextStyles.displayLarge),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15),
              const SizedBox(width: 6),
              Text(session.countryName, style: AppTextStyles.body),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          _LeaderStrip(leader: leader),
        ],
      ),
    );
  }
}

class _LeaderStrip extends StatelessWidget {
  const _LeaderStrip({required this.leader});
  final LiveEntry? leader;

  @override
  Widget build(BuildContext context) {
    if (leader == null) {
      return Row(
        children: [
          Text('LEADER', style: AppTextStyles.overline),
          const SizedBox(width: 16),
          Text('Awaiting timing…', style: AppTextStyles.body),
        ],
      );
    }
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: leader!.driver.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CURRENT LEADER', style: AppTextStyles.overline),
            const SizedBox(height: 4),
            Text(leader!.driver.fullName, style: AppTextStyles.titleLarge),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: leader!.driver.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('#${leader!.driver.driverNumber}',
              style: AppTextStyles.numeric.copyWith(fontSize: 18)),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.weather, required this.leader});
  final F1Weather? weather;
  final LiveEntry? leader;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      StatTile(
        label: 'Track Temp',
        value: weather?.trackTemperature != null
            ? '${weather!.trackTemperature!.toStringAsFixed(1)}°'
            : '—',
        icon: Icons.thermostat_rounded,
        valueColor: AppColors.warning,
      ),
      StatTile(
        label: 'Air Temp',
        value: weather?.airTemperature != null
            ? '${weather!.airTemperature!.toStringAsFixed(1)}°'
            : '—',
        icon: Icons.air_rounded,
      ),
      StatTile(
        label: 'Conditions',
        value: weather == null ? '—' : (weather!.isWet ? 'WET' : 'DRY'),
        icon: Icons.water_drop_outlined,
        valueColor: (weather?.isWet ?? false)
            ? AppColors.info
            : AppColors.positive,
      ),
      StatTile(
        label: 'Leader Tyre',
        value: leader?.compound ?? '—',
        icon: Icons.tire_repair_rounded,
        valueColor: AppColors.tyreColor(leader?.compound),
      ),
    ];

    final columns = context.responsive(mobile: 2, tablet: 4, desktop: 4);
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.9,
      children: [
        for (final t in tiles)
          GlassCard(padding: const EdgeInsets.all(18), child: t),
      ],
    ).animate().fadeIn(delay: 120.ms, duration: 400.ms);
  }
}

class _LeaderboardPreview extends StatelessWidget {
  const _LeaderboardPreview({required this.entries});
  final List<LiveEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return GlassCard(
        child: Text('No running order available for this session.',
            style: AppTextStyles.body),
      );
    }
    final top = entries.take(5).toList();
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (final e in top)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${e.position}',
                        style: AppTextStyles.numeric.copyWith(fontSize: 16)),
                  ),
                  Container(
                    width: 3,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: e.driver.color,
                  ),
                  Expanded(
                    child: Text(e.driver.nameAcronym.isEmpty
                        ? e.driver.fullName
                        : e.driver.nameAcronym,
                        style: AppTextStyles.titleSmall),
                  ),
                  Text(
                    e.position == 1
                        ? 'LEADER'
                        : (e.gapToLeader != null
                            ? '+${e.gapToLeader!.toStringAsFixed(3)}'
                            : '—'),
                    style: AppTextStyles.label.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Loading & error states ──────────────────────────────────────────────
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) => const GlassCard(
        padding: EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 120, height: 12),
            SizedBox(height: 16),
            SkeletonBox(width: 240, height: 36),
            SizedBox(height: 12),
            SkeletonBox(width: 160, height: 14),
            SizedBox(height: 28),
            SkeletonBox(height: 44),
          ],
        ),
      );
}

class _BoardSkeleton extends StatelessWidget {
  const _BoardSkeleton();
  @override
  Widget build(BuildContext context) => const GlassCard(
        child: Column(
          children: [
            SkeletonBox(height: 18),
            SizedBox(height: 14),
            SkeletonBox(height: 18),
            SizedBox(height: 14),
            SkeletonBox(height: 18),
          ],
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
