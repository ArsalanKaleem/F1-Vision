import 'package:intl/intl.dart';

/// Domain-specific formatting helpers (lap times, gaps, countdowns).
abstract final class Formatters {
  static final _dayMonth = DateFormat('d MMM');
  static final _weekday = DateFormat('EEE, d MMM');

  /// 83.214 → "1:23.214"
  static String lapTime(num? seconds) {
    if (seconds == null) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return s.toStringAsFixed(3);
    return '$m:${s.toStringAsFixed(3).padLeft(6, '0')}';
  }

  /// Signed gap, e.g. +0.214 / LEADER.
  static String gap(num? seconds) {
    if (seconds == null) return '—';
    if (seconds == 0) return 'LEADER';
    return '+${seconds.toStringAsFixed(3)}';
  }

  static String dayMonth(DateTime d) => _dayMonth.format(d);
  static String weekday(DateTime d) => _weekday.format(d);

  /// Countdown like "3d 04h 12m" or "12:04:33" inside the final day.
  static String countdown(Duration d) {
    if (d.isNegative) return 'LIVE';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days > 0) {
      return '${days}d ${_two(hours)}h ${_two(minutes)}m';
    }
    return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
