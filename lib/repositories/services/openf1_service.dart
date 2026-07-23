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

  static int? _toInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  // ── Historical session feeds (replay enrichment) ────────────────────
  //
  // OpenF1 only covers 2023 onwards. Every method here is optional extra
  // detail: the replay is fully functional from Jolpica alone.

  /// Finds the session of a given weekend by calendar date, e.g. the Race on
  /// 2024-03-02. Returns null when OpenF1 has no data for that event.
  Future<F1Session?> sessionOnDate({
    required int year,
    required DateTime date,
    required String sessionName,
  }) async {
    final sessions = await sessionsForYear(year);
    final target = DateTime.utc(date.year, date.month, date.day);
    F1Session? best;
    for (final s in sessions) {
      if (s.sessionName.toLowerCase() != sessionName.toLowerCase()) continue;
      final start = s.dateStart;
      if (start == null) continue;
      final day = DateTime.utc(start.year, start.month, start.day);
      // Allow ±1 day: OpenF1 timestamps are UTC while Jolpica dates are local.
      if (day.difference(target).inDays.abs() <= 1) {
        best ??= s;
      }
    }
    return best;
  }

  /// Tyre stints for a session.
  Future<List<({int driverNumber, int lapStart, int lapEnd, String compound})>>
      sessionStints(int sessionKey) async {
    final data = await _client.getJson(
      ApiConstants.stints,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    final out =
        <({int driverNumber, int lapStart, int lapEnd, String compound})>[];
    for (final row in _asList(data)) {
      final driverNo = _toInt(row['driver_number']);
      if (driverNo == null) continue;
      final start = _toInt(row['lap_start']) ?? 0;
      out.add((
        driverNumber: driverNo,
        lapStart: start,
        lapEnd: _toInt(row['lap_end']) ?? start,
        compound: (row['compound'] ?? 'UNKNOWN').toString().toUpperCase(),
      ));
    }
    return out;
  }

  /// Race-control messages (safety car, flags, incidents).
  Future<
      List<
          ({
            int? lap,
            String category,
            String flag,
            String message,
            String scope
          })>> sessionRaceControl(int sessionKey) async {
    final data = await _client.getJson(
      ApiConstants.raceControl,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    return _asList(data)
        .map((row) => (
              lap: _toInt(row['lap_number']),
              category: (row['category'] ?? '').toString(),
              flag: (row['flag'] ?? '').toString(),
              message: (row['message'] ?? '').toString(),
              scope: (row['scope'] ?? '').toString(),
            ))
        .toList();
  }

  /// Per-lap timing detail: lap duration, sector splits and speed-trap value.
  Future<
      List<
          ({
            int driverNumber,
            int lapNumber,
            double? duration,
            double? sector1,
            double? sector2,
            double? sector3,
            double? topSpeed,
            DateTime? startedAt
          })>> sessionLaps(int sessionKey) async {
    final data = await _client.getJson(
      ApiConstants.laps,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    final out = <({
      int driverNumber,
      int lapNumber,
      double? duration,
      double? sector1,
      double? sector2,
      double? sector3,
      double? topSpeed,
      DateTime? startedAt
    })>[];
    for (final row in _asList(data)) {
      final driverNo = _toInt(row['driver_number']);
      final lapNo = _toInt(row['lap_number']);
      if (driverNo == null || lapNo == null) continue;
      out.add((
        driverNumber: driverNo,
        lapNumber: lapNo,
        duration: _toDouble(row['lap_duration']),
        sector1: _toDouble(row['duration_sector_1']),
        sector2: _toDouble(row['duration_sector_2']),
        sector3: _toDouble(row['duration_sector_3']),
        topSpeed: _toDouble(row['st_speed']),
        startedAt: DateTime.tryParse(row['date_start']?.toString() ?? ''),
      ));
    }
    return out;
  }

  /// Weather samples across a session (used to detect rain transitions).
  Future<List<({DateTime? date, double? airTemp, double? trackTemp, int? rain})>>
      sessionWeatherSeries(int sessionKey) async {
    final data = await _client.getJson(
      ApiConstants.weather,
      query: {'session_key': sessionKey},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    return _asList(data)
        .map((row) => (
              date: DateTime.tryParse(row['date']?.toString() ?? ''),
              airTemp: _toDouble(row['air_temperature']),
              trackTemp: _toDouble(row['track_temperature']),
              rain: _toInt(row['rainfall']),
            ))
        .toList();
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
