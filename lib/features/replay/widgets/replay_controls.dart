import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/replay_providers.dart';
import 'studio_panel.dart';

/// Formats a playback rate as "0.5×" / "2×".
String speedLabel(double speed) => speed == speed.roundToDouble()
    ? '${speed.toStringAsFixed(0)}×'
    : '$speed×';

/// The replay transport: play / pause, restart, lap stepping, speed selection
/// and a scrubber that jumps straight to any lap.
class ReplayControls extends ConsumerWidget {
  const ReplayControls({super.key, required this.totalLaps});
  final int totalLaps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(replayPlaybackProvider(totalLaps));
    final controller = ref.read(replayPlaybackProvider(totalLaps).notifier);

    return StudioPanel(
      title: 'Replay Control',
      subtitle: playback.playing ? 'Playing' : 'Paused',
      trailing: StudioPill(
        label: speedLabel(playback.speed),
        color: AppColors.accentSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('LAP', style: AppTextStyles.overline),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.35),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  '${playback.lap}',
                  key: ValueKey(playback.lap),
                  style: AppTextStyles.numeric.copyWith(fontSize: 30),
                ),
              ),
              Text(' / $totalLaps',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceHigh,
              thumbColor: AppColors.accentSoft,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: playback.lap.toDouble().clamp(1.0, totalLaps.toDouble()).toDouble(),
              min: 1,
              max: totalLaps <= 1 ? 2 : totalLaps.toDouble(),
              onChanged: (value) => controller.jumpTo(value.round()),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Restart',
                onTap: controller.restart,
              ),
              _ControlButton(
                icon: Icons.skip_previous_rounded,
                tooltip: 'Previous lap',
                onTap: controller.previous,
              ),
              _ControlButton(
                icon: playback.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                tooltip: playback.playing ? 'Pause' : 'Play',
                primary: true,
                onTap: controller.togglePlay,
              ),
              _ControlButton(
                icon: Icons.skip_next_rounded,
                tooltip: 'Next lap',
                onTap: controller.next,
              ),
              _ControlButton(
                icon: Icons.flag_rounded,
                tooltip: 'Jump to finish',
                onTap: () => controller.jumpTo(totalLaps),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('SPEED', style: AppTextStyles.overline),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final speed in replaySpeeds) ...[
                Expanded(
                  child: _SpeedChip(
                    speed: speed,
                    selected: playback.speed == speed,
                    onTap: () => controller.setSpeed(speed),
                  ),
                ),
                if (speed != replaySpeeds.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: primary ? 52 : 42,
          height: primary ? 52 : 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? AppColors.accent : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(primary ? 16 : 12),
            border: Border.all(
              color: primary ? AppColors.accent : AppColors.surfaceStroke,
            ),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: -4,
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: primary ? 26 : 20,
            color: primary ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.speed,
    required this.selected,
    required this.onTap,
  });

  final double speed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.surfaceStroke,
          ),
        ),
        child: Text(
          speedLabel(speed),
          style: AppTextStyles.label.copyWith(
            color: selected ? AppColors.accentSoft : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
