import '../core/utils/json.dart';

/// A single OpenF1 `/car_data` sample (~3.7 Hz on track).
///
/// OpenF1 reports `brake` as 0 or 100 and `drs` as a status code rather than a
/// boolean — the helpers below translate those into the booleans the UI wants.
class TelemetrySample {
  const TelemetrySample({
    required this.date,
    required this.speed,
    required this.rpm,
    required this.throttle,
    required this.brake,
    required this.gear,
    required this.drs,
  });

  final DateTime date;
  final int speed; // km/h
  final int rpm; // engine rpm
  final int throttle; // 0..100 (%)
  final int brake; // 0 or 100 (%) per OpenF1
  final int gear; // 0..8 (0 == neutral)
  final int drs; // raw OpenF1 DRS status code

  /// OpenF1 DRS codes 10/12/14 mean the flap is open (active).
  bool get drsActive => drs == 10 || drs == 12 || drs == 14;

  /// Code 8 means the car is within a detection zone and eligible to use DRS.
  bool get drsEligible => drs == 8;

  bool get braking => brake >= 50;

  /// Human gear label — neutral shows as "N".
  String get gearLabel => gear <= 0 ? 'N' : '$gear';

  /// Sensible full-scale references for gauges/axes.
  static const double speedScale = 360; // km/h
  static const double rpmScale = 15000;

  factory TelemetrySample.fromJson(Map<String, dynamic> json) => TelemetrySample(
        date: Json.asDate(json['date']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        speed: Json.asInt(json['speed']) ?? 0,
        rpm: Json.asInt(json['rpm']) ?? 0,
        throttle: Json.asInt(json['throttle']) ?? 0,
        brake: Json.asInt(json['brake']) ?? 0,
        gear: Json.asInt(json['n_gear']) ?? 0,
        drs: Json.asInt(json['drs']) ?? 0,
      );
}
