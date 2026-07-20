import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/driver.dart';
import '../../../providers/telemetry_providers.dart';

/// Horizontal, scrollable driver picker. Selecting a driver updates
/// [selectedDriverProvider], which re-keys the telemetry stream.
class DriverSelector extends ConsumerWidget {
  const DriverSelector({
    super.key,
    required this.drivers,
    required this.selected,
  });

  final List<F1Driver> drivers;
  final int selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: drivers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = drivers[i];
          final isSelected = d.driverNumber == selected;
          return GestureDetector(
            onTap: () =>
                ref.read(selectedDriverProvider.notifier).state = d.driverNumber,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? d.color.withValues(alpha: 0.18)
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? d.color : AppColors.surfaceStroke,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: d.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    d.nameAcronym.isNotEmpty
                        ? d.nameAcronym
                        : '#${d.driverNumber}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${d.driverNumber}',
                    style: AppTextStyles.overline.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
