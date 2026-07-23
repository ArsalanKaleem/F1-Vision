import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/team_palette.dart';

/// Which session of a Grand Prix weekend is being replayed.
enum ReplaySession {
  race('Race', 'RACE'),
  sprint('Sprint', 'SPRINT');

  const ReplaySession(this.label, this.code);
  final String label;
  final String code;
}

/// A selectable Grand Prix in the race picker (from the season schedule).
class RaceListing {
  const RaceListing({
    required this.season,
    required this.round,
    required this.raceName,
    required this.circuitName,
    required this.locality,
    required this.country,
    required this.date,
    required this.hasSprint,
  });

  final String season;
  final int round;
  final String raceName;
  final String circuitName;
  final String locality;
  final String country;
  final DateTime? date;
  final bool hasSprint;

  String get shortName {
    final trimmed = raceName.replaceAll('Grand Prix', '').trim();
    return trimmed.isEmpty ? raceName : trimmed;
  }

  /// True once the race has actually happened (only past races are replayable).
  bool get isCompleted {
    final d = date;
    if (d == null) return false;
    return d.isBefore(DateTime.now());
  }
}

/// Headline facts shown above the replay (circuit, date, winner, pole, FL).
class RaceMeta {
  const RaceMeta({
    required this.season,
    required this.round,
    required this.raceName,
    required this.circuitName,
    required this.locality,
    required this.country,
    required this.session,
    this.date,
    this.winner = '',
    this.winnerConstructorId = '',
    this.pole = '',
    this.poleTime = '',
    this.fastestLapDriver = '',
    this.fastestLapTime = '',
    this.fastestLapNumber,
  });

  final String season;
  final int round;
  final String raceName;
  final String circuitName;
  final String locality;
  final String country;
  final ReplaySession session;
  final DateTime? date;
  final String winner;
  final String winnerConstructorId;
  final String pole;
  final String poleTime;
  final String fastestLapDriver;
  final String fastestLapTime;
  final int? fastestLapNumber;

  String get location => [locality, country]
      .where((e) => e.isNotEmpty)
      .join(', ');
}

/// One driver's state on one lap. Positions come from Jolpica lap timings;
/// sector times, tyre compound and speeds are filled in by an enrichment
/// source when one is available for that season.
class LapEntry {
  const LapEntry({
    required this.driverId,
    required this.lap,
    required this.position,
    required this.cumulativeSeconds,
    required this.gapToLeader,
    this.lapSeconds,
    this.inPit = false,
    this.pitStop,
    this.pitSeconds,
    this.compound,
    this.sector1,
    this.sector2,
    this.sector3,
    this.topSpeed,
  });

  final String driverId;
  final int lap;
  final int position;
  final double cumulativeSeconds;
  final double gapToLeader;
  final double? lapSeconds;
  final bool inPit;
  final int? pitStop;

  /// Stationary time of the stop made on this lap, when published.
  final double? pitSeconds;
  final String? compound;
  final double? sector1;
  final double? sector2;
  final double? sector3;
  final double? topSpeed;

  LapEntry copyWith({
    String? compound,
    double? sector1,
    double? sector2,
    double? sector3,
    double? topSpeed,
  }) =>
      LapEntry(
        driverId: driverId,
        lap: lap,
        position: position,
        cumulativeSeconds: cumulativeSeconds,
        gapToLeader: gapToLeader,
        lapSeconds: lapSeconds,
        inPit: inPit,
        pitStop: pitStop,
        pitSeconds: pitSeconds,
        compound: compound ?? this.compound,
        sector1: sector1 ?? this.sector1,
        sector2: sector2 ?? this.sector2,
        sector3: sector3 ?? this.sector3,
        topSpeed: topSpeed ?? this.topSpeed,
      );
}

/// The full classification at the end of a given lap, ordered by position.
class LapSnapshot {
  const LapSnapshot({required this.lap, required this.entries});
  final int lap;
  final List<LapEntry> entries;
}

/// A single tyre stint between two pit stops.
class TyreStint {
  const TyreStint({
    required this.compound,
    required this.startLap,
    required this.endLap,
    this.positionBefore,
    this.positionAfter,
  });

  final String compound;
  final int startLap;
  final int endLap;

  /// Position immediately before / after the pit stop that ended the previous
  /// stint (null for the opening stint).
  final int? positionBefore;
  final int? positionAfter;

  int get duration => (endLap - startLap + 1).clamp(0, 200);
  Color get color => AppColors.tyreColor(compound);

  /// Places gained (+) or lost (−) across the stop that started this stint.
  int? get positionDelta {
    final before = positionBefore;
    final after = positionAfter;
    if (before == null || after == null) return null;
    return before - after;
  }
}

/// Season-long identity of a driver within one replay.
class ReplayDriver {
  const ReplayDriver({
    required this.driverId,
    required this.code,
    required this.name,
    required this.constructorId,
    required this.constructorName,
    required this.grid,
    required this.finishPosition,
    required this.status,
    required this.stints,
    this.driverNumber,
  });

