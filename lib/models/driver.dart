import 'dart:ui';

import '../core/utils/json.dart';

/// An OpenF1 driver entry for a given session.
class F1Driver {
  const F1Driver({
    required this.driverNumber,
    required this.fullName,
    required this.nameAcronym,
    required this.teamName,
    required this.teamColour,
    required this.countryCode,
    this.headshotUrl,
  });

  final int driverNumber;
  final String fullName;
  final String nameAcronym; // e.g. VER, HAM
  final String teamName;
  final String teamColour; // hex without '#'
  final String countryCode;
  final String? headshotUrl;

  /// Team colour parsed into a Flutter [Color] (OpenF1 omits the leading '#').
  Color get color {
    final hex = teamColour.replaceAll('#', '');
    if (hex.length != 6) return const Color(0xFF888888);
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory F1Driver.fromJson(Map<String, dynamic> json) => F1Driver(
        driverNumber: Json.asInt(json['driver_number']) ?? 0,
        fullName: Json.asString(json['full_name']),
        nameAcronym: Json.asString(json['name_acronym']),
        teamName: Json.asString(json['team_name']),
        teamColour: Json.asString(json['team_colour'], '888888'),
        countryCode: Json.asString(json['country_code']),
        headshotUrl: json['headshot_url']?.toString(),
      );
}
