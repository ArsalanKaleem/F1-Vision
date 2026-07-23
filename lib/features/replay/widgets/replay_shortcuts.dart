import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/replay_providers.dart';

// ── Intents ────────────────────────────────────────────────────────────
class _PlayPauseIntent extends Intent {
  const _PlayPauseIntent();
}

class _NextLapIntent extends Intent {
  const _NextLapIntent();
}

class _PrevLapIntent extends Intent {
  const _PrevLapIntent();
}

class _RestartIntent extends Intent {
  const _RestartIntent();
}

class _JumpStartIntent extends Intent {
  const _JumpStartIntent();
}

class _JumpEndIntent extends Intent {
  const _JumpEndIntent();
}

class _SpeedIntent extends Intent {
  const _SpeedIntent(this.speed);
  final double speed;
}

/// Wraps the replay studio in desktop keyboard controls.
///
/// Space toggles playback, ←/→ step laps, Home/End jump to the start or the
/// flag, R restarts and 1–4 select a replay speed. The subtree is wrapped in a
/// [FocusScope] that requests focus on mount, so the shortcuts work without the
/// user clicking first — while text fields inside still capture typing
/// normally.
class ReplayShortcuts extends ConsumerWidget {
  const ReplayShortcuts({
    super.key,
    required this.totalLaps,
    required this.child,
  });

  final int totalLaps;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(replayPlaybackProvider(totalLaps).notifier);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): _PlayPauseIntent(),
        SingleActivator(LogicalKeyboardKey.keyK): _PlayPauseIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextLapIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PrevLapIntent(),
        SingleActivator(LogicalKeyboardKey.keyR): _RestartIntent(),
        SingleActivator(LogicalKeyboardKey.home): _JumpStartIntent(),
        SingleActivator(LogicalKeyboardKey.end): _JumpEndIntent(),
        SingleActivator(LogicalKeyboardKey.digit1): _SpeedIntent(0.5),
        SingleActivator(LogicalKeyboardKey.digit2): _SpeedIntent(1),
        SingleActivator(LogicalKeyboardKey.digit3): _SpeedIntent(2),
        SingleActivator(LogicalKeyboardKey.digit4): _SpeedIntent(5),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PlayPauseIntent: CallbackAction<_PlayPauseIntent>(
            onInvoke: (_) {
              controller.togglePlay();
              return null;
            },
          ),
          _NextLapIntent: CallbackAction<_NextLapIntent>(
            onInvoke: (_) {
              controller.next();
              return null;
            },
          ),
          _PrevLapIntent: CallbackAction<_PrevLapIntent>(
            onInvoke: (_) {
              controller.previous();
              return null;
            },
          ),
          _RestartIntent: CallbackAction<_RestartIntent>(
            onInvoke: (_) {
              controller.restart();
              return null;
            },
          ),
          _JumpStartIntent: CallbackAction<_JumpStartIntent>(
            onInvoke: (_) {
              controller.jumpTo(1);
              return null;
            },
          ),
          _JumpEndIntent: CallbackAction<_JumpEndIntent>(
            onInvoke: (_) {
              controller.jumpTo(totalLaps);
              return null;
            },
          ),
          _SpeedIntent: CallbackAction<_SpeedIntent>(
            onInvoke: (intent) {
              controller.setSpeed(intent.speed);
              return null;
            },
          ),
        },
        child: FocusScope(autofocus: true, child: child),
      ),
    );
  }
}

/// Compact legend of the available shortcuts, shown on desktop only.
class ShortcutLegend extends StatelessWidget {
  const ShortcutLegend({super.key});

  static const _items = <({String keys, String action})>[
    (keys: 'Space', action: 'Play / pause'),
    (keys: '← →', action: 'Step lap'),
    (keys: 'R', action: 'Restart'),
    (keys: 'Home / End', action: 'Start / finish'),
    (keys: '1–4', action: 'Speed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Keyboard shortcuts: space play or pause, arrow keys step lap, '
          'R restart, Home and End jump to start or finish, number keys 1 to 4 '
          'set replay speed.',
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          for (final item in _items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm - 2),
                    border: Border.all(color: AppColors.surfaceStroke),
                  ),
                  child: Text(item.keys,
                      style: AppTextStyles.overline.copyWith(fontSize: 9)),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(item.action,
                    style: AppTextStyles.overline
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
        ],
      ),
    );
  }
}
