import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/replay.dart';
import '../../../providers/replay_providers.dart';
import 'studio_panel.dart';

/// The race log. Events up to the current lap are shown newest-first; as the
/// replay advances the feed auto-scrolls to the latest event and the events on
/// the current lap are highlighted. Tapping an event jumps the replay to it.
class EventFeed extends ConsumerStatefulWidget {
  const EventFeed({super.key, required this.replay, this.height = 320});
  final RaceReplay replay;
  final double height;

  @override
  ConsumerState<EventFeed> createState() => _EventFeedState();
}

class _EventFeedState extends ConsumerState<EventFeed> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.replay.totalLaps;
    final lap = ref.watch(
      replayPlaybackProvider(total).select((s) => s.lap),
    );

    // Newest first so the current action sits at the top.
    final visible = widget.replay.events
        .where((e) => e.lap <= lap)
        .toList()
        .reversed
        .toList();

    // Keep the newest event in view as playback progresses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients && _controller.offset > 0) {
        _controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return StudioPanel(
      title: 'Race Feed',
      subtitle: '${visible.length} events',
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 12),
      child: SizedBox(
        height: widget.height,
        child: visible.isEmpty
            ? const PanelNotice(message: 'Press play to follow the race.')
            : ListView.builder(
                controller: _controller,
                padding: const EdgeInsets.only(right: 8),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final event = visible[index];
                  return _EventTile(
                    event: event,
                    current: event.lap == lap,
                    onTap: () => ref
                        .read(replayPlaybackProvider(total).notifier)
                        .jumpTo(event.lap),
                  );
                },
              ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.current,
    required this.onTap,
  });

  final RaceEvent event;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: current
              ? event.accent.withValues(alpha: 0.12)
              : AppColors.surfaceHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: current ? event.accent.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: event.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(event.type.icon, size: 15, color: event.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (event.detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.detail,
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('L${event.lap}',
                  style: AppTextStyles.overline.copyWith(fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}
