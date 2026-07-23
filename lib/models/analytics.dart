import 'package:flutter/material.dart';

import '../core/theme/team_palette.dart';
import '../core/utils/json.dart';

/// One driver's result in one race (parsed from a Jolpica `Results` row).
class RaceResultRow {
  const RaceResultRow({
    required this.round,
    required this.raceName,
    required this.driverId,
    required this.driverCode,
    required this.driverName,
    required this.constructorId,
    required this.constructorName,
    required this.position,
    required this.grid,
    required this.points,
    required this.status,
    required this.setFastestLap,
    this.fastestLapSpeed,
    this.fastestLapSeconds,
  });

  final int round;
  final String raceName;
  final String driverId;
  final String driverCode;
  final String driverName;
  final String constructorId;
  final String constructorName;
  final int position;
  final int grid;
  final double points;
  final String status;
  final bool setFastestLap;
  final double? fastestLapSpeed; // km/h
  final double? fastestLapSeconds;

  /// Ergast marks classified finishers as "Finished" or "+N Lap(s)".
  bool get finished => status == 'Finished' || status.startsWith('+');
  bool get dnf => !finished;
  bool get podium => position >= 1 && position <= 3;

  factory RaceResultRow.fromResult({
    required int round,
    required String raceName,
    required Map<String, dynamic> json,
  }) {
    final driver = (json['Driver'] as Map?)?.cast<String, dynamic>() ?? {};
    final constructor =
        (json['Constructor'] as Map?)?.cast<String, dynamic>() ?? {};
    final fastest = (json['FastestLap'] as Map?)?.cast<String, dynamic>();

    double? speed;
    double? seconds;
    var setFl = false;
    if (fastest != null) {
      setFl = Json.asString(fastest['rank']) == '1';
      final avg = (fastest['AverageSpeed'] as Map?)?.cast<String, dynamic>();
      speed = Json.asDouble(avg?['speed']);
      final time = (fastest['Time'] as Map?)?.cast<String, dynamic>();
      seconds = _parseLapSeconds(Json.asString(time?['time']));
    }

    return RaceResultRow(
      round: round,
      raceName: raceName,
      driverId: Json.asString(driver['driverId']),
      driverCode: Json.asString(driver['code']),
      driverName:
          '${Json.asString(driver['givenName'])} ${Json.asString(driver['familyName'])}'
              .trim(),
      constructorId: Json.asString(constructor['constructorId']),
      constructorName: Json.asString(constructor['name']),
      position: Json.asInt(json['position']) ?? 0,
      grid: Json.asInt(json['grid']) ?? 0,
      points: Json.asDouble(json['points']) ?? 0,
      status: Json.asString(json['status'], 'Unknown'),
      setFastestLap: setFl,
      fastestLapSpeed: speed,
      fastestLapSeconds: seconds,
    );
  }

  /// Parses "1:31.447" or "58.123" into seconds.
  static double? _parseLapSeconds(String raw) {
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

/// Season-long aggregate for a single driver.
class DriverAggregate {
  const DriverAggregate({
    required this.driverId,
    required this.code,
    required this.name,
    required this.constructorId,
    required this.constructorName,
    required this.championshipPosition,
    required this.points,
    required this.wins,
    required this.podiums,
    required this.poles,
    required this.fastestLaps,
    required this.dnfs,
    required this.avgFinish,
    required this.avgPaceKmh,
    required this.last5,
    required this.cumulativePoints,
  });

  final String driverId;
  final String code;
  final String name;
  final String constructorId;
  final String constructorName;
  final int championshipPosition;
  final double points;
  final int wins;
  final int podiums;
  final int poles;
  final int fastestLaps;
  final int dnfs;
  final double avgFinish;
  final double avgPaceKmh;
  final List<int> last5; // finishing positions, oldest → newest
  final List<double> cumulativePoints; // aligned to season rounds

  Color get color => TeamPalette.of(constructorId);
  String get shortName {
    if (code.isNotEmpty) return code;
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts.last : name;
  }
}

/// Season-long aggregate for a single constructor.
class ConstructorAggregate {
  const ConstructorAggregate({
    required this.constructorId,
    required this.name,
    required this.championshipPosition,
    required this.points,
    required this.wins,
    required this.podiums,
    required this.avgPaceKmh,
    required this.cumulativePoints,
  });

  final String constructorId;
  final String name;
  final int championshipPosition;
  final double points;
  final int wins;
  final int podiums;
  final double avgPaceKmh;
  final List<double> cumulativePoints;

  Color get color => TeamPalette.of(constructorId);
}

/// A single slice of the season's finish-status breakdown.
class StatusSlice {
  const StatusSlice({required this.label, required this.count});
  final String label;
  final int count;
}

/// Pit-stop analytics for the most recent race.
class PitAnalytics {
  const PitAnalytics({
    required this.raceName,
    required this.avgSeconds,
    required this.fastestSeconds,
    required this.fastestLabel,
    required this.stops,
  });

  final String raceName;
  final double avgSeconds;
  final double fastestSeconds;
  final String fastestLabel;
  final int stops;
}

/// The full analytics payload for a season — built once by the repository and
/// passed down to panels as immutable data (so panels rebuild minimally).
class SeasonAnalytics {
  const SeasonAnalytics({
    required this.season,
    required this.roundLabels,
    required this.raceNames,
    required this.totalRounds,
    required this.drivers,
    required this.constructors,
    required this.statusSlices,
    required this.generatedAt,
    this.pit,
    this.classifiedCount = 0,
    this.statusTotal = 0,
  });

  final String season;
  final List<String> roundLabels; // e.g. ['R1','R2',…] aligned to cumulatives
  final List<String> raceNames; // full names, aligned to roundLabels
  final int totalRounds;
  final List<DriverAggregate> drivers; // sorted by championship position
  final List<ConstructorAggregate> constructors;
  final List<StatusSlice> statusSlices;

  /// Classified finishers ("Finished" plus any "+N Lap" result) and the total
  /// number of classified results. Computed from the *full* status table
  /// before the display slices collapse the long tail into "Other", so the
  /// finish/retirement rates stay accurate.
  final int classifiedCount;
  final int statusTotal;
  final PitAnalytics? pit;
  final DateTime generatedAt;

  bool get isEmpty => drivers.isEmpty || totalRounds == 0;
}
