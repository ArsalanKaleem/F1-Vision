import '../core/utils/json.dart';

/// A single OpenF1 weather sample for a session.
class F1Weather {
  const F1Weather({
    this.airTemperature,
    this.trackTemperature,
    this.humidity,
    this.rainfall,
    this.windSpeed,
    this.windDirection,
    this.pressure,
    this.date,
  });

  final double? airTemperature;
  final double? trackTemperature;
  final double? humidity;
  final int? rainfall; // 0 dry, 1 wet
  final double? windSpeed;
  final int? windDirection;
  final double? pressure;
  final DateTime? date;

  bool get isWet => (rainfall ?? 0) > 0;

  factory F1Weather.fromJson(Map<String, dynamic> json) => F1Weather(
        airTemperature: Json.asDouble(json['air_temperature']),
        trackTemperature: Json.asDouble(json['track_temperature']),
        humidity: Json.asDouble(json['humidity']),
        rainfall: Json.asInt(json['rainfall']),
        windSpeed: Json.asDouble(json['wind_speed']),
        windDirection: Json.asInt(json['wind_direction']),
        pressure: Json.asDouble(json['pressure']),
        date: Json.asDate(json['date']),
      );
}
