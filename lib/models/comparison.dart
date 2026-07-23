import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'analytics.dart';
import 'replay.dart';

/// One driver's side of a head-to-head, combining season aggregates with the
/// per-lap detail of an optionally selected race.
class ComparisonSide {
  const ComparisonSide({
    required this.driverId,
    required this.code,
    required this.name,
    required this.constructorName,
    required this.color,
    required this.season,
    this.race,
    this.laps = const [],
    this.stints = const [],
  });

  final String driverId;
  final String code;
  final String name;
  final String constructorName;
  final Color color;

  /// Season-long aggregate (championship points, wins, average pace…).
  final DriverAggregate season;

  /// Entry in the selected race, when one is loaded and the driver started it.
  final ReplayDriver? race;

  /// Per-lap rows of the selected race, ordered by lap.
  final List<LapEntry> laps;

  /// Tyre stints of the selected race.
  final List<TyreStint> stints;

  bool get hasRace => race != null && laps.isNotEmpty;

  // ── Derived race metrics ──────────────────────────────────────────────

  /// Lap times with in/out laps, safety-car laps and outliers removed, so
  /// "pace" reflects genuine racing laps.
  List<double> get cleanLapTimes {
    final raw = <double>[
      for (final l in laps)
        if (!l.inPit && l.lapSeconds != null && l.lapSeconds! > 0)
          l.lapSeconds!,
    ];
    if (raw.length < 3) return raw;
    final sorted = [...raw]..sort();
    final median = sorted[sorted.length ~/ 2];
    // 107% of the median is the usual cut-off for a representative lap.
    return raw.where((v) => v <= median * 1.07).toList();
  }

  double? get bestLap {
    double? best;
    for (final l in laps) {
      final v = l.lapSeconds;
      if (v == null || v <= 0) continue;
      if (best == null || v < best) best = v;
    }
    return best;
  }

  double? get averagePace => _mean(cleanLapTimes);

  double? get medianPace {
    final clean = cleanLapTimes;
    if (clean.isEmpty) return null;
    final sorted = [...clean]..sort();
    return sorted[sorted.length ~/ 2];
  }

  double? get bestSector1 => _min([for (final l in laps) l.sector1]);
  double? get bestSector2 => _min([for (final l in laps) l.sector2]);
  double? get bestSector3 => _min([for (final l in laps) l.sector3]);

  double? get topSpeed => _max([for (final l in laps) l.topSpeed]);
  double? get averageSpeed =>
      _mean([for (final l in laps) if (l.topSpeed != null) l.topSpeed!]);

  /// Positions gained (+) or lost (−) between the grid and the flag.
  int? get positionsGained {
    final r = race;
    if (r == null || r.grid == 0 || r.finishPosition == 0) return null;
    return r.grid - r.finishPosition;
  }

  List<({int lap, double? seconds})> get pitStops => [
        for (final l in laps)
          if (l.inPit) (lap: l.lap, seconds: l.pitSeconds),
      ];

  int get pitCount => pitStops.length;

  double? get totalPitTime {
    final values = [
      for (final p in pitStops)
        if (p.seconds != null) p.seconds!,
    ];
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b);
  }

  double? get averagePitTime {
    final values = [
      for (final p in pitStops)
        if (p.seconds != null) p.seconds!,
    ];
    return _mean(values);
  }

  static double? _mean(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double? _min(List<double?> values) {
    double? out;
    for (final v in values) {
      if (v == null || v <= 0) continue;
      if (out == null || v < out) out = v;
    }
    return out;
  }

  static double? _max(List<double?> values) {
    double? out;
    for (final v in values) {
      if (v == null || v <= 0) continue;
      if (out == null || v > out) out = v;
    }
    return out;
  }
}

/// A single comparable metric, already resolved for both drivers.
///
/// [lowerIsBetter] lets the UI colour the winning side without each panel
/// re-deciding the semantics of the metric.
class ComparisonMetric {
  const ComparisonMetric({
    required this.label,
    required this.a,
    required this.b,
    required this.format,
    this.lowerIsBetter = false,
    this.unit = '',
  });

