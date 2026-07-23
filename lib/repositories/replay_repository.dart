import '../core/errors/failures.dart';
import '../core/network/result.dart';
import '../core/utils/json.dart';
import '../models/replay.dart';
import 'replay/replay_enrichment.dart';
import 'services/jolpica_service.dart';

/// Builds a complete lap-by-lap [RaceReplay].
///
/// Jolpica supplies the backbone (entry list, classification, lap timings and
/// pit stops) for every race since 1996. Optional [ReplayEnrichmentSource]s
/// layer on tyre compounds, sector times, speed traps and race-control events
/// where they have coverage. Adding a provider means registering another
/// source — the models and UI never change.
class ReplayRepository {
  ReplayRepository(this._jolpica, this._sources);

  final JolpicaService _jolpica;
  final List<ReplayEnrichmentSource> _sources;

  /// The season calendar, newest first, restricted to completed events.
  Future<Result<List<RaceListing>>> schedule(String season) =>
      _guard(() async {
        final races = await _jolpica.seasonSchedule(season);
        return races.where((r) => r.isCompleted).toList();
      });

  Future<Result<RaceReplay>> replay({
    required String season,
    required int round,
    required ReplaySession session,
  }) =>
      _guard(() async {
        final classification =
            await _jolpica.raceResults(season, round, session: session);
        final race = classification.race;
        final results = classification.results;
        if (results.isEmpty) {
          throw const ServerException(
            'No classification is published for this event yet.',
          );
        }

        final timings = await _jolpica.raceLaps(season, round);
        final pitStops = await _jolpica.racePitStops(season, round);

        return _assemble(
          season: season,
          round: round,
          session: session,
          race: race,
          results: results,
          timings: timings,
          pitStops: pitStops,
        );
      });

