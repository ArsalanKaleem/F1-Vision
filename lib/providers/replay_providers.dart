import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/result.dart';
import '../models/replay.dart';
import 'core_providers.dart';

// ── Selection ──────────────────────────────────────────────────────────

/// Season being browsed in the replay studio (independent of other screens).
final replaySeasonProvider =
    StateProvider<String>((ref) => DateTime.now().year.toString());

/// Seasons offered in the picker. OpenF1 enrichment starts in 2023, but
/// Jolpica lap timing goes back to 1996 — both are replayable.
final replaySeasonOptionsProvider = Provider<List<String>>((ref) {
  final year = DateTime.now().year;
  return [for (var y = year; y >= 1996; y--) y.toString()];
});

/// Selected Grand Prix (round number) within the season; null until chosen.
final replayRoundProvider = StateProvider<int?>((ref) => null);

/// Selected session of the weekend.
final replaySessionProvider =
    StateProvider<ReplaySession>((ref) => ReplaySession.race);

/// Completed races of the selected season.
final replayScheduleProvider =
    FutureProvider.family<Result<List<RaceListing>>, String>((ref, season) {
  return ref.watch(replayRepositoryProvider).schedule(season);
});

/// Identifies one replayable event. Value equality keeps the family cache
/// stable so scrubbing never refetches.
class ReplayRequest {
  const ReplayRequest({
    required this.season,
    required this.round,
    required this.session,
  });

  final String season;
  final int round;
  final ReplaySession session;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReplayRequest &&
          other.season == season &&
          other.round == round &&
          other.session == session;

  @override
  int get hashCode => Object.hash(season, round, session);
}

/// The currently selected event, or null while the user hasn't picked one.
final replayRequestProvider = Provider<ReplayRequest?>((ref) {
  final round = ref.watch(replayRoundProvider);
  if (round == null) return null;
  return ReplayRequest(
    season: ref.watch(replaySeasonProvider),
    round: round,
    session: ref.watch(replaySessionProvider),
  );
});

/// The assembled replay. Cached per request — a completed race never changes,
/// so re-selecting one is instant.
final replayProvider =
    FutureProvider.family<Result<RaceReplay>, ReplayRequest>((ref, request) {
  return ref.watch(replayRepositoryProvider).replay(
        season: request.season,
        round: request.round,
        session: request.session,
      );
});

/// Drivers highlighted in the analysis charts (empty = automatic top runners).
final focusedDriversProvider = StateProvider<Set<String>>((ref) => {});

// ── Playback ───────────────────────────────────────────────────────────

/// Available replay speeds.
const replaySpeeds = <double>[0.5, 1, 2, 5];

/// Immutable playback state. Widgets `select` the single field they need so a
/// lap tick never rebuilds the whole studio.
class ReplayPlayback {
  const ReplayPlayback({
    required this.lap,
    required this.totalLaps,
    required this.playing,
    required this.speed,
  });

  final int lap;
  final int totalLaps;
  final bool playing;
  final double speed;

  bool get atEnd => lap >= totalLaps;
  double get progress => totalLaps <= 1 ? 0 : (lap - 1) / (totalLaps - 1);

  ReplayPlayback copyWith({int? lap, bool? playing, double? speed}) =>
      ReplayPlayback(
        lap: lap ?? this.lap,
        totalLaps: totalLaps,
        playing: playing ?? this.playing,
        speed: speed ?? this.speed,
      );
}

/// Drives lap-by-lap playback with a cancellable ticker.
class ReplayController extends StateNotifier<ReplayPlayback> {
  ReplayController(int totalLaps)
      : super(ReplayPlayback(
          lap: 1,
          totalLaps: totalLaps < 1 ? 1 : totalLaps,
          playing: false,
          speed: 1,
        ));

  /// Wall-clock duration of one lap at 1× — slow enough to read the board,
  /// fast enough to feel like a replay.
  static const _baseLapDuration = Duration(milliseconds: 1100);

  Timer? _timer;

  void play() {
    if (state.playing) return;
    if (state.atEnd) jumpTo(1);
    state = state.copyWith(playing: true);
    _schedule();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    if (state.playing) state = state.copyWith(playing: false);
  }

  void togglePlay() => state.playing ? pause() : play();

  void restart() {
    pause();
    state = state.copyWith(lap: 1);
  }

  void next() => jumpTo(state.lap + 1);

  void previous() => jumpTo(state.lap - 1);

  void jumpTo(int lap) {
    final clamped = lap.clamp(1, state.totalLaps);
    if (clamped == state.lap) return;
    state = state.copyWith(lap: clamped);
  }

  void setSpeed(double speed) {
    if (speed == state.speed) return;
    state = state.copyWith(speed: speed);
    if (state.playing) _schedule(); // re-arm at the new cadence
  }

  void _schedule() {
    _timer?.cancel();
    final ms = (_baseLapDuration.inMilliseconds / state.speed).round();
    _timer = Timer.periodic(Duration(milliseconds: ms < 40 ? 40 : ms), (_) {
      if (state.atEnd) {
        pause();
        return;
      }
      state = state.copyWith(lap: state.lap + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Playback for one race, keyed by lap count so switching events resets the
/// ticker cleanly. `autoDispose` guarantees no timer outlives the screen.
final replayPlaybackProvider = StateNotifierProvider.autoDispose
    .family<ReplayController, ReplayPlayback, int>(
  (ref, totalLaps) => ReplayController(totalLaps),
);