  final String label;
  final double? a;
  final double? b;
  final String Function(double value) format;
  final bool lowerIsBetter;
  final String unit;

  bool get hasBoth => a != null && b != null;

  /// -1 → A is better, 1 → B is better, 0 → tie or incomparable.
  int get winner {
    if (!hasBoth || a == b) return 0;
    final aBetter = lowerIsBetter ? a! < b! : a! > b!;
    return aBetter ? -1 : 1;
  }

  String display(double? value) => value == null ? '—' : format(value);

  /// Fraction of the larger value, used for the paired bar rows.
  double fraction(double? value) {
    if (value == null) return 0;
    final peak = math.max(a ?? 0, b ?? 0);
    if (peak <= 0) return 0;
    return (value / peak).clamp(0.0, 1.0).toDouble();
  }
}

/// The assembled head-to-head. Built by [DriverComparison.build] from data the
/// Analytics and Replay providers already fetched, so selecting drivers never
/// triggers another network round-trip.
class DriverComparison {
  const DriverComparison({
    required this.season,
    required this.a,
    required this.b,
    required this.roundLabels,
    this.raceMeta,
    this.totalLaps = 0,
    this.hasTelemetry = false,
  });

  final String season;
  final ComparisonSide a;
  final ComparisonSide b;
  final List<String> roundLabels;
  final RaceMeta? raceMeta;
  final int totalLaps;
  final bool hasTelemetry;

  bool get hasRace => a.hasRace || b.hasRace;

  /// Both drivers actually ran the selected race — required before showing
  /// head-to-head race panels.
  bool get bothInRace => a.hasRace && b.hasRace;

  /// Season-level metrics available for every era of the sport.
  List<ComparisonMetric> get seasonMetrics => [
        ComparisonMetric(
          label: 'Championship points',
          a: a.season.points,
          b: b.season.points,
          format: _points,
        ),
        ComparisonMetric(
          label: 'Wins',
          a: a.season.wins.toDouble(),
          b: b.season.wins.toDouble(),
          format: _whole,
        ),
        ComparisonMetric(
          label: 'Podiums',
          a: a.season.podiums.toDouble(),
          b: b.season.podiums.toDouble(),
          format: _whole,
        ),
        ComparisonMetric(
          label: 'Pole positions',
          a: a.season.poles.toDouble(),
          b: b.season.poles.toDouble(),
          format: _whole,
        ),
        ComparisonMetric(
          label: 'Fastest laps',
          a: a.season.fastestLaps.toDouble(),
          b: b.season.fastestLaps.toDouble(),
          format: _whole,
        ),
        ComparisonMetric(
          label: 'Average finish',
          a: a.season.avgFinish > 0 ? a.season.avgFinish : null,
          b: b.season.avgFinish > 0 ? b.season.avgFinish : null,
          format: (v) => 'P${v.toStringAsFixed(1)}',
          lowerIsBetter: true,
        ),
        ComparisonMetric(
          label: 'DNFs',
          a: a.season.dnfs.toDouble(),
          b: b.season.dnfs.toDouble(),
          format: _whole,
          lowerIsBetter: true,
        ),
        ComparisonMetric(
          label: 'Avg race pace',
          a: a.season.avgPaceKmh > 0 ? a.season.avgPaceKmh : null,
          b: b.season.avgPaceKmh > 0 ? b.season.avgPaceKmh : null,
          format: (v) => '${v.toStringAsFixed(1)} km/h',
        ),
      ];

