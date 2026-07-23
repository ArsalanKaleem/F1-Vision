import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/info_widgets.dart';

/// Skeleton shown while a replay is being assembled (several paginated calls).
class ReplayLoading extends StatelessWidget {
  const ReplayLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(height: 18, width: 200),
                SizedBox(height: 10),
                SkeletonBox(height: 12, width: 140),
                SizedBox(height: 20),
                SkeletonBox(height: 46),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _SkeletonCard(height: 320)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _SkeletonCard(height: 320)),
              const SizedBox(width: 16),
              const Expanded(child: _SkeletonCard(height: 320)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Text('Assembling lap-by-lap timing…', style: AppTextStyles.body),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 14, width: 120),
          const SizedBox(height: 18),
          SkeletonBox(height: height - 70),
        ],
      ),
    );
  }
}

/// Shown before the user has picked a race.
class ReplayEmpty extends StatelessWidget {
  const ReplayEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.replay_rounded,
                  size: 30, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text('Race Replay & Strategy',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Pick a season and Grand Prix to replay it lap by lap — with an '
              'animated leaderboard, tyre strategy, position history and a '
              'synchronized race feed.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
