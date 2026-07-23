import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_widgets.dart';
import '../../core/widgets/live_badge.dart';
import '../../models/live_entry.dart';
import '../../models/session.dart';
import '../../providers/dashboard_providers.dart';

/// A race-control style live leaderboard. Rows are absolutely positioned by
/// classification so that when the order changes between polls, each car slides
/// smoothly to its new slot (the brief's "position changes slide smoothly").
class LiveRaceScreen extends ConsumerWidget {
  const LiveRaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(latestSessionProvider);
    final live =
        sessionAsync.valueOrNull?.dataOrNull?.isLive ?? false;
    final pad = context.responsive(mobile: 16.0, desktop: 28.0);

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIMING & SCORING', style: AppTextStyles.overline),
                    const SizedBox(height: 4),
                    Text(live ? 'Live Race' : 'Race Result',
                        style: AppTextStyles.displayLarge),
                    if (!live) ...[
                      const SizedBox(height: 4),
                      Text('Latest classification — final positions',
                          style: AppTextStyles.body),
                    ],
                  ],
                ),
              ),
              if (live)
                const LiveBadge(label: 'LIVE FEED')
              else
                const _LatestChip(),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: sessionAsync.when(
              loading: () => const _Loading(),
              error: (e, _) => _Error(message: '$e'),
              data: (r) => r.when(
                success: (session) => _LiveBoard(session: session),
                failure: (f) => _Error(message: f.message),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBoard extends ConsumerWidget {
  const _LiveBoard({required this.session});
  final F1Session session;

  static const double _rowHeight = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(leaderboardProvider(session.sessionKey));

    return boardAsync.when(
      loading: () => const _Loading(),
      error: (e, _) => _Error(message: '$e'),
      data: (r) => r.when(
        success: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text('No live timing for this session.',
                  style: AppTextStyles.body),
            );
          }
          return _Header(
            session: session,
            live: session.isLive,
            child: SizedBox(
              height: entries.length * _rowHeight + 8,
              child: Stack(
                children: [
                  for (final e in entries)
                    AnimatedPositioned(
                      key: ValueKey(e.driver.driverNumber),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOutCubic,
                      top: (e.position - 1) * _rowHeight,
                      left: 0,
                      right: 0,
                      height: _rowHeight,
                      child: _LiveRow(entry: e, live: session.isLive),
                    ),
                ],
              ),
            ),
          );
        },
        failure: (f) => _Error(message: f.message),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session, required this.live, required this.child});
  final F1Session session;
  final bool live;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${session.circuitShortName} · ${session.sessionName}'
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.overline,
                  ),
                ),
                const SizedBox(width: 12),
                const Spacer(),
                Text(live ? 'GAP' : 'POS', style: AppTextStyles.overline),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.entry, required this.live});
  final LiveEntry entry;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final d = entry.driver;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: d.color, width: 4),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text('${entry.position}',
                  style: AppTextStyles.numeric.copyWith(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              child: Text(
                d.nameAcronym.isEmpty ? d.fullName : d.nameAcronym,
                style: AppTextStyles.titleSmall,
              ),
            ),
            // Post-session, the classification is the story: always show the
            // team and drop the (stale) tyre / DRS / gap decorations.
            if (!live || !context.isMobile) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(d.teamName,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label),
              ),
            ] else
              const Spacer(),
            if (live) ...[
              if (entry.compound != null) _TyrePill(compound: entry.compound!),
              const SizedBox(width: 12),
              if (entry.drsActive) const _DrsChip(),
              SizedBox(
                width: 78,
                child: Text(
                  entry.position == 1
                      ? 'LEADER'
                      : Formatters.gap(entry.interval ?? entry.gapToLeader),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: 54,
                child: Text(
                  'P${entry.position}',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.label.copyWith(
                    color: entry.position <= 3
                        ? AppColors.accentSoft
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Static chip shown instead of the pulsing LIVE badge once a session is over.
class _LatestChip extends StatelessWidget {
  const _LatestChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('LATEST RESULT', style: AppTextStyles.overline),
        ],
      ),
    );
  }
}

class _TyrePill extends StatelessWidget {
  const _TyrePill({required this.compound});
  final String compound;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.tyreColor(compound);
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        compound.isNotEmpty ? compound[0].toUpperCase() : '?',
        style: AppTextStyles.label.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

class _DrsChip extends StatelessWidget {
  const _DrsChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.positive.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('DRS',
          style: AppTextStyles.label
              .copyWith(color: AppColors.positive, fontSize: 10)),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const GlassCard(
        child: Column(
          children: [
            SkeletonBox(height: 20),
            SizedBox(height: 16),
            SkeletonBox(height: 20),
            SizedBox(height: 16),
            SkeletonBox(height: 20),
            SizedBox(height: 16),
            SkeletonBox(height: 20),
          ],
        ),
      );
}

class _Error extends StatelessWidget {
  const _Error({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
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
      );
}
