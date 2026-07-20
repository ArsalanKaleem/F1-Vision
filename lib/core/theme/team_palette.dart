import 'package:flutter/material.dart';

/// Maps Jolpica/Ergast `constructorId`s to their brand colours so charts and
/// legends stay recognisable. Unknown teams fall back to a deterministic hue
/// derived from the id, so historical seasons still render distinct colours.
abstract final class TeamPalette {
  static const Map<String, Color> _byId = {
    'red_bull': Color(0xFF3671C6),
    'ferrari': Color(0xFFE8002D),
    'mercedes': Color(0xFF27F4D2),
    'mclaren': Color(0xFFFF8000),
    'aston_martin': Color(0xFF229971),
    'alpine': Color(0xFFFF87BC),
    'williams': Color(0xFF64C4FF),
    'rb': Color(0xFF6692FF),
    'racing_bulls': Color(0xFF6692FF),
    'alphatauri': Color(0xFF5E8FAA),
    'toro_rosso': Color(0xFF469BFF),
    'sauber': Color(0xFF52E252),
    'alfa': Color(0xFFC92D4B),
    'haas': Color(0xFFB6BABD),
    'renault': Color(0xFFFFF500),
    'racing_point': Color(0xFFF596C8),
    'force_india': Color(0xFFF596C8),
    'lotus_f1': Color(0xFFFFB800),
    'toro': Color(0xFF469BFF),
    'manor': Color(0xFFED1C24),
    'caterham': Color(0xFF016A3A),
    'marussia': Color(0xFF6E0000),
  };

  static Color of(String constructorId) {
    final direct = _byId[constructorId];
    if (direct != null) return direct;
    // Deterministic fallback: hash the id into a pleasant, saturated hue.
    var hash = 0;
    for (final unit in constructorId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.62, 0.58).toColor();
  }
}
