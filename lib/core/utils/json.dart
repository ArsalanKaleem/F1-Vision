/// Both upstreams are loosely typed — OpenF1 occasionally mixes string/number
/// representations, and Jolpica (Ergast) returns *everything* as strings. These
/// helpers coerce safely so model constructors stay clean.
abstract final class Json {
  static int? asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? asDouble(Object? v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String asString(Object? v, [String fallback = '']) =>
      v?.toString() ?? fallback;

  static DateTime? asDate(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