  final String driverId;
  final String code;
  final String name;
  final String constructorId;
  final String constructorName;
  final int grid;
  final int finishPosition;
  final String status;
  final List<TyreStint> stints;
  final int? driverNumber;

  Color get color => TeamPalette.of(constructorId);
  bool get finished => status == 'Finished' || status.startsWith('+');

  String get shortName {
    if (code.isNotEmpty) return code;
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.last : name;
  }
}

/// Categories of race event shown on the timeline and in the event feed.
enum RaceEventType {
  lights,
  safetyCar,
  virtualSafetyCar,
  redFlag,
  yellowFlag,
  greenFlag,
  pitStop,
  overtake,
  fastestLap,
  weather,
  retirement,
  chequered;

  String get label => switch (this) {
        RaceEventType.lights => 'Start',
        RaceEventType.safetyCar => 'Safety Car',
        RaceEventType.virtualSafetyCar => 'VSC',
        RaceEventType.redFlag => 'Red Flag',
        RaceEventType.yellowFlag => 'Yellow Flag',
        RaceEventType.greenFlag => 'Green Flag',
        RaceEventType.pitStop => 'Pit Stop',
        RaceEventType.overtake => 'Overtake',
        RaceEventType.fastestLap => 'Fastest Lap',
        RaceEventType.weather => 'Weather',
        RaceEventType.retirement => 'Retirement',
        RaceEventType.chequered => 'Finish',
      };

  IconData get icon => switch (this) {
        RaceEventType.lights => Icons.play_circle_outline_rounded,
        RaceEventType.safetyCar => Icons.local_taxi_rounded,
        RaceEventType.virtualSafetyCar => Icons.slow_motion_video_rounded,
        RaceEventType.redFlag => Icons.flag_rounded,
        RaceEventType.yellowFlag => Icons.warning_amber_rounded,
        RaceEventType.greenFlag => Icons.flag_outlined,
        RaceEventType.pitStop => Icons.build_circle_outlined,
        RaceEventType.overtake => Icons.swap_vert_rounded,
        RaceEventType.fastestLap => Icons.bolt_rounded,
        RaceEventType.weather => Icons.water_drop_outlined,
        RaceEventType.retirement => Icons.remove_circle_outline_rounded,
        RaceEventType.chequered => Icons.sports_score_rounded,
      };

  Color get color => switch (this) {
        RaceEventType.lights => AppColors.info,
        RaceEventType.safetyCar => AppColors.warning,
        RaceEventType.virtualSafetyCar => AppColors.warning,
        RaceEventType.redFlag => AppColors.negative,
        RaceEventType.yellowFlag => AppColors.warning,
        RaceEventType.greenFlag => AppColors.positive,
        RaceEventType.pitStop => AppColors.info,
        RaceEventType.overtake => AppColors.accentSoft,
        RaceEventType.fastestLap => const Color(0xFFB388FF),
        RaceEventType.weather => const Color(0xFF00BCD4),
        RaceEventType.retirement => AppColors.negative,
        RaceEventType.chequered => AppColors.positive,
      };
}

/// A discrete moment in the race, pinned to a lap.
class RaceEvent {
  const RaceEvent({
    required this.lap,
    required this.type,
    required this.title,
    this.detail = '',
    this.driverId,
    this.driverColor,
  });

  final int lap;
  final RaceEventType type;
  final String title;
  final String detail;
  final String? driverId;
  final Color? driverColor;

  Color get accent => driverColor ?? type.color;
}

/// The complete, immutable replay payload. Built once by the repository and
/// passed down to pure widgets so playback never triggers a refetch.
class RaceReplay {
  const RaceReplay({
    required this.meta,
    required this.drivers,
    required this.laps,
    required this.byDriver,
    required this.events,
    required this.totalLaps,
    required this.hasTelemetry,
    required this.generatedAt,
  });

  final RaceMeta meta;
  final List<ReplayDriver> drivers; // finishing order
  final List<LapSnapshot> laps; // index 0 == lap 1
  final Map<String, List<LapEntry>> byDriver;
  final List<RaceEvent> events;
  final int totalLaps;

  /// True when an enrichment source supplied sector times / compounds / speeds.
  final bool hasTelemetry;
  final DateTime generatedAt;

  bool get isEmpty => totalLaps == 0 || drivers.isEmpty;

  ReplayDriver? driver(String driverId) {
    for (final d in drivers) {
      if (d.driverId == driverId) return d;
    }
    return null;
  }

  /// Classification at [lap] (clamped into range).
  LapSnapshot? snapshotAt(int lap) {
    if (laps.isEmpty) return null;
    final index = (lap - 1).clamp(0, laps.length - 1);
    return laps[index];
  }

  List<RaceEvent> eventsAt(int lap) =>
      events.where((e) => e.lap == lap).toList();

  /// Every driver's lap-time series, aligned to lap numbers (null = no data).
  List<double?> lapTimesFor(String driverId) {
    final entries = byDriver[driverId] ?? const <LapEntry>[];
    final out = List<double?>.filled(totalLaps, null);
    for (final e in entries) {
      if (e.lap >= 1 && e.lap <= totalLaps) out[e.lap - 1] = e.lapSeconds;
    }
    return out;
  }
}