  Future<RaceReplay> _assemble({
    required String season,
    required int round,
    required ReplaySession session,
    required Map<String, dynamic> race,
    required List<Map<String, dynamic>> results,
    required List<({int lap, String driverId, int position, double? seconds})>
        timings,
    required List<({String driverId, int lap, int stop, double? duration})>
        pitStops,
  }) async {
    // ── Entry list & classification ─────────────────────────────────────
    final circuit = (race['Circuit'] as Map?)?.cast<String, dynamic>() ?? {};
    final location =
        (circuit['Location'] as Map?)?.cast<String, dynamic>() ?? {};

    final numbers = <int, String>{};
    final codes = <String, String>{};
    final entries = <_Entry>[];
    var fastestDriver = '';
    var fastestTime = '';
    int? fastestLapNumber;

    for (final row in results) {
      final driver = (row['Driver'] as Map?)?.cast<String, dynamic>() ?? {};
      final constructor =
          (row['Constructor'] as Map?)?.cast<String, dynamic>() ?? {};
      final driverId = Json.asString(driver['driverId']);
      if (driverId.isEmpty) continue;

      final code = Json.asString(driver['code']).toUpperCase();
      final number = Json.asInt(driver['permanentNumber']) ??
          Json.asInt(row['number']);
      if (number != null) numbers[number] = driverId;
      if (code.isNotEmpty) codes[code] = driverId;

      entries.add(_Entry(
        driverId: driverId,
        code: code,
        name:
            '${Json.asString(driver['givenName'])} ${Json.asString(driver['familyName'])}'
                .trim(),
        constructorId: Json.asString(constructor['constructorId']),
        constructorName: Json.asString(constructor['name']),
        grid: Json.asInt(row['grid']) ?? 0,
        position: Json.asInt(row['position']) ?? 0,
        status: Json.asString(row['status'], 'Unknown'),
        number: number,
      ));

      final fl = (row['FastestLap'] as Map?)?.cast<String, dynamic>();
      if (fl != null && Json.asString(fl['rank']) == '1') {
        fastestDriver =
            '${Json.asString(driver['givenName'])} ${Json.asString(driver['familyName'])}'
                .trim();
        final time = (fl['Time'] as Map?)?.cast<String, dynamic>();
        fastestTime = Json.asString(time?['time']);
        fastestLapNumber = Json.asInt(fl['lap']);
      }
    }
    entries.sort((a, b) {
      // Classified runners first (position 1..n), retirements last.
      final ap = a.position == 0 ? 999 : a.position;
      final bp = b.position == 0 ? 999 : b.position;
      return ap.compareTo(bp);
    });

    final winner = entries.isNotEmpty ? entries.first : null;

    // Pole: prefer the qualifying feed, else the driver who started P1.
    var poleName = '';
    var poleTime = '';
    if (session == ReplaySession.race) {
      try {
        final pole = await _jolpica.racePole(season, round);
        if (pole != null) {
          poleName = pole.name;
          poleTime = pole.time;
        }
      } catch (_) {
        // Qualifying data is optional (and absent for some historic events).
      }
    }
    if (poleName.isEmpty) {
      for (final e in entries) {
        if (e.grid == 1) {
          poleName = e.name;
          break;
        }
      }
    }

    final meta = RaceMeta(
      season: season,
      round: round,
      raceName: Json.asString(race['raceName']),
      circuitName: Json.asString(circuit['circuitName']),
      locality: Json.asString(location['locality']),
      country: Json.asString(location['country']),
      session: session,
      date: Json.asDate(race['date']),
      winner: winner?.name ?? '',
      winnerConstructorId: winner?.constructorId ?? '',
      pole: poleName,
      poleTime: poleTime,
      fastestLapDriver: fastestDriver,
      fastestLapTime: fastestTime,
      fastestLapNumber: fastestLapNumber,
    );

    // ── Lap grid ────────────────────────────────────────────────────────
    var totalLaps = 0;
    for (final t in timings) {
      if (t.lap > totalLaps) totalLaps = t.lap;
    }
    if (totalLaps == 0) {
      // Lap-by-lap timing isn't published for this event (pre-1996, or a
      // sprint without lap data). Return an empty replay; the UI explains.
      return RaceReplay(
        meta: meta,
        drivers: const [],
        laps: const [],
        byDriver: const {},
        events: const [],
        totalLaps: 0,
        hasTelemetry: false,
        generatedAt: DateTime.now(),
      );
    }

    final pitByDriverLap = <String, Map<int, ({int stop, double? duration})>>{};
    for (final p in pitStops) {
      (pitByDriverLap[p.driverId] ??= {})[p.lap] =
          (stop: p.stop, duration: p.duration);
    }

    // Group timings by lap, then build cumulative race time per driver.
    final byLap = <int, List<({String driverId, int position, double? seconds})>>{};
    for (final t in timings) {
      (byLap[t.lap] ??= []).add(
        (driverId: t.driverId, position: t.position, seconds: t.seconds),
      );
    }

    final cumulative = <String, double>{};
    final lastSeen = <String, double>{};
    final laps = <LapSnapshot>[];
    final byDriver = <String, List<LapEntry>>{};

    for (var lap = 1; lap <= totalLaps; lap++) {
      final rows = byLap[lap];
      if (rows == null || rows.isEmpty) continue;
      rows.sort((a, b) => a.position.compareTo(b.position));

      // Advance every runner's cumulative time first so gaps are consistent.
      for (final row in rows) {
        final seconds = row.seconds ?? lastSeen[row.driverId];
        if (seconds != null) {
          cumulative[row.driverId] = (cumulative[row.driverId] ?? 0) + seconds;
          lastSeen[row.driverId] = seconds;
        }
      }
      final leaderId = rows.first.driverId;
      final leaderTime = cumulative[leaderId] ?? 0;

      final entriesForLap = <LapEntry>[];
      for (final row in rows) {
        final pit = pitByDriverLap[row.driverId]?[lap];
        final entry = LapEntry(
          driverId: row.driverId,
          lap: lap,
          position: row.position,
          cumulativeSeconds: cumulative[row.driverId] ?? 0,
          gapToLeader: (cumulative[row.driverId] ?? 0) - leaderTime,
          lapSeconds: row.seconds,
          inPit: pit != null,
          pitStop: pit?.stop,
          pitSeconds: pit?.duration,
        );
        entriesForLap.add(entry);
        (byDriver[row.driverId] ??= []).add(entry);
      }
      laps.add(LapSnapshot(lap: lap, entries: entriesForLap));
    }

    // ── Optional provider enrichment ────────────────────────────────────
    final index = ReplayDriverIndex(byNumber: numbers, byCode: codes);
    ReplayEnrichment? enrichment;
    for (final source in _sources) {
      try {
        final result = await source.enrich(
          meta: meta,
          index: index,
          totalLaps: totalLaps,
        );
        if (result != null && !result.isEmpty) {
          enrichment = result;
          break;
        }
      } catch (_) {
        // A failing provider must never break the replay.
      }
    }

    if (enrichment != null) {
      final detail = enrichment.lapDetail;
      for (final driverId in byDriver.keys) {
        final perLap = detail[driverId];
        if (perLap == null) continue;
        final list = byDriver[driverId]!;
        for (var i = 0; i < list.length; i++) {
          final extra = perLap[list[i].lap];
          if (extra == null) continue;
          list[i] = list[i].copyWith(
            compound: extra.compound,
            sector1: extra.sector1,
            sector2: extra.sector2,
            sector3: extra.sector3,
            topSpeed: extra.topSpeed,
          );
        }
      }
      // Rebuild snapshots so the leaderboard sees the enriched entries.
      for (var i = 0; i < laps.length; i++) {
        final snapshot = laps[i];
        final rebuilt = <LapEntry>[];
        for (final e in snapshot.entries) {
          final extra = detail[e.driverId]?[e.lap];
          rebuilt.add(extra == null
              ? e
              : e.copyWith(
                  compound: extra.compound,
                  sector1: extra.sector1,
                  sector2: extra.sector2,
                  sector3: extra.sector3,
                  topSpeed: extra.topSpeed,
                ));
        }
        laps[i] = LapSnapshot(lap: snapshot.lap, entries: rebuilt);
      }
    }

    int? positionAt(String driverId, int lap) {
      final list = byDriver[driverId];
      if (list == null) return null;
      for (final e in list) {
        if (e.lap == lap) return e.position;
      }
      return null;
    }

    // ── Drivers with tyre strategy ──────────────────────────────────────
    final drivers = <ReplayDriver>[];
    for (final e in entries) {
      final providerStints = enrichment?.stintsByDriver[e.driverId];
      final stints = _withPitContext(
        providerStints ??
            _stintsFromPitStops(
              stops: pitByDriverLap[e.driverId] ?? const {},
              lastLap: byDriver[e.driverId]?.isNotEmpty == true
                  ? byDriver[e.driverId]!.last.lap
                  : totalLaps,
            ),
        driverId: e.driverId,
        positionAt: positionAt,
      );

      drivers.add(ReplayDriver(
        driverId: e.driverId,
        code: e.code,
        name: e.name,
        constructorId: e.constructorId,
        constructorName: e.constructorName,
        grid: e.grid,
        finishPosition: e.position,
        status: e.status,
        stints: stints,
        driverNumber: e.number,
      ));
    }

    final events = _buildEvents(
      meta: meta,
      drivers: drivers,
      laps: laps,
      byDriver: byDriver,
      pitStops: pitStops,
      totalLaps: totalLaps,
      providerEvents: enrichment?.events ?? const [],
    );

    return RaceReplay(
      meta: meta,
      drivers: drivers,
      laps: laps,
      byDriver: byDriver,
      events: events,
      totalLaps: totalLaps,
      hasTelemetry: enrichment != null,
      generatedAt: DateTime.now(),
    );
  }

