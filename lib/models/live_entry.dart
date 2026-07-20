import '../core/utils/json.dart';
import 'driver.dart';

/// A composed live leaderboard row. OpenF1 splits live state across several
/// endpoints (position, intervals, stints, car_data); the repository joins them
/// into this view model so the UI consumes one clean object.
class LiveEntry {
  const LiveEntry({
    required this.driver,
    required this.position,
    this.gapToLeader,
    this.interval,
    this.compound,
    this.stintLaps,
    this.speed,
    this.drs,
  });

  final F1Driver driver;
  final int position;
  final double? gapToLeader;
  final double? interval; // gap to car ahead
  final String? compound;
  final int? stintLaps;
  final int? speed;
  final int? drs;

  bool get drsActive => (drs ?? 0) >= 10; // OpenF1 DRS codes 10–14 ≈ active

  LiveEntry copyWith({
    int? position,
    double? gapToLeader,
    double? interval,
    String? compound,
    int? stintLaps,
    int? speed,
    int? drs,
  }) {
    return LiveEntry(
      driver: driver,
      position: position ?? this.position,
      gapToLeader: gapToLeader ?? this.gapToLeader,
      interval: interval ?? this.interval,
      compound: compound ?? this.compound,
      stintLaps: stintLaps ?? this.stintLaps,
      speed: speed ?? this.speed,
      drs: drs ?? this.drs,
    );
  }

  /// Parses an OpenF1 `/position` record into a position number.
  static int positionFromJson(Map<String, dynamic> json) =>
      Json.asInt(json['position']) ?? 0;
}
