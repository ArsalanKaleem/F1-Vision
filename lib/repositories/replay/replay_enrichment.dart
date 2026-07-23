import '../../models/replay.dart';
import '../services/openf1_service.dart';

/// Extra per-lap detail a telemetry provider can contribute.
class LapDetail {
  const LapDetail({
    this.compound,
    this.sector1,
    this.sector2,
    this.sector3,
    this.topSpeed,
  });

  final String? compound;
  final double? sector1;
  final double? sector2;
  final double? sector3;
  final double? topSpeed;
}

/// Lets a provider translate its own driver identifiers into Jolpica
/// `driverId`s without knowing how the replay was assembled.
class ReplayDriverIndex {
  const ReplayDriverIndex({required this.byNumber, required this.byCode});

  final Map<int, String> byNumber; // car number → driverId
  final Map<String, String> byCode; // 3-letter code → driverId

  String? resolve({int? number, String? code}) {
    if (number != null) {
      final hit = byNumber[number];
      if (hit != null) return hit;
    }
    if (code != null && code.isNotEmpty) {
      return byCode[code.toUpperCase()];
    }
    return null;
  }
}

/// Everything an enrichment source can add to a replay.
class ReplayEnrichment {
  const ReplayEnrichment({
    this.stintsByDriver = const {},
    this.lapDetail = const {},
    this.events = const [],
  });

  /// driverId → tyre stints, in chronological order.
  final Map<String, List<TyreStint>> stintsByDriver;

  /// driverId → lap number → extra detail.
  final Map<String, Map<int, LapDetail>> lapDetail;

  /// Session-wide events (safety cars, flags, weather changes).
  final List<RaceEvent> events;

  bool get isEmpty =>
      stintsByDriver.isEmpty && lapDetail.isEmpty && events.isEmpty;
}

/// A pluggable telemetry provider for the replay.
///
/// The repository asks each registered source, in order, for whatever it can
/// contribute; sources that have no data for an event simply return null. New
/// providers can therefore be added by implementing this interface and
/// registering it in `core_providers.dart` — no UI, model or widget changes.
abstract class ReplayEnrichmentSource {
  const ReplayEnrichmentSource();

  /// Human-readable provider name, surfaced in the UI as a data-source badge.
  String get name;

  Future<ReplayEnrichment?> enrich({
    required RaceMeta meta,
    required ReplayDriverIndex index,
    required int totalLaps,
  });
}

/// Enriches replays with OpenF1 data (2023 onwards): tyre compounds, sector
/// times, speed-trap readings, race-control messages and weather changes.
class OpenF1EnrichmentSource extends ReplayEnrichmentSource {
  const OpenF1EnrichmentSource(this._service);
  final OpenF1Service _service;

  @override
  String get name => 'OpenF1';