  /// Derives stint windows purely from pit-stop laps (compound unknown).
  static List<TyreStint> _stintsFromPitStops({
    required Map<int, ({int stop, double? duration})> stops,
    required int lastLap,
  }) {
    final pitLaps = stops.keys.toList()..sort();
    final out = <TyreStint>[];
    var start = 1;
    for (final lap in pitLaps) {
      out.add(TyreStint(
        compound: 'UNKNOWN',
        startLap: start,
        endLap: lap < start ? start : lap,
      ));
      start = lap + 1;
    }
    if (start <= lastLap) {
      out.add(TyreStint(
        compound: 'UNKNOWN',
        startLap: start,
        endLap: lastLap,
      ));
    }
    return out;
  }

  /// Annotates each stint with the positions either side of the stop that
  /// started it, so the strategy panel can show places gained or lost.
  static List<TyreStint> _withPitContext(
    List<TyreStint> stints, {
    required String driverId,
    required int? Function(String, int) positionAt,
  }) {
    final out = <TyreStint>[];
    for (var i = 0; i < stints.length; i++) {
      final s = stints[i];
      if (i == 0) {
        out.add(s);
        continue;
      }
      final pitLap = s.startLap - 1;
      final before =
          positionAt(driverId, pitLap - 1) ?? positionAt(driverId, pitLap);
      final after =
          positionAt(driverId, s.startLap + 1) ?? positionAt(driverId, s.startLap);
      out.add(TyreStint(
        compound: s.compound,
        startLap: s.startLap,
        endLap: s.endLap,
        positionBefore: before,
        positionAfter: after,
      ));
    }
    return out;
  }

