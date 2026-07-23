import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../models/replay.dart';
import '../../providers/replay_providers.dart';
import 'widgets/animated_leaderboard.dart';
import 'widgets/event_feed.dart';
import 'widgets/lap_analysis_chart.dart';
import 'widgets/position_history_chart.dart';
import 'widgets/race_selector.dart';
import 'widgets/race_stats_panel.dart';
import 'widgets/race_timeline.dart';
import 'widgets/replay_controls.dart';
import 'widgets/replay_shortcuts.dart';
import 'widgets/replay_states.dart';
import 'widgets/speed_analysis.dart';
import 'widgets/strategy_timeline.dart';
import 'widgets/studio_panel.dart';

/// Phase 4 — Race Replay & Strategy Simulator.
///
/// Professional-style strategy software: replay any completed Grand Prix lap by
/// lap with an animated leaderboard, tyre strategy, position history, lap-time
/// and speed analysis, a race timeline and a synchronized feed. The replay is
/// assembled once (Jolpica timing + optional telemetry enrichment) into an
/// immutable [RaceReplay]; playback advances a lap counter that panels `select`
/// individually, so a lap tick never rebuilds the whole studio.
class ReplayStudioScreen extends ConsumerWidget {
  const ReplayStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(replaySeasonProvider);
    final scheduleAsync = ref.watch(replayScheduleProvider(season));
    final request = ref.watch(replayRequestProvider);
    final pad = context.responsive(mobile: 16.0, desktop: 24.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 18),
          Expanded(
            child: scheduleAsync.when(
              loading: () => _buildBody(context, ref, const [], request),
              error: (e, _) => _buildBody(context, ref, const [], request),
              data: (result) => result.when(
                success: (races) => _buildBody(context, ref, races, request),
                failure: (f) => _buildBody(context, ref, const [], request),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<RaceListing> races,
    ReplayRequest? request,
  ) {
    final selector = RaceSelector(races: races);

    if (request == null) {
      // No race chosen yet: selector on the left, invitation on the right.
      if (context.isMobile) {
        return SingleChildScrollView(
          child: Column(children: [selector, const SizedBox(height: 300, child: ReplayEmpty())]),
        );
      }
      return SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 320, child: selector),
            const SizedBox(width: 20),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: ReplayEmpty(),
              ),
            ),
          ],
        ),
      );
    }

    final replayAsync = ref.watch(replayProvider(request));
    return replayAsync.when(
      loading: () => const ReplayLoading(),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(replayProvider(request)),
      ),
      data: (result) => result.when(
        success: (replay) => replay.isEmpty
            ? _EmptyReplay(selector: selector, meta: replay.meta)
            : _StudioLayout(replay: replay, selector: selector),
        failure: (f) => _ErrorView(
          message: f.message,
          onRetry: () => ref.invalidate(replayProvider(request)),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RACE REPLAY & STRATEGY', style: AppTextStyles.overline),
              const SizedBox(height: 4),
              Text('Replay Studio', style: AppTextStyles.displayLarge),
            ],
          ),
        ),
      ],
    );
  }
}

/// The assembled studio. A shared [DriverFilterBar] selection and the playback
/// lap flow into every panel; the layout reflows by breakpoint.
class _StudioLayout extends StatelessWidget {
  const _StudioLayout({required this.replay, required this.selector});
  final RaceReplay replay;
  final Widget selector;

  @override
  Widget build(BuildContext context) {
    // Desktop keyboard transport (space, arrows, R, Home/End, 1-4).
    return ReplayShortcuts(
      totalLaps: replay.totalLaps,
      child: _buildLayout(context),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final controls = ReplayControls(totalLaps: replay.totalLaps);
    final meta = RaceMetaHeader(
      meta: replay.meta,
      totalLaps: replay.totalLaps,
      hasTelemetry: replay.hasTelemetry,
    );
    final timeline = RaceTimeline(replay: replay);
    final leaderboard = AnimatedLeaderboard(replay: replay);
    final strategy = StrategyTimeline(replay: replay);
    final position = PositionHistoryChart(replay: replay);
    final lapAnalysis = LapAnalysisChart(replay: replay);
    final speed = SpeedAnalysis(replay: replay);
    final stats = RaceStatsPanel(replay: replay);
    final feed = EventFeed(replay: replay);

    Widget gap() => const SizedBox(height: 16);

    if (context.isDesktop) {
      // Three columns: controls & feed | leaderboard & charts | strategy & stats
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            meta,
            gap(),
            timeline,
            gap(),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: Column(
                      children: [
                        selector,
                        gap(),
                        controls,
                        const SizedBox(height: 10),
                        const ShortcutLegend(),
                        gap(),
                        feed,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        leaderboard,
                        gap(),
                        position,
                        gap(),
                        lapAnalysis,
                        gap(),
                        speed,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 340,
                    child: Column(
                      children: [
                        stats,
                        gap(),
                        strategy,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    if (context.isTablet) {
      // Two columns.
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          children: [
            meta,
            gap(),
            timeline,
            gap(),
            controls,
            gap(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(children: [leaderboard, gap(), strategy, gap(), position]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(children: [stats, gap(), feed, gap(), lapAnalysis, gap(), speed]),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    // Mobile: a single adaptive column that keeps every capability.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          meta,
          gap(),
          controls,
          gap(),
          timeline,
          gap(),
          leaderboard,
          gap(),
          stats,
          gap(),
          strategy,
          gap(),
          position,
          gap(),
          lapAnalysis,
          gap(),
          speed,
          gap(),
          feed,
          gap(),
          selector,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _EmptyReplay extends StatelessWidget {
  const _EmptyReplay({required this.selector, required this.meta});
  final Widget selector;
  final RaceMeta meta;

  @override
  Widget build(BuildContext context) {
    final body = StudioPanel(
      title: meta.raceName.isEmpty ? 'No timing data' : meta.raceName,
      subtitle: 'Lap-by-lap timing unavailable',
      child: const PanelNotice(
        message:
            'Lap-by-lap timing isn’t published for this event, so it can’t be '
            'replayed. Jolpica provides lap timing from 1996 onward — try a '
            'more recent race.',
        icon: Icons.timer_off_outlined,
      ),
    );

    if (context.isMobile) {
      return SingleChildScrollView(
        child: Column(children: [selector, const SizedBox(height: 16), body]),
      );
    }
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 320, child: selector),
          const SizedBox(width: 20),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
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
            Text('Couldn’t load this race',
                textAlign: TextAlign.center, style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
