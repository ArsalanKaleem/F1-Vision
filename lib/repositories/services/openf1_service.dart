import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../../models/driver.dart';
import '../../models/session.dart';
import '../../models/telemetry.dart';
import '../../models/weather.dart';

/// Typed access to the OpenF1 endpoints used by the app.
///
/// OpenF1 returns bare JSON arrays. Every method coerces that into typed
/// models and throws an [AppException] (via [DioClient]) on failure — the
/// repository layer is responsible for turning those into [Failure]s.
class OpenF1Service {
  OpenF1Service(this._client);
  final DioClient _client;

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    throw const ParseException('Expected a JSON array from OpenF1.');
  }

  /// The latest (or live) session.
  Future<F1Session> latestSession() async {
    final data = await _client.getJson(
      ApiConstants.sessions,
      query: {'session_key': ApiConstants.latest},
      cacheTtl: ApiConstants.defaultCacheTtl,
    );
    final list = _asList(data);
    if (list.isEmpty) throw const ServerException('No session available.');
    return F1Session.fromJson(list.last);
  }

  /// All sessions in a season (used for the calendar).
  Future<List<F1Session>> sessionsForYear(int year) async {
    final data = await _client.getJson(
      ApiConstants.sessions,
      query: {'year': year},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    return _asList(data).map(F1Session.fromJson).toList();
  }

  Future<List<F1Driver>> drivers(int sessionKey) async {
    final data = await _client.getJson(
      ApiConstants.drivers,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    return _asList(data).map(F1Driver.fromJson).toList();
  }

  /// Latest weather sample for a session.
  Future<F1Weather?> latestWeather(int sessionKey) async {
    final data = await _client.getJson(
      ApiConstants.weather,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.defaultCacheTtl,
    );
    final list = _asList(data);
    return list.isEmpty ? null : F1Weather.fromJson(list.last);
  }

  /// Live driver→position map. Latest position per driver wins.
  Future<Map<int, int>> positions(int sessionKey) async {
    final data = await _client.getJson(
      ApiConstants.position,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.defaultCacheTtl,
    );
    final map = <int, int>{};
    for (final row in _asList(data)) {
      final driverNo = row['driver_number'] as int?;
      final pos = row['position'] as int?;
      if (driverNo != null && pos != null) map[driverNo] = pos;
    }
    return map;
  }

  /// Latest interval/gap-to-leader per driver.
  Future<Map<int, ({double? gapToLeader, double? interval})>> intervals(
    int sessionKey,
  ) async {
    final data = await _client.getJson(
      ApiConstants.intervals,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.defaultCacheTtl,
    );
    final map = <int, ({double? gapToLeader, double? interval})>{};
    for (final row in _asList(data)) {
      final driverNo = row['driver_number'] as int?;
      if (driverNo == null) continue;
      map[driverNo] = (
        gapToLeader: _toDouble(row['gap_to_leader']),
        interval: _toDouble(row['interval']),
      );
    }
    return map;
  }

  /// Latest stint (compound + lap count) per driver.
  Future<Map<int, ({String compound, int laps})>> stints(int sessionKey) async {
    final data = await _client.getJson(
      ApiConstants.stints,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.defaultCacheTtl,
    );
    final map = <int, ({String compound, int laps})>{};
    for (final row in _asList(data)) {
      final driverNo = row['driver_number'] as int?;
      if (driverNo == null) continue;
      final start = (row['lap_start'] as num?)?.toInt() ?? 0;
      final end = (row['lap_end'] as num?)?.toInt() ?? start;
      map[driverNo] = (
        compound: (row['compound'] ?? 'UNKNOWN').toString(),
        laps: (end - start).clamp(0, 200),
      );
    }
    return map;
  }

  static double? _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  /// A bounded slice of car telemetry for one driver, `[since, until)`.
  ///
  /// OpenF1's `/car_data` is huge over a full session, so we always fetch a
  /// small time window. The relational operators are baked into the query
  /// string (OpenF1's documented `date>=…&date<…` syntax) and percent-encoded —
  /// exactly what a browser sends, which OpenF1 accepts. Results come back
  /// unsorted, so we order by timestamp before returning.
  Future<List<TelemetrySample>> carDataWindow({
    required int sessionKey,
    required int driverNumber,
    required DateTime since,
    required DateTime until,
  }) async {
    final gte = Uri.encodeComponent('>='); // -> %3E%3D
    final lt = Uri.encodeComponent('<'); // -> %3C
    final sinceIso = Uri.encodeQueryComponent(since.toUtc().toIso8601String());
    final untilIso = Uri.encodeQueryComponent(until.toUtc().toIso8601String());

    final path = '${ApiConstants.carData}'
        '?session_key=$sessionKey'
        '&driver_number=$driverNumber'
        '&date$gte$sinceIso'
        '&date$lt$untilIso';

    final data = await _client.getJson(path); // live window — uncached
    final samples = _asList(data).map(TelemetrySample.fromJson).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return samples;
  }
}