  /// Race-level metrics; empty when no race is loaded.
  List<ComparisonMetric> get raceMetrics {
    if (!bothInRace) return const [];
    return [
      ComparisonMetric(
        label: 'Best lap',
        a: a.bestLap,
        b: b.bestLap,
        format: _lap,
        lowerIsBetter: true,
      ),
      ComparisonMetric(
        label: 'Average pace',
        a: a.averagePace,
        b: b.averagePace,
        format: _lap,
        lowerIsBetter: true,
      ),
      ComparisonMetric(
        label: 'Median pace',
        a: a.medianPace,
        b: b.medianPace,
        format: _lap,
        lowerIsBetter: true,
      ),
      ComparisonMetric(
        label: 'Top speed',
        a: a.topSpeed,
        b: b.topSpeed,
        format: (v) => '${v.toStringAsFixed(0)} km/h',
      ),
      ComparisonMetric(
        label: 'Pit stops',
        a: a.pitCount.toDouble(),
        b: b.pitCount.toDouble(),
        format: _whole,
        lowerIsBetter: true,
      ),
      ComparisonMetric(
        label: 'Total pit time',
        a: a.totalPitTime,
        b: b.totalPitTime,
        format: (v) => '${v.toStringAsFixed(1)}s',
        lowerIsBetter: true,
      ),
    ];
  }

  /// Six normalised axes (0–100) for the radar, where 100 is the better of the
  /// two drivers on that axis.
  ({List<String> axes, List<double> a, List<double> b}) get radarVectors {
    const axes = [
      'Points',
      'Wins',
      'Podiums',
      'Poles',
      'Fast Laps',
      'Finish',
    ];
    double finishScore(DriverAggregate d) =>
        d.avgFinish > 0 ? 1 / d.avgFinish : 0;

    final rawA = <double>[
      a.season.points,
      a.season.wins.toDouble(),
      a.season.podiums.toDouble(),
      a.season.poles.toDouble(),
      a.season.fastestLaps.toDouble(),
      finishScore(a.season),
    ];
    final rawB = <double>[
      b.season.points,
      b.season.wins.toDouble(),
      b.season.podiums.toDouble(),
      b.season.poles.toDouble(),
      b.season.fastestLaps.toDouble(),
      finishScore(b.season),
    ];

    final normA = <double>[];
    final normB = <double>[];
    for (var i = 0; i < axes.length; i++) {
      final peak = math.max(rawA[i], rawB[i]);
      normA.add(peak > 0 ? rawA[i] / peak * 100 : 0);
      normB.add(peak > 0 ? rawB[i] / peak * 100 : 0);
    }
    return (axes: axes, a: normA, b: normB);
  }

  static String _whole(double v) => v.toStringAsFixed(0);
  static String _points(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  static String _lap(double v) {
    final m = v ~/ 60;
    final s = v % 60;
    if (m == 0) return s.toStringAsFixed(3);
    return '$m:${s.toStringAsFixed(3).padLeft(6, '0')}';
  }

  /// Composes a comparison from data the providers already hold.
  ///
  /// Returns null when either driver is missing from the season aggregate,
  /// which is the only genuinely un-comparable case.
  static DriverComparison? build({
    required SeasonAnalytics analytics,
    required String driverA,
    required String driverB,
    RaceReplay? replay,
  }) {
    DriverAggregate? findSeason(String id) {
      for (final d in analytics.drivers) {
        if (d.driverId == id) return d;
      }
      return null;
    }

    final seasonA = findSeason(driverA);
    final seasonB = findSeason(driverB);
    if (seasonA == null || seasonB == null) return null;

    ComparisonSide side(DriverAggregate agg) {
      final entry = replay?.driver(agg.driverId);
      final laps = replay?.byDriver[agg.driverId] ?? const <LapEntry>[];
      return ComparisonSide(
        driverId: agg.driverId,
        code: agg.shortName,
        name: agg.name,
        constructorName: agg.constructorName,
        color: agg.color,
        season: agg,
        race: entry,
        laps: [...laps]..sort((x, y) => x.lap.compareTo(y.lap)),
        stints: entry?.stints ?? const <TyreStint>[],
      );
    }

    return DriverComparison(
      season: analytics.season,
      a: side(seasonA),
      b: side(seasonB),
      roundLabels: analytics.roundLabels,
      raceMeta: replay?.meta,
      totalLaps: replay?.totalLaps ?? 0,
      hasTelemetry: replay?.hasTelemetry ?? false,
    );
  }
}
