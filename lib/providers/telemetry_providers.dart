import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failures.dart';
import '../core/network/result.dart';
import '../models/driver.dart';
import '../models/telemetry.dart';
import '../repositories/telemetry_repository.dart';
import 'core_providers.dart';

// ── Driver list for the active session ─────────────────────────────────
final telemetryDriversProvider =
    FutureProvider.family<Result<List<F1Driver>>, int>((ref, sessionKey) {
  return ref.watch(telemetryRepositoryProvider).drivers(sessionKey);
});

/// The driver whose telemetry is on screen. `null` means "default to the first
/// available driver" — resolved in the UI once the driver list loads.
final selectedDriverProvider = StateProvider<int?>((ref) => null);

// ── Current track position (low-frequency, separate from the trace) ────
typedef PositionArgs = ({int sessionKey, int driverNumber});

final driverPositionProvider =
    FutureProvider.family<Result<int?>, PositionArgs>((ref, args) {
  final timer = Timer(
    const Duration(seconds: 10),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return ref
      .watch(telemetryRepositoryProvider)
      .position(args.sessionKey, args.driverNumber);
});

// ── Streaming telemetry buffer ─────────────────────────────────────────

enum TelemetryStatus { loading, streaming, error }

/// Immutable view of the live telemetry buffer.
class TelemetryState {
  const TelemetryState({
    this.samples = const [],
    this.status = TelemetryStatus.loading,
    this.failure,
    this.paused = false,
  });

  final List<TelemetrySample> samples;
  final TelemetryStatus status;
  final Failure? failure;
  final bool paused;

  TelemetrySample? get latest => samples.isEmpty ? null : samples.last;
  bool get hasData => samples.isNotEmpty;

  TelemetryState copyWith({
    List<TelemetrySample>? samples,
    TelemetryStatus? status,
    Failure? failure,
    bool clearFailure = false,
    bool? paused,
  }) {
    return TelemetryState(
      samples: samples ?? this.samples,
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
      paused: paused ?? this.paused,
    );
  }
}

/// Identifies one telemetry stream. Equality drives Riverpod family caching, so
/// switching driver spins up a fresh notifier and disposes the previous one.
class TelemetryArgs {
  const TelemetryArgs({
    required this.sessionKey,
    required this.driverNumber,
    required this.sessionStart,
  });

  final int sessionKey;
  final int driverNumber;
  final DateTime sessionStart;

  @override
  bool operator ==(Object other) =>
      other is TelemetryArgs &&
      other.sessionKey == sessionKey &&
      other.driverNumber == driverNumber &&
      other.sessionStart == sessionStart;

  @override
  int get hashCode => Object.hash(sessionKey, driverNumber, sessionStart);
}

/// Streams telemetry by repeatedly fetching a small time window and appending
/// only the *new* samples to a capped rolling buffer. A playback cursor walks
/// forward through the session, so the trace flows continuously for both live
/// and recently-completed sessions. When the cursor outruns the available data
/// it loops back, keeping the dashboard alive indefinitely.
class TelemetryStreamNotifier extends StateNotifier<TelemetryState> {
  TelemetryStreamNotifier(this._repo, this._args)
      : super(const TelemetryState()) {
    _cursor = _anchor;
    _tick();
  }

  final TelemetryRepository _repo;
  final TelemetryArgs _args;

  // Tuning constants.
  static const Duration _window = Duration(seconds: 6);
  static const Duration _interval = Duration(seconds: 3);
  static const Duration _initialOffset = Duration(minutes: 18);
  static const int _maxBuffer = 200;
  static const int _emptyBeforeRewind = 10;

  late DateTime _cursor;
  Timer? _timer;
  bool _busy = false;
  int _emptyStreak = 0;

  DateTime get _anchor => _args.sessionStart.toUtc().add(_initialOffset);

  Future<void> _tick() async {
    if (!mounted) return;
    if (state.paused || _busy) {
      _schedule();
      return;
    }
    _busy = true;
    final until = _cursor.add(_window);
    final res = await _repo.window(
      sessionKey: _args.sessionKey,
      driverNumber: _args.driverNumber,
      since: _cursor,
      until: until,
    );
    if (!mounted) return;

    res.when(
      success: (batch) {
        if (batch.isNotEmpty) {
          _emptyStreak = 0;
          final merged = <TelemetrySample>[...state.samples, ...batch];
          final trimmed = merged.length > _maxBuffer
              ? merged.sublist(merged.length - _maxBuffer)
              : merged;
          state = state.copyWith(
            samples: trimmed,
            status: TelemetryStatus.streaming,
            clearFailure: true,
          );
          // Advance just past the last sample so windows stay contiguous.
          _cursor = batch.last.date.toUtc().add(const Duration(milliseconds: 1));
        } else {
          _emptyStreak++;
          _cursor = until;
          // Empty early (initial offset landed in a gap) → drop to session start.
          if (_emptyStreak == 3 && state.samples.isEmpty) {
            _cursor = _args.sessionStart.toUtc();
          }
          // Ran past the end of available data → loop the replay.
          if (_emptyStreak >= _emptyBeforeRewind) {
            _emptyStreak = 0;
            _cursor = _anchor;
          }
          state = state.copyWith(
            status: state.samples.isEmpty
                ? TelemetryStatus.loading
                : TelemetryStatus.streaming,
          );
        }
      },
      failure: (f) {
        state = state.copyWith(
          status: state.samples.isEmpty
              ? TelemetryStatus.error
              : TelemetryStatus.streaming,
          failure: f,
        );
      },
    );

    _busy = false;
    _schedule();
  }

  void _schedule() {
    if (!mounted) return;
    _timer?.cancel();
    _timer = Timer(_interval, _tick);
  }

  void togglePause() => state = state.copyWith(paused: !state.paused);

  /// Clears the buffer and restarts the replay from the anchor point.
  void restart() {
    _emptyStreak = 0;
    _cursor = _anchor;
    state = const TelemetryState();
    _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final telemetryStreamProvider = StateNotifierProvider.autoDispose
    .family<TelemetryStreamNotifier, TelemetryState, TelemetryArgs>((ref, args) {
  return TelemetryStreamNotifier(ref.watch(telemetryRepositoryProvider), args);
});
