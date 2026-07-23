import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'studio_panel.dart';

/// A horizontal strip of the whole race: safety cars, flags, pit stops,
/// overtakes, weather changes and fastest laps, positioned by lap. Tapping a
/// marker jumps the replay to that moment.
class RaceTimeline extends ConsumerWidget {
  const RaceTimeline({super.key, required this.replay});
  final RaceReplay replay;

  /// Event types that earn their own marker on the strip. Pit stops and
  /// overtakes are far too numerous — they stay in the feed below.
  static const _tracked = {
    RaceEventType.safetyCar,
    RaceEventType.virtualSafetyCar,
    RaceEventType.redFlag,
    RaceEventType.yellowFlag,
    RaceEventType.greenFlag,
    RaceEventType.weather,
    RaceEventType.fastestLap,
    RaceEventType.retirement,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = replay.totalLaps;
    final lap = ref.watch(
      replayPlaybackProvider(total).select((s) => s.lap),
    );
    final controller = ref.read(replayPlaybackProvider(total).notifier);

    final markers = replay.events.where((e) => _tracked.contains(e.type)).toList();
    final pitLaps = <int>{
      for (final e in replay.events)
        if (e.type == RaceEventType.pitStop) e.lap,
    };

    return StudioPanel(
      title: 'Race Timeline',
      subtitle: 'Tap any marker to jump',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 62,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                double xFor(int atLap) {
                  if (total <= 1) return 0;
                  final fraction = (atLap - 1) / (total - 1);
                  return (fraction * (width - 14)).clamp(0.0, width - 14).toDouble();
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    if (total <= 1) return;
                    final fraction =
                        (details.localPosition.dx / width).clamp(0.0, 1.0);
                    controller.jumpTo((fraction * (total - 1)).round() + 1);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Track.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 26,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: AppColors.surfaceStroke),
                          ),
                        ),
                      ),
                      // Progress fill.
                      Positioned(
                        left: 0,
                        top: 26,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                          height: 8,
                          width: total <= 1
                              ? 0
                              : ((lap - 1) / (total - 1)) * width,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Pit-stop ticks (dense, so drawn as thin marks).
                      for (final pitLap in pitLaps)
                        Positioned(
                          left: xFor(pitLap) + 6,
                          top: 38,
                          child: Container(
                            width: 2,
                            height: 7,
                            color: AppColors.info.withValues(alpha: 0.75),
                          ),
                        ),
                      // Event markers.
                      for (final event in markers)
                        Positioned(
                          left: xFor(event.lap),
                          top: 6,
                          child: _Marker(
                            event: event,
                            onTap: () => controller.jumpTo(event.lap),
                          ),
                        ),
                      // Playhead.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                        left: xFor(lap) + 3,
                        top: 18,
                        child: Container(
                          width: 3,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('LAP 1', style: AppTextStyles.overline),
              const Spacer(),
              Text('LAP $total', style: AppTextStyles.overline),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final type in _legendTypes(markers, pitLaps.isNotEmpty))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 12, color: type.color),
                    const SizedBox(width: 4),
                    Text(type.label, style: AppTextStyles.overline),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static List<RaceEventType> _legendTypes(
    List<RaceEvent> markers,
    bool hasPits,
  ) {
    final present = <RaceEventType>{for (final m in markers) m.type};
    if (hasPits) present.add(RaceEventType.pitStop);
    final ordered = RaceEventType.values.where(present.contains).toList();
    return ordered;
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.event, required this.onTap});
  final RaceEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Lap ${event.lap} · ${event.title}',
      waitDuration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: event.type.color.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: event.type.color, width: 1.5),
            ),
            child: Icon(event.type.icon, size: 8, color: event.type.color),
          ),
        ),
      ),
    );
  }
}
