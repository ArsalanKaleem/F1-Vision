import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';

/// Drivers the analysis charts should plot: the explicit selection when the
/// user has made one, otherwise the leading finishers.
List<ReplayDriver> effectiveDrivers(
  RaceReplay replay,
  Set<String> focused, {
  int fallback = 6,
}) {
  if (focused.isEmpty) return replay.drivers.take(fallback).toList();
  return replay.drivers.where((d) => focused.contains(d.driverId)).toList();
}

/// Chip row for choosing which drivers the charts highlight. The selection is
/// shared by every analysis panel, so picking a driver once updates them all.
class DriverFilterBar extends ConsumerWidget {
  const DriverFilterBar({super.key, required this.replay});
  final RaceReplay replay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = ref.watch(focusedDriversProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              focused.isEmpty ? 'SHOWING TOP RUNNERS' : 'SELECTED DRIVERS',
              style: AppTextStyles.overline,
            ),
            const Spacer(),
            if (focused.isNotEmpty)
              GestureDetector(
                onTap: () =>
                    ref.read(focusedDriversProvider.notifier).state = {},
                child: Text(
                  'Reset',
                  style: AppTextStyles.overline
                      .copyWith(color: AppColors.accentSoft),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final driver in replay.drivers)
              _DriverChip(
                driver: driver,
                selected: focused.contains(driver.driverId),
                onTap: () {
                  final next = Set<String>.from(focused);
                  if (!next.remove(driver.driverId)) {
                    next.add(driver.driverId);
                  }
                  ref.read(focusedDriversProvider.notifier).state = next;
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _DriverChip extends StatelessWidget {
  const _DriverChip({
    required this.driver,
    required this.selected,
    required this.onTap,
  });

  final ReplayDriver driver;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? driver.color.withValues(alpha: 0.22)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? driver.color : AppColors.surfaceStroke,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: driver.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              driver.shortName,
              style: AppTextStyles.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
