import '../core/errors/failures.dart';
import '../core/network/result.dart';
import '../models/driver.dart';
import '../models/telemetry.dart';
import 'services/openf1_service.dart';

/// Repository for the Telemetry feature. Mirrors [LiveRepository]'s `_guard`
/// pattern so every call returns a [Result] instead of throwing across layers.
class TelemetryRepository {
  TelemetryRepository(this._openF1);
  final OpenF1Service _openF1;

  /// Drivers entered for a session (used to populate the driver selector).
  Future<Result<List<F1Driver>>> drivers(int sessionKey) =>
      _guard(() => _openF1.drivers(sessionKey));

  /// A bounded `[since, until)` telemetry window for one driver.
  Future<Result<List<TelemetrySample>>> window({
    required int sessionKey,
    required int driverNumber,
    required DateTime since,
    required DateTime until,
  }) =>
      _guard(
        () => _openF1.carDataWindow(
          sessionKey: sessionKey,
          driverNumber: driverNumber,
          since: since,
          until: until,
        ),
      );

  /// The driver's current track position (nullable if not classified).
  Future<Result<int?>> position(int sessionKey, int driverNumber) => _guard(
        () async => (await _openF1.positions(sessionKey))[driverNumber],
      );

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
