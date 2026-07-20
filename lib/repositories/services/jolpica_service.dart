import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/json.dart';
import '../../models/analytics.dart';
import '../../models/standings.dart';

/// Typed access to the Jolpica (Ergast-compatible) endpoints.
///
/// Every Jolpica response is wrapped in `MRData → <Table> → <List>`. The helpers
/// here unwrap that envelope defensively before mapping to models.
class JolpicaService {
  JolpicaService(this._client);
  final DioClient _client;

  Map<String, dynamic> _mrData(dynamic data) {
    if (data is Map && data['MRData'] is Map) {
      return (data['MRData'] as Map).cast<String, dynamic>();
    }
    throw const ParseException('Unexpected Jolpica envelope.');
  }

  Future<List<DriverStanding>> driverStandings(String season) async {
    final data = await _client.getJson(
      ApiConstants.driverStandings(season),
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    final mr = _mrData(data);
    final lists = (mr['StandingsTable']?['StandingsLists'] as List?) ?? const [];
    if (lists.isEmpty) return const [];
    final rows = (lists.first['DriverStandings'] as List?) ?? const [];
    return rows
        .cast<Map>()
        .map((e) => DriverStanding.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<ConstructorStanding>> constructorStandings(String season) async {
    final data = await _client.getJson(
      ApiConstants.constructorStandings(season),
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    final mr = _mrData(data);
    final lists = (mr['StandingsTable']?['StandingsLists'] as List?) ?? const [];
    if (lists.isEmpty) return const [];
    final rows = (lists.first['ConstructorStandings'] as List?) ?? const [];
    return rows
        .cast<Map>()
        .map((e) => ConstructorStanding.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Raw race schedule rows for a season (kept as maps — the Calendar feature
  /// can map these into a typed `RaceEvent` model when it's built out).
  Future<List<Map<String, dynamic>>> raceSchedule(String season) async {
    final data = await _client.getJson(
      ApiConstants.raceSchedule(season),
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    final mr = _mrData(data);
    final races = (mr['RaceTable']?['Races'] as List?) ?? const [];
    return races.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  // ── Analytics feeds ─────────────────────────────────────────────────

  /// Current-season data changes after each race, so cache it briefly;
  /// completed seasons are immutable and can be cached for hours.
  Duration _ttl(String season) =>
      season == DateTime.now().year.toString()
          ? ApiConstants.defaultCacheTtl
          : ApiConstants.historicalCacheTtl;

  /// Every result of a season, paginated (Jolpica caps `limit` at 100).
  Future<List<RaceResultRow>> seasonResults(String season) async {
    final rows = <RaceResultRow>[];
    const limit = 100;
    var offset = 0;
    var total = 1 << 30;
    var pages = 0;
    while (offset < total && pages < 8) {
      final data = await _client.getJson(
        ApiConstants.seasonResults(season),
        query: {'limit': limit, 'offset': offset},
        cacheTtl: _ttl(season),
      );
      final mr = _mrData(data);
      total = Json.asInt(mr['total']) ?? rows.length;
      final races = (mr['RaceTable']?['Races'] as List?) ?? const [];
      if (races.isEmpty) break;
      var pageRows = 0;
      for (final raceRaw in races.cast<Map>()) {
        final race = raceRaw.cast<String, dynamic>();
        final round = Json.asInt(race['round']) ?? 0;
        final raceName = Json.asString(race['raceName']);
        final results = (race['Results'] as List?) ?? const [];
        for (final r in results.cast<Map>()) {
          rows.add(RaceResultRow.fromResult(
            round: round,
            raceName: raceName,
            json: r.cast<String, dynamic>(),
          ));
          pageRows++;
        }
      }
      offset += limit;
      pages++;
      if (pageRows == 0) break;
    }
    return rows;
  }

  /// Pole counts per `driverId` (one lightweight call via the `/qualifying/1`
  /// server-side filter instead of paging the whole qualifying feed).
  Future<Map<String, int>> polePositions(String season) async {
    final data = await _client.getJson(
      ApiConstants.seasonQualifyingPole(season),
      query: {'limit': 100},
      cacheTtl: _ttl(season),
    );
    final mr = _mrData(data);
    final races = (mr['RaceTable']?['Races'] as List?) ?? const [];
    final poles = <String, int>{};
    for (final raceRaw in races.cast<Map>()) {
      final race = raceRaw.cast<String, dynamic>();
      final qr = (race['QualifyingResults'] as List?) ?? const [];
      for (final q in qr.cast<Map>()) {
        final row = q.cast<String, dynamic>();
        if ((Json.asInt(row['position']) ?? 0) == 1) {
          final driver = (row['Driver'] as Map?)?.cast<String, dynamic>() ?? {};
          final id = Json.asString(driver['driverId']);
          if (id.isNotEmpty) poles[id] = (poles[id] ?? 0) + 1;
        }
      }
    }
    return poles;
  }

  /// Season finish-status breakdown (Finished / +1 Lap / Engine / …).
  Future<List<StatusSlice>> seasonStatus(String season) async {
    final data = await _client.getJson(
      ApiConstants.seasonStatus(season),
      query: {'limit': 100},
      cacheTtl: _ttl(season),
    );
    final mr = _mrData(data);
    final list = (mr['StatusTable']?['Status'] as List?) ?? const [];
    return list.cast<Map>().map((e) {
      final m = e.cast<String, dynamic>();
      return StatusSlice(
        label: Json.asString(m['status'], 'Unknown'),
        count: Json.asInt(m['count']) ?? 0,
      );
    }).toList();
  }

  /// Pit-stop analytics for the most recent race of the season.
  Future<PitAnalytics?> lastRacePitStops(String season) async {
    final data = await _client.getJson(
      ApiConstants.lastPitStops(season),
      query: {'limit': 100},
      cacheTtl: ApiConstants.defaultCacheTtl,
    );
    final mr = _mrData(data);
    final races = (mr['RaceTable']?['Races'] as List?) ?? const [];
    if (races.isEmpty) return null;
    final race = races.first.cast<String, dynamic>();
    final raceName = Json.asString(race['raceName']);
    final stops = (race['PitStops'] as List?) ?? const [];
    if (stops.isEmpty) return null;

    var sum = 0.0;
    var count = 0;
    double? fastest;
    var fastestLabel = '';
    for (final s in stops.cast<Map>()) {
      final m = s.cast<String, dynamic>();
      final dur = _seconds(Json.asString(m['duration']));
      if (dur == null) continue;
      sum += dur;
      count++;
      if (fastest == null || dur < fastest) {
        fastest = dur;
        fastestLabel = Json.asString(m['driverId']);
      }
    }
    if (count == 0) return null;
    return PitAnalytics(
      raceName: raceName,
      avgSeconds: sum / count,
      fastestSeconds: fastest ?? 0,
      fastestLabel: fastestLabel,
      stops: count,
    );
  }

  static double? _seconds(String raw) {
    if (raw.isEmpty) return null;
    final parts = raw.split(':');
    try {
      if (parts.length == 2) {
        return int.parse(parts[0]) * 60 + double.parse(parts[1]);
      }
      return double.parse(parts[0]);
    } catch (_) {
      return null;
    }
  }
}
