import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/result.dart';
import '../models/analytics.dart';
import 'core_providers.dart';

/// The season the Command Center is exploring. Kept separate from the global
/// [selectedSeasonProvider] so browsing analytics never disturbs other screens.
final analyticsSeasonProvider =
    StateProvider<String>((ref) => DateTime.now().year.toString());

/// A short list of recent seasons offered in the season picker.
final analyticsSeasonOptionsProvider = Provider<List<String>>((ref) {
  final year = DateTime.now().year;
  return [for (var y = year; y >= year - 6; y--) y.toString()];
});

/// The composed analytics payload for a season.
///
/// For the *current* season the provider re-fetches every 90s so that results
/// roll in automatically after a race weekend; completed seasons are immutable
/// and never poll (and are served from the Dio cache).
final analyticsProvider =
    FutureProvider.family<Result<SeasonAnalytics>, String>((ref, season) {
  final isCurrent = season == DateTime.now().year.toString();
  if (isCurrent) {
    final timer = Timer(const Duration(seconds: 90), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return ref.watch(analyticsRepositoryProvider).season(season);
});
