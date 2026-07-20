import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/telemetry_providers.dart';

/// Engineer-style status block: gear, DRS, pedal application and position.
/// Watches only the latest sample (and position) so it rebuilds independently
/// of the charts.
class StatusRail extends ConsumerWidget {
  const StatusRail({super.key, required this.args});

  final TelemetryArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sample = ref.watch(
      telemetryStreamProvider(args).select((s) => s.latest),
    );
    final positionRes = ref.watch(
      driverPositionProvider((
        sessionKey: args.sessionKey,
        driverNumber: args.driverNumber,
      )),
    );
    final position = positionRes.maybeWhen(
      data: (r) => r.dataOrNull,
      orElse: () => null,
    );

    final throttle = (sample?.throttle ?? 0).toDouble();
    final brake = (sample?.brake ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GearBadge(gear: sample?.gearLabel ?? '—'),
            const SizedBox(width: 12),
            Expanded(
              child: DrsIndicator(
                active: sample?.drsActive ?? false,
                eligible: sample?.drsEligible ?? false,
              ),
            ),
            const SizedBox(width: 12),
            _PositionChip(position: position),
          ],
        ),
        const SizedBox(height: 18),
        PedalBar(
          label: 'THROTTLE',
          value: throttle,
          color: AppColors.positive,
        ),
        const SizedBox(height: 12),
        PedalBar(
          label: 'BRAKE',
          value: brake,
          color: AppColors.negative,
        ),
      ],
    );
  }
}

/// Large current-gear readout.
class GearBadge extends StatelessWidget {
  const GearBadge({super.key, required this.gear});
  final String gear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceStroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('GEAR', style: AppTextStyles.overline.copyWith(fontSize: 9)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              gear,
              key: ValueKey<String>(gear),
              style: AppTextStyles.numeric.copyWith(fontSize: 30),
            ),
          ),
        ],
      ),
    );
  }
}

/// DRS state pill: green when open, amber when eligible, muted when off.
class DrsIndicator extends StatelessWidget {
  const DrsIndicator({super.key, required this.active, required this.eligible});
  final bool active;
  final bool eligible;

  @override
  Widget build(BuildContext context) {
    final (Color color, String text) = active
        ? (AppColors.positive, 'DRS OPEN')
        : eligible
            ? (AppColors.warning, 'DRS READY')
            : (AppColors.textTertiary, 'DRS OFF');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: active ? 0.6 : 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.air_rounded, size: 18, color: color),
          const SizedBox(height: 2),
          Text(
            text,
            style: AppTextStyles.overline.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _PositionChip extends StatelessWidget {
  const _PositionChip({required this.position});
  final int? position;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceStroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('POS', style: AppTextStyles.overline.copyWith(fontSize: 9)),
          Text(
            position == null ? '—' : 'P$position',
            style: AppTextStyles.numeric.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }
}

/// Animated horizontal pedal-application bar (0–100%).
class PedalBar extends StatelessWidget {
  const PedalBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value; // 0..100
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.overline),
            Text(
              '${value.round()}%',
              style: AppTextStyles.label.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 10, color: AppColors.surfaceHigh),
              LayoutBuilder(
                builder: (context, c) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: 10,
                  width: c.maxWidth * fraction,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.7), color],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