  /// Builds the merged, chronological event list that drives both the
  /// timeline and the race feed.
  static List<RaceEvent> _buildEvents({
    required RaceMeta meta,
    required List<ReplayDriver> drivers,
    required List<LapSnapshot> laps,
    required Map<String, List<LapEntry>> byDriver,
    required List<({String driverId, int lap, int stop, double? duration})>
        pitStops,
    required int totalLaps,
    required List<RaceEvent> providerEvents,
  }) {
    final byId = {for (final d in drivers) d.driverId: d};
    final events = <RaceEvent>[
      RaceEvent(
        lap: 1,
        type: RaceEventType.lights,
        title: 'Lights out',
        detail: '${meta.raceName} · ${drivers.length} starters',
      ),
      ...providerEvents,
    ];

    // Pit stops.
    for (final p in pitStops) {
      final d = byId[p.driverId];
      if (d == null) continue;
      final duration = p.duration;
      events.add(RaceEvent(
        lap: p.lap.clamp(1, totalLaps),
        type: RaceEventType.pitStop,
        title: '${d.shortName} pits',
        detail: duration != null
            ? 'Stop ${p.stop} · ${duration.toStringAsFixed(1)}s stationary'
            : 'Stop ${p.stop}',
        driverId: d.driverId,
        driverColor: d.color,
      ));
    }

    final pitLaps = <String, Set<int>>{};
    for (final p in pitStops) {
      (pitLaps[p.driverId] ??= {}).add(p.lap);
    }
    bool pitted(String driverId, int lap) =>
        pitLaps[driverId]?.contains(lap) ?? false;

    // Overtakes: position swaps between consecutive laps, ignoring anything
    // within a lap of a pit stop (those are strategy, not wheel-to-wheel).
    for (var i = 1; i < laps.length; i++) {
      final prev = {
        for (final e in laps[i - 1].entries) e.driverId: e.position,
      };
      final current = laps[i];
      var emitted = 0;
      for (final e in current.entries) {
        if (emitted >= 4) break;
        final was = prev[e.driverId];
        if (was == null || e.position >= was) continue;
        if (pitted(e.driverId, current.lap) ||
            pitted(e.driverId, current.lap - 1)) {
          continue;
        }
        String? victimId;
        var victimPosition = 1 << 30;
        for (final other in current.entries) {
          if (other.driverId == e.driverId) continue;
          final otherWas = prev[other.driverId];
          if (otherWas == null) continue;
          final passed = otherWas < was && other.position > e.position;
          if (!passed) continue;
          if (pitted(other.driverId, current.lap) ||
              pitted(other.driverId, current.lap - 1)) {
            continue;
          }
          if (other.position < victimPosition) {
            victimPosition = other.position;
            victimId = other.driverId;
          }
        }
        if (victimId == null) continue;
        final driver = byId[e.driverId];
        final victim = byId[victimId];
        if (driver == null || victim == null) continue;
        events.add(RaceEvent(
          lap: current.lap,
          type: RaceEventType.overtake,
          title: '${driver.shortName} passes ${victim.shortName}',
          detail: 'For P${e.position}',
          driverId: driver.driverId,
          driverColor: driver.color,
        ));
        emitted++;
      }
    }

    // Fastest lap: the overall best, plus each time it changed hands.
    ({String driverId, int lap, double seconds})? best;
    for (final snapshot in laps) {
      for (final e in snapshot.entries) {
        final seconds = e.lapSeconds;
        if (seconds == null || seconds <= 0) continue;
        if (best == null || seconds < best.seconds) {
          final previousHolder = best?.driverId;
          best = (driverId: e.driverId, lap: e.lap, seconds: seconds);
          // Skip the opening laps, when the "record" changes on every car.
          if (snapshot.lap > 3 && previousHolder != e.driverId) {
            final d = byId[e.driverId];
            if (d != null) {
              events.add(RaceEvent(
                lap: snapshot.lap,
                type: RaceEventType.fastestLap,
                title: '${d.shortName} takes fastest lap',
                detail: _formatLapTime(seconds),
                driverId: d.driverId,
                driverColor: d.color,
              ));
            }
          }
        }
      }
    }

    // Retirements.
    for (final d in drivers) {
      if (d.finished) continue;
      final list = byDriver[d.driverId];
      final lap = list != null && list.isNotEmpty ? list.last.lap : 1;
      events.add(RaceEvent(
        lap: lap.clamp(1, totalLaps),
        type: RaceEventType.retirement,
        title: '${d.shortName} out',
        detail: d.status,
        driverId: d.driverId,
        driverColor: d.color,
      ));
    }

    if (drivers.isNotEmpty) {
      events.add(RaceEvent(
        lap: totalLaps,
        type: RaceEventType.chequered,
        title: 'Chequered flag',
        detail: '${drivers.first.name} wins ${meta.raceName}',
        driverId: drivers.first.driverId,
        driverColor: drivers.first.color,
      ));
    }

    events.sort((a, b) {
      final byLap = a.lap.compareTo(b.lap);
      if (byLap != 0) return byLap;
      return a.type.index.compareTo(b.type.index);
    });
    return events;
  }

  static String _formatLapTime(double seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds - minutes * 60;
    if (minutes == 0) return '${rest.toStringAsFixed(3)}s';
    return '$minutes:${rest.toStringAsFixed(3).padLeft(6, '0')}';
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}

/// Internal projection of one classification row.
class _Entry {
  const _Entry({
    required this.driverId,
    required this.code,
    required this.name,
    required this.constructorId,
    required this.constructorName,
    required this.grid,
    required this.position,
    required this.status,
    this.number,
  });

  final String driverId;
  final String code;
  final String name;
  final String constructorId;
  final String constructorName;
  final int grid;
  final int position;
  final String status;
  final int? number;
}
