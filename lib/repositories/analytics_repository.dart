import '../core/errors/failures.dart';
import '../core/network/result.dart';
import '../models/analytics.dart';
import '../models/standings.dart';
import 'services/jolpica_service.dart';

/// Builds the season-wide analytics payload from several Jolpica feeds. All the
/// heavy aggregation happens here (pure Dart), so the UI just renders immutable
/// [SeasonAnalytics] and the providers stay thin.
class AnalyticsRepository {
  AnalyticsRepository(this._jolpica);
  final JolpicaService _jolpica;

  Future<Result<SeasonAnalytics>> season(String season) async {
    return _guard(() async {
      // Fetched sequentially to stay within Jolpica's rate limits; the Dio
      // layer caches each response so revisiting a season is instant.
      final results = await _jolpica.seasonResults(season);
      final driverStandings = await _jolpica.driverStandings(season);
      final constructorStandings = await _jolpica.constructorStandings(season);
      final poles = await _jolpica.polePositions(season);
      final status = await _jolpica.seasonStatus(season);
      final pit = await _safePit(season);

      return _aggregate(
        season: season,
        results: results,
        driverStandings: driverStandings,
        constructorStandings: constructorStandings,
        poles: poles,
        status: status,
        pit: pit,
      );
    });
  }

  Future<PitAnalytics?> _safePit(String season) async {
    try {
      return await _jolpica.lastRacePitStops(season);
    } catch (_) {
      return null; // pit data is a nice-to-have; never fail the whole screen.
    }
  }

  SeasonAnalytics _aggregate({
    required String season,
    required List<RaceResultRow> results,
    required List<DriverStanding> driverStandings,
    required List<ConstructorStanding> constructorStandings,
    required Map<String, int> poles,
    required List<StatusSlice> status,
    required PitAnalytics? pit,
  }) {
    final rounds = results.map((r) => r.round).toSet().toList()..sort();
    final roundIndex = {for (var i = 0; i < rounds.length; i++) rounds[i]: i};
    final roundLabels = [for (final r in rounds) 'R$r'];
    final raceNames = List<String>.filled(rounds.length, '');
    for (final r in results) {
      final idx = roundIndex[r.round];
      if (idx != null && raceNames[idx].isEmpty) raceNames[idx] = r.raceName;
    }

    List<double> cumulative(List<RaceResultRow> rows) {
      final perRound = List<double>.filled(rounds.length, 0);
      for (final row in rows) {
        final idx = roundIndex[row.round];
        if (idx != null) perRound[idx] += row.points;
      }
      final out = <double>[];
      var run = 0.0;
      for (final p in perRound) {
        run += p;
        out.add(run);
      }
      return out;
    }

    // Group results.
    final byDriver = <String, List<RaceResultRow>>{};
    final byConstructor = <String, List<RaceResultRow>>{};
    for (final r in results) {
      (byDriver[r.driverId] ??= []).add(r);
      (byConstructor[r.constructorId] ??= []).add(r);
    }

    final drivers = <DriverAggregate>[];
    for (final s in driverStandings) {
      final rows = byDriver[s.driverId] ?? const <RaceResultRow>[];
      final ordered = [...rows]..sort((a, b) => a.round.compareTo(b.round));
      final finishes =
          ordered.where((r) => r.position > 0).map((r) => r.position).toList();
      final speeds =
          ordered.map((r) => r.fastestLapSpeed).whereType<double>().toList();
      final last5 = ordered.length <= 5
          ? ordered.map((r) => r.position).toList()
          : ordered
              .sublist(ordered.length - 5)
              .map((r) => r.position)
              .toList();

      drivers.add(DriverAggregate(
        driverId: s.driverId,
        code: ordered.isNotEmpty && ordered.last.driverCode.isNotEmpty
            ? ordered.last.driverCode
            : _codeFrom(s.familyName),
        name: s.fullName,
        constructorId:
            ordered.isNotEmpty ? ordered.last.constructorId : '',
        constructorName:
            ordered.isNotEmpty ? ordered.last.constructorName : s.constructorName,
        championshipPosition: s.position,
        points: s.points,
        wins: s.wins,
        podiums: ordered.where((r) => r.podium).length,
        poles: poles[s.driverId] ?? 0,
        fastestLaps: ordered.where((r) => r.setFastestLap).length,
        dnfs: ordered.where((r) => r.dnf).length,
        avgFinish: _avg(finishes.map((e) => e.toDouble())),
        avgPaceKmh: _avg(speeds),
        last5: last5,
        cumulativePoints: cumulative(ordered),
      ));
    }

    final constructors = <ConstructorAggregate>[];
    for (final c in constructorStandings) {
      final rows = byConstructor[c.constructorId] ?? const <RaceResultRow>[];
      final speeds =
          rows.map((r) => r.fastestLapSpeed).whereType<double>().toList();
      constructors.add(ConstructorAggregate(
        constructorId: c.constructorId,
        name: c.name,
        championshipPosition: c.position,
        points: c.points,
        wins: c.wins,
        podiums: rows.where((r) => r.podium).length,
        avgPaceKmh: _avg(speeds),
        cumulativePoints: cumulative(rows),
      ));
    }

    // Accurate finish/retirement totals must be taken from the FULL status
    // table: the display slices below fold the long tail into "Other", which
    // would otherwise mis-count lapped finishers ("+2 Laps", "+3 Laps", …)
    // as retirements.
    var statusTotal = 0;
    var classifiedCount = 0;
    for (final s in status) {
      statusTotal += s.count;
      if (s.label == 'Finished' || s.label.startsWith('+')) {
        classifiedCount += s.count;
      }
    }

    // Status breakdown: keep the six largest, fold the rest into "Other".
    final sortedStatus = [...status]..sort((a, b) => b.count.compareTo(a.count));
    final slices = <StatusSlice>[];
    var other = 0;
    for (var i = 0; i < sortedStatus.length; i++) {
      if (i < 6) {
        slices.add(sortedStatus[i]);
      } else {
        other += sortedStatus[i].count;
      }
    }
    if (other > 0) slices.add(StatusSlice(label: 'Other', count: other));

    return SeasonAnalytics(
      season: season,
      roundLabels: roundLabels,
      raceNames: raceNames,
      totalRounds: rounds.length,
      drivers: drivers,
      constructors: constructors,
      statusSlices: slices,
      classifiedCount: classifiedCount,
      statusTotal: statusTotal,
      pit: pit,
      generatedAt: DateTime.now(),
    );
  }

  static String _codeFrom(String familyName) => familyName.isEmpty
      ? '—'
      : familyName.substring(0, familyName.length >= 3 ? 3 : familyName.length)
          .toUpperCase();

  static double _avg(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
