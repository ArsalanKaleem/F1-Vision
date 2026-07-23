import '../core/utils/json.dart';

/// A driver championship standing row (Jolpica/Ergast `DriverStanding`).
class DriverStanding {
  const DriverStanding({
    required this.position,
    required this.points,
    required this.wins,
    required this.driverId,
    required this.givenName,
    required this.familyName,
    required this.nationality,
    required this.permanentNumber,
    required this.constructorName,
  });

  final int position;
  final double points;
  final int wins;
  final String driverId;
  final String givenName;
  final String familyName;
  final String nationality;
  final String permanentNumber;
  final String constructorName;

  String get fullName => '$givenName $familyName';

  factory DriverStanding.fromJson(Map<String, dynamic> json) {
    final driver = (json['Driver'] as Map?)?.cast<String, dynamic>() ?? {};
    final constructors =
        (json['Constructors'] as List?)?.cast<Map>() ?? const [];
    final firstConstructor =
        constructors.isNotEmpty ? (constructors.first as Map).cast<String, dynamic>() : {};

    return DriverStanding(
      position: Json.asInt(json['position']) ?? 0,
      points: Json.asDouble(json['points']) ?? 0,
      wins: Json.asInt(json['wins']) ?? 0,
      driverId: Json.asString(driver['driverId']),
      givenName: Json.asString(driver['givenName']),
      familyName: Json.asString(driver['familyName']),
      nationality: Json.asString(driver['nationality']),
      permanentNumber: Json.asString(driver['permanentNumber']),
      constructorName: Json.asString(firstConstructor['name']),
    );
  }
}

/// A constructor championship standing row (Jolpica/Ergast `ConstructorStanding`).
class ConstructorStanding {
  const ConstructorStanding({
    required this.position,
    required this.points,
    required this.wins,
    required this.constructorId,
    required this.name,
    required this.nationality,
  });

  final int position;
  final double points;
  final int wins;
  final String constructorId;
  final String name;
  final String nationality;

  factory ConstructorStanding.fromJson(Map<String, dynamic> json) {
    final constructor =
        (json['Constructor'] as Map?)?.cast<String, dynamic>() ?? {};
    return ConstructorStanding(
      position: Json.asInt(json['position']) ?? 0,
      points: Json.asDouble(json['points']) ?? 0,
      wins: Json.asInt(json['wins']) ?? 0,
      constructorId: Json.asString(constructor['constructorId']),
      name: Json.asString(constructor['name']),
      nationality: Json.asString(constructor['nationality']),
    );
  }
}
