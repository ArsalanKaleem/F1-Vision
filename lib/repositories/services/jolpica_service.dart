import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/json.dart';
import '../../models/analytics.dart';
import '../../models/replay.dart';
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
    final race = (races.first as Map).cast<String, dynamic>();
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

  // ── Race replay feeds ───────────────────────────────────────────────

  /// The season calendar as typed listings for the replay picker.
  Future<List<RaceListing>> seasonSchedule(String season) async {
    final races = await raceSchedule(season);
    return races.map((race) {
      final circuit = (race['Circuit'] as Map?)?.cast<String, dynamic>() ?? {};
      final location =
          (circuit['Location'] as Map?)?.cast<String, dynamic>() ?? {};
      return RaceListing(
        season: season,
        round: Json.asInt(race['round']) ?? 0,
        raceName: Json.asString(race['raceName']),
        circuitName: Json.asString(circuit['circuitName']),
        locality: Json.asString(location['locality']),
        country: Json.asString(location['country']),
        date: Json.asDate(race['date']),
        hasSprint: race['Sprint'] != null,
      );
    }).toList();
  }

  /// Race (or sprint) classification plus the race header block.
  Future<({Map<String, dynamic> race, List<Map<String, dynamic>> results})>
      raceResults(
    String season,
    int round, {
    ReplaySession session = ReplaySession.race,
  }) async {
    final path = session == ReplaySession.sprint
        ? ApiConstants.sprintResults(season, round)
        : ApiConstants.raceResults(season, round);
    final data = await _client.getJson(
      path,
      query: {'limit': 100},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    final mr = _mrData(data);
    final races = (mr['RaceTable']?['Races'] as List?) ?? const [];
    if (races.isEmpty) {
      return (race: <String, dynamic>{}, results: <Map<String, dynamic>>[]);
    }
    final race = (races.first as Map).cast<String, dynamic>();
    final key = session == ReplaySession.sprint ? 'SprintResults' : 'Results';
    final rows = (race[key] as List?) ?? const [];
    return (
      race: race,
      results:
          rows.cast<Map>().map((e) => e.cast<String, dynamic>()).toList(),
    );
  }

  /// Every lap timing of a race, paginated.
  ///
  /// Jolpica caps `limit` at 100 and paginates over individual *timings*
  /// (driver × lap), so a full race needs roughly a dozen requests. Responses
  /// are cached for hours — completed races never change — so this cost is
  /// paid once per race.
  Future<List<({int lap, String driverId, int position, double? seconds})>>
      raceLaps(String season, int round) async {
    final out = <({int lap, String driverId, int position, double? seconds})>[];
    const limit = 100;
    var offset = 0;
    var total = 1 << 30;
    var pages = 0;
    while (offset < total && pages < 30) {
      final data = await _client.getJson(
        ApiConstants.raceLaps(season, round),
        query: {'limit': limit, 'offset': offset},
        cacheTtl: ApiConstants.historicalCacheTtl,
      );
      final mr = _mrData(data);
      total = Json.asInt(mr['total']) ?? out.length;
      final races = (mr['RaceTable']?['Races'] as List?) ?? const [];
      if (races.isEmpty) break;
      final laps =
          ((races.first as Map).cast<String, dynamic>()['Laps'] as List?) ?? const [];
      if (laps.isEmpty) break;
      var added = 0;
      for (final lapRaw in laps.cast<Map>()) {
        final lapMap = lapRaw.cast<String, dynamic>();
        final lapNumber = Json.asInt(lapMap['number']) ?? 0;
        final timings = (lapMap['Timings'] as List?) ?? const [];
        for (final t in timings.cast<Map>()) {
          final timing = t.cast<String, dynamic>();
          out.add((
            lap: lapNumber,
            driverId: Json.asString(timing['driverId']),
            position: Json.asInt(timing['position']) ?? 0,
            seconds: _seconds(Json.asString(timing['time'])),
          ));
          added++;
        }
      }
      offset += limit;
      pages++;
      if (added == 0) break;
    }
    return out;
  }

  /// Pit stops for a race (lap, stop number and stationary duration).
  Future<List<({String driverId, int lap, int stop, double? duration})>>
      racePitStops(String season, int round) async {
    final data = await _client.getJson(
      ApiConstants.racePitStops(season, round),
      query: {'limit': 100},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    final mr = _mrData(data);
    final races = (mr['RaceTable']?['Races'] as List?) ?? const [];
    if (races.isEmpty) return const [];
    final stops =
        ((races.first as Map).cast<String, dynamic>()['PitStops'] as List?) ?? const [];
    return stops.cast<Map>().map((e) {
      final m = e.cast<String, dynamic>();
      return (
        driverId: Json.asString(m['driverId']),
        lap: Json.asInt(m['lap']) ?? 0,
        stop: Json.asInt(m['stop']) ?? 0,
        duration: _seconds(Json.asString(m['duration'])),
      );
    }).toList();
  }

  /// Pole sitter for a race (name + Q3 time), when qualifying data exists.
  Future<({String name, String time})?> racePole(
    String season,
    int round,
  ) async {
    final data = await _client.getJson(
      ApiConstants.raceQualifying(season, round),
      query: {'limit': 100},
      cacheTtl: ApiConstants.historicalCacheTtl,
    );
    final mr = _mrData(data);
    final races = (mr['RaceTable']?['Races'] as List?) ?? const [];
    if (races.isEmpty) return null;
    final rows =
        ((races.first as Map).cast<String, dynamic>()['QualifyingResults'] as List?) ??
            const [];
    for (final r in rows.cast<Map>()) {
      final row = r.cast<String, dynamic>();
      if ((Json.asInt(row['position']) ?? 0) != 1) continue;
      final driver = (row['Driver'] as Map?)?.cast<String, dynamic>() ?? {};
      final best = Json.asString(row['Q3']).isNotEmpty
          ? Json.asString(row['Q3'])
          : Json.asString(row['Q2']).isNotEmpty
              ? Json.asString(row['Q2'])
              : Json.asString(row['Q1']);
      return (
        name:
            '${Json.asString(driver['givenName'])} ${Json.asString(driver['familyName'])}'
                .trim(),
        time: best,
      );
    }
    return null;
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
