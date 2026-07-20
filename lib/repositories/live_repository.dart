import '../core/errors/failures.dart';
import '../core/network/result.dart';
import '../models/live_entry.dart';
import '../models/session.dart';
import '../models/weather.dart';
import 'services/openf1_service.dart';

/// Aggregates the several OpenF1 live feeds into cohesive view models.
class LiveRepository {
  LiveRepository(this._openF1);
  final OpenF1Service _openF1;

  Future<Result<F1Session>> latestSession() => _guard(_openF1.latestSession);

  Future<Result<F1Weather?>> weather(int sessionKey) =>
      _guard(() => _openF1.latestWeather(sessionKey));

  /// Builds the live leaderboard by joining drivers, positions, intervals and
  /// stints. Returns entries already sorted by track position.
  Future<Result<List<LiveEntry>>> leaderboard(int sessionKey) async {
    return _guard(() async {
      final drivers = await _openF1.drivers(sessionKey);
      final positions = await _openF1.positions(sessionKey);
      final intervals = await _openF1.intervals(sessionKey);
      final stints = await _openF1.stints(sessionKey);

      final entries = <LiveEntry>[];
      for (final driver in drivers) {
        final pos = positions[driver.driverNumber];
        if (pos == null) continue; // skip cars not on track
        final gap = intervals[driver.driverNumber];
        final stint = stints[driver.driverNumber];
        entries.add(
          LiveEntry(
            driver: driver,
            position: pos,
            gapToLeader: gap?.gapToLeader,
            interval: gap?.interval,
            compound: stint?.compound,
            stintLaps: stint?.laps,
          ),
        );
      }
      entries.sort((a, b) => a.position.compareTo(b.position));
      return entries;
    });
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