  @override
  Future<ReplayEnrichment?> enrich({
    required RaceMeta meta,
    required ReplayDriverIndex index,
    required int totalLaps,
  }) async {
    final date = meta.date;
    if (date == null) return null;
    // OpenF1's archive starts in 2023; skip the lookup entirely before that.
    if (date.year < 2023) return null;

    final session = await _service.sessionOnDate(
      year: date.year,
      date: date,
      sessionName: meta.session == ReplaySession.sprint ? 'Sprint' : 'Race',
    );
    if (session == null) return null;
    final key = session.sessionKey;

    // Reconcile OpenF1 car numbers with Jolpica driverIds via the entry list.
    final numberToId = <int, String>{};
    try {
      for (final d in await _service.drivers(key)) {
        final id =
            index.resolve(number: d.driverNumber, code: d.nameAcronym);
        if (id != null) numberToId[d.driverNumber] = id;
      }
    } catch (_) {
      // Entry list is optional — fall back to the number map we were given.
    }
    String? idFor(int number) => numberToId[number] ?? index.byNumber[number];

    final stintsByDriver = <String, List<TyreStint>>{};
    final lapDetail = <String, Map<int, LapDetail>>{};
    final events = <RaceEvent>[];

    // ── Tyre stints ───────────────────────────────────────────────────
    final compoundByDriverLap = <String, Map<int, String>>{};
    try {
      for (final s in await _service.sessionStints(key)) {
        final id = idFor(s.driverNumber);
        if (id == null) continue;
        final start = s.lapStart <= 0 ? 1 : s.lapStart;
        final end = s.lapEnd < start ? start : s.lapEnd;
        (stintsByDriver[id] ??= []).add(TyreStint(
          compound: s.compound,
          startLap: start,
          endLap: end > totalLaps && totalLaps > 0 ? totalLaps : end,
        ));
        final perLap = compoundByDriverLap[id] ??= {};
        for (var lap = start; lap <= end; lap++) {
          perLap[lap] = s.compound;
        }
      }
      for (final list in stintsByDriver.values) {
        list.sort((a, b) => a.startLap.compareTo(b.startLap));
      }
    } catch (_) {
      // Stint data missing — strategy panel will fall back to pit-stop laps.
    }

    // ── Lap detail (sectors + speed trap) and the lap→time index ──────
    final lapStartTimes = List<DateTime?>.filled(
      totalLaps > 0 ? totalLaps : 0,
      null,
    );
    try {
      for (final l in await _service.sessionLaps(key)) {
        final id = idFor(l.driverNumber);
        if (id == null) continue;
        final compound = compoundByDriverLap[id]?[l.lapNumber];
        (lapDetail[id] ??= {})[l.lapNumber] = LapDetail(
          compound: compound,
          sector1: l.sector1,
          sector2: l.sector2,
          sector3: l.sector3,
          topSpeed: l.topSpeed,
        );
        final started = l.startedAt;
        final idx = l.lapNumber - 1;
        if (started != null && idx >= 0 && idx < lapStartTimes.length) {
          final current = lapStartTimes[idx];
          if (current == null || started.isBefore(current)) {
            lapStartTimes[idx] = started;
          }
        }
      }
    } catch (_) {
      // Sector detail is optional.
    }

    // Fill compounds for drivers that had stints but no lap rows.
    for (final entry in compoundByDriverLap.entries) {
      final perLap = lapDetail[entry.key] ??= {};
      for (final lap in entry.value.entries) {
        perLap.putIfAbsent(lap.key, () => LapDetail(compound: lap.value));
      }
    }

    /// The last lap that had already started at [when].
    int? lapForTime(DateTime when) {
      int? best;
      for (var i = 0; i < lapStartTimes.length; i++) {
        final start = lapStartTimes[i];
        if (start != null && !start.isAfter(when)) best = i + 1;
      }
      return best;
    }

    // ── Race control: safety cars, flags, incidents ───────────────────
    try {
      final seen = <String>{};
      for (final m in await _service.sessionRaceControl(key)) {
        final message = m.message.trim();
        if (message.isEmpty) continue;
        final upper = message.toUpperCase();
        final type = _classify(category: m.category, flag: m.flag, message: upper);
        if (type == null) continue;
        final lap = (m.lap ?? 0).clamp(0, totalLaps);
        final dedupe = '$lap|${type.name}|$upper';
        if (!seen.add(dedupe)) continue;
        events.add(RaceEvent(
          lap: lap == 0 ? 1 : lap,
          type: type,
          title: type.label,
          detail: _titleCase(message),
        ));
      }
    } catch (_) {
      // Race control is optional.
    }

    // ── Weather transitions ───────────────────────────────────────────
    try {
      final samples = await _service.sessionWeatherSeries(key);
      int? lastRain;
      for (final s in samples) {
        final rain = s.rain;
        final when = s.date;
        if (rain == null || when == null) continue;
        if (lastRain != null && rain != lastRain) {
          final lap = lapForTime(when);
          events.add(RaceEvent(
            lap: (lap ?? 1).clamp(1, totalLaps == 0 ? 1 : totalLaps),
            type: RaceEventType.weather,
            title: rain > 0 ? 'Rain started' : 'Track drying',
            detail: rain > 0
                ? 'Rainfall detected at the circuit'
                : 'Rainfall stopped',
          ));
        }
        lastRain = rain;
      }
    } catch (_) {
      // Weather is optional.
    }

    final enrichment = ReplayEnrichment(
      stintsByDriver: stintsByDriver,
      lapDetail: lapDetail,
      events: events,
    );
    return enrichment.isEmpty ? null : enrichment;
  }

  static RaceEventType? _classify({
    required String category,
    required String flag,
    required String message,
  }) {
    if (message.contains('VIRTUAL SAFETY CAR') || message.contains('VSC')) {
      return RaceEventType.virtualSafetyCar;
    }
    if (message.contains('SAFETY CAR') || category == 'SafetyCar') {
      return RaceEventType.safetyCar;
    }
    final f = flag.toUpperCase();
    if (f == 'RED') return RaceEventType.redFlag;
    if (f == 'YELLOW' || f == 'DOUBLE YELLOW') return RaceEventType.yellowFlag;
    if (f == 'GREEN' || f == 'CLEAR') return RaceEventType.greenFlag;
    if (f == 'CHEQUERED') return RaceEventType.chequered;
    return null;
  }

  /// Race control shouts in caps; soften it for the feed.
  static String _titleCase(String value) {
    final lower = value.toLowerCase();
    return lower.isEmpty ? value : lower[0].toUpperCase() + lower.substring(1);
  }
}
