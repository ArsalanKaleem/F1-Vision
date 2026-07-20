import '../core/utils/json.dart';

/// An OpenF1 session (Practice / Qualifying / Sprint / Race) enriched with the
/// meeting fields OpenF1 conveniently denormalises onto each session record.
class F1Session {
  const F1Session({
    required this.sessionKey,
    required this.meetingKey,
    required this.sessionName,
    required this.sessionType,
    required this.location,
    required this.countryName,
    required this.circuitShortName,
    this.dateStart,
    this.dateEnd,
    this.year,
  });

  final int sessionKey;
  final int meetingKey;
  final String sessionName;
  final String sessionType;
  final String location;
  final String countryName;
  final String circuitShortName;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final int? year;

  bool get isRace => sessionType.toUpperCase() == 'RACE';

  /// True while the session is actually running (with a small buffer either
  /// side). OpenF1's `latest` session is usually a *past* session outside race
  /// weekends — screens use this to switch between "live feed" and "latest
  /// classification" presentations.
  bool get isLive {
    final start = dateStart;
    if (start == null) return false;
    final now = DateTime.now().toUtc();
    final end = (dateEnd ?? start.add(const Duration(hours: 3)))
        .add(const Duration(minutes: 15));
    return now.isAfter(start.subtract(const Duration(minutes: 5))) &&
        now.isBefore(end);
  }

  factory F1Session.fromJson(Map<String, dynamic> json) => F1Session(
        sessionKey: Json.asInt(json['session_key']) ?? 0,
        meetingKey: Json.asInt(json['meeting_key']) ?? 0,
        sessionName: Json.asString(json['session_name']),
        sessionType: Json.asString(json['session_type']),
        location: Json.asString(json['location']),
        countryName: Json.asString(json['country_name']),
        circuitShortName: Json.asString(json['circuit_short_name']),
        dateStart: Json.asDate(json['date_start']),
        dateEnd: Json.asDate(json['date_end']),
        year: Json.asInt(json['year']),
      );
}
