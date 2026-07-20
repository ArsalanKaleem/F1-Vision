import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/info_widgets.dart';

/// A shimmering skeleton that mirrors the dashboard's masonry while data loads.
class AnalyticsLoading extends StatelessWidget {
  const AnalyticsLoading({super.key, this.columns = 3});
  final int columns;

  @override
  Widget build(BuildContext context) {
    final heights = [220.0, 300.0, 180.0, 260.0, 200.0, 320.0];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (var i = 0; i < columns * 2; i++)
            SizedBox(
              width: _cardWidth(context, columns),
              child: _SkeletonCard(height: heights[i % heights.length]),
            ),
        ],
      ),
    );
  }

  double _cardWidth(BuildContext context, int columns) {
    final total = MediaQuery.sizeOf(context).width;
    final usable = (total > 1200 ? 1200 : total) - 56 - (columns - 1) * 16;
    return usable / columns;
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
          const SizedBox(height: 8),
          const SkeletonBox(height: 10, width: 80),
          const SizedBox(height: 20),
          SkeletonBox(height: height - 90),
        ],
      ),
    );
  }
}

/// A friendly empty state (no data for the chosen season).
class AnalyticsEmpty extends StatelessWidget {
  const AnalyticsEmpty({super.key, required this.season});
  final String season;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('No analytics for $season yet',
                textAlign: TextAlign.center, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              'This season has no completed races to analyse. Pick another '
              'season from the selector above.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}

/// An error state with a retry affordance.
class AnalyticsError extends StatelessWidget {
  const AnalyticsError({super.key, required this.message, required this.onRetry});
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
            const SizedBox(height: 16),
            Text('Couldn’t load analytics',
                textAlign: TextAlign.center, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
