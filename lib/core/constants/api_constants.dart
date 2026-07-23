/// Endpoint configuration for the two upstream data sources.
///
/// * OpenF1   — live & recent telemetry / timing. Returns bare JSON arrays.
///              Historical data is unauthenticated. Supports `session_key=latest`
///              and operator filters such as `speed>=315`.
/// * Jolpica  — Ergast-compatible historical data. Returns an `MRData` wrapper.
///              Unauthenticated rate limit ~4 req/s, 500 req/hr — be polite.
abstract final class ApiConstants {
  // OpenF1 ---------------------------------------------------------------
  static const String openF1BaseUrl = 'https://api.openf1.org/v1';

  static const String sessions = '/sessions';
  static const String meetings = '/meetings';
  static const String drivers = '/drivers';
  static const String laps = '/laps';
  static const String carData = '/car_data';
  static const String position = '/position';
  static const String intervals = '/intervals';
  static const String stints = '/stints';
  static const String pit = '/pit';
  static const String weather = '/weather';
  static const String raceControl = '/race_control';

  /// Sentinel accepted by OpenF1 to mean "the most recent session/meeting".
  static const String latest = 'latest';

  // Jolpica (Ergast-compatible) -----------------------------------------
  static const String jolpicaBaseUrl = 'https://api.jolpi.ca/ergast/f1';

  static String driverStandings(String season) => '/$season/driverStandings.json';
  static String constructorStandings(String season) =>
      '/$season/constructorStandings.json';
  static String raceSchedule(String season) => '/$season/races.json';
  static String results(String season, String round) =>
      '/$season/$round/results.json';

  // Race replay (single-event feeds) ------------------------------------
  static String raceLaps(String season, int round) =>
      '/$season/$round/laps.json';
  static String racePitStops(String season, int round) =>
      '/$season/$round/pitstops.json';
  static String raceQualifying(String season, int round) =>
      '/$season/$round/qualifying.json';
  static String raceResults(String season, int round) =>
      '/$season/$round/results.json';
  static String sprintResults(String season, int round) =>
      '/$season/$round/sprint.json';

  // Analytics (season-wide aggregates) ----------------------------------
  static String seasonResults(String season) => '/$season/results.json';
  static String seasonQualifyingPole(String season) =>
      '/$season/qualifying/1.json';
  static String seasonStatus(String season) => '/$season/status.json';
  static String lastPitStops(String season) => '/$season/last/pitstops.json';

  // Timeouts -------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Retry ----------------------------------------------------------------
  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(milliseconds: 600);

  // Cache ----------------------------------------------------------------
  static const Duration defaultCacheTtl = Duration(seconds: 30);
  static const Duration historicalCacheTtl = Duration(hours: 6);
}
