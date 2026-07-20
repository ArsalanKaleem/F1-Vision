import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/animated_counter.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_widgets.dart';
import '../../models/standings.dart';
import '../../providers/core_providers.dart';
import '../../providers/standings_providers.dart';

/// Championship standings with two tabs (Drivers / Constructors). Cards animate
/// in on load and points count up.
class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(selectedSeasonProvider);
    final pad = context.responsive(mobile: 16.0, desktop: 28.0);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHAMPIONSHIP $season',
                        style: AppTextStyles.overline),
                    const SizedBox(height: 4),
                    Text('Standings', style: AppTextStyles.displayLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabs,
          isScrollable: false,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppTextStyles.titleSmall,
          tabs: const [Tab(text: 'Drivers'), Tab(text: 'Constructors')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _DriverStandingsTab(pad: pad),
              _ConstructorStandingsTab(pad: pad),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverStandingsTab extends ConsumerWidget {
  const _DriverStandingsTab({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(driverStandingsProvider);
    return async.when(
      loading: () => _ListSkeleton(pad: pad),
      error: (e, _) => _Error(message: '$e'),
      data: (Result<List<DriverStanding>> result) => result.when(
        success: (rows) => _DriverList(rows: rows, pad: pad),
        failure: (f) => _Error(message: f.message),
      ),
    );
  }
}

class _DriverList extends StatelessWidget {
  const _DriverList({required this.rows, required this.pad});
  final List<DriverStanding> rows;
  final double pad;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _Empty();
    final maxPoints = rows.first.points.clamp(1, double.infinity);
    return ListView.separated(
      padding: EdgeInsets.all(pad),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = rows[i];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          onTap: () {},
          child: Row(
            children: [
              _PositionBadge(position: r.position),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.fullName, style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text('${r.constructorName} · ${r.nationality}',
                        style: AppTextStyles.label),
                  ],
                ),
              ),
              if (!context.isMobile) ...[
                Expanded(
                  flex: 2,
                  child: _PointsBar(
                    value: r.points,
                    max: maxPoints.toDouble(),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedCounter(
                    value: r.points,
                    fractionDigits: r.points % 1 == 0 ? 0 : 1,
                    style: AppTextStyles.numeric,
                  ),
                  Text('${r.wins} wins', style: AppTextStyles.label),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (40 * i).ms, duration: 320.ms)
            .slideX(begin: 0.04, end: 0);
      },
    );
  }
}

class _ConstructorStandingsTab extends ConsumerWidget {
  const _ConstructorStandingsTab({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(constructorStandingsProvider);
    return async.when(
      loading: () => _ListSkeleton(pad: pad),
      error: (e, _) => _Error(message: '$e'),
      data: (result) => result.when(
        success: (rows) => _ConstructorList(rows: rows, pad: pad),
        failure: (f) => _Error(message: f.message),
      ),
    );
  }
}

class _ConstructorList extends StatelessWidget {
  const _ConstructorList({required this.rows, required this.pad});
  final List<ConstructorStanding> rows;
  final double pad;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const _Empty();
    final maxPoints = rows.first.points.clamp(1, double.infinity);
    return ListView.separated(
      padding: EdgeInsets.all(pad),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = rows[i];
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          onTap: () {},
          child: Row(
            children: [
              _PositionBadge(position: r.position),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text(r.nationality, style: AppTextStyles.label),
                  ],
                ),
              ),
              if (!context.isMobile) ...[
                Expanded(
                  flex: 2,
                  child: _PointsBar(
                    value: r.points,
                    max: maxPoints.toDouble(),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedCounter(value: r.points, style: AppTextStyles.numeric),
                  Text('${r.wins} wins', style: AppTextStyles.label),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (40 * i).ms, duration: 320.ms)
            .slideX(begin: 0.04, end: 0);
      },
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position});
  final int position;

  @override
  Widget build(BuildContext context) {
    final isPodium = position <= 3;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isPodium ? AppColors.accentGradient : null,
        color: isPodium ? null : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPodium ? Colors.transparent : AppColors.surfaceStroke,
        ),
      ),
      child: Text('$position',
          style: AppTextStyles.numeric.copyWith(
            fontSize: 16,
            color: isPodium ? Colors.white : AppColors.textSecondary,
          )),
    );
  }
}

/// A thin animated progress bar showing points relative to the leader.
class _PointsBar extends StatelessWidget {
  const _PointsBar({required this.value, required this.max});
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / max).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Container(
                height: 8,
                width: constraints.maxWidth * v,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.pad});
  final double pad;
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(pad),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const GlassCard(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            SkeletonBox(width: 40, height: 40, radius: 12),
            SizedBox(width: 16),
            Expanded(child: SkeletonBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning),
                const SizedBox(width: 12),
                Flexible(child: Text(message, style: AppTextStyles.body)),
              ],
            ),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
        child: Text('No standings for this season yet.',
            style: AppTextStyles.body),
      );
}
