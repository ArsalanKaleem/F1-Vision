import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/result.dart';
import '../models/analytics.dart';
import '../models/comparison.dart';
import '../models/replay.dart';
import 'analytics_providers.dart';
import 'core_providers.dart';
import 'replay_providers.dart';

/// Season under comparison (independent of the other screens' selections).
final comparisonSeasonProvider =
    StateProvider<String>((ref) => DateTime.now().year.toString());

/// Explicitly chosen drivers; null means "use the championship leaders".
final comparisonDriverAProvider = StateProvider<String?>((ref) => null);
final comparisonDriverBProvider = StateProvider<String?>((ref) => null);

/// Optional race to drill into. Null keeps the comparison season-wide.
final comparisonRoundProvider = StateProvider<int?>((ref) => null);

/// Races available to drill into for the selected season.
final comparisonScheduleProvider =
    FutureProvider.family<Result<List<RaceListing>>, String>((ref, season) {
  return ref.watch(replayRepositoryProvider).schedule(season);
});

/// The assembled head-to-head.
///
/// This provider deliberately performs **no** I/O of its own: it composes the
/// already-cached Analytics aggregate with the already-cached Replay for the
/// selected race. Switching drivers is therefore instant, and drilling into a
/// race the user has already replayed costs nothing.
///
/// If the race fails to load, the comparison degrades gracefully to the
/// season-only view rather than erroring the whole screen.
final comparisonProvider = Provider<AsyncValue<DriverComparison?>>((ref) {
  final season = ref.watch(comparisonSeasonProvider);
  final analyticsAsync = ref.watch(analyticsProvider(season));

  return analyticsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
    data: (analyticsResult) => analyticsResult.when(
      failure: (f) => AsyncValue.error(f.message, StackTrace.current),
      success: (analytics) {
        final pair = _resolvePair(ref, analytics);
        if (pair == null) return const AsyncValue.data(null);

        final round = ref.watch(comparisonRoundProvider);
        if (round == null) {
          return AsyncValue.data(DriverComparison.build(
            analytics: analytics,
            driverA: pair.a,
            driverB: pair.b,
          ));
        }

        final request = ReplayRequest(
          season: season,
          round: round,
          session: ReplaySession.race,
        );
        return ref.watch(replayProvider(request)).when(
              loading: () => const AsyncValue.loading(),
              error: (error, stack) => AsyncValue.error(error, stack),
              data: (replayResult) => AsyncValue.data(
                DriverComparison.build(
                  analytics: analytics,
                  driverA: pair.a,
                  driverB: pair.b,
                  // A missing race degrades to the season comparison.
                  replay: replayResult.dataOrNull,
                ),
              ),
            );
      },
    ),
  );
});

/// The drivers currently being compared, falling back to the top two in the
/// championship so the screen is never empty on first open.
({String a, String b})? _resolvePair(Ref ref, SeasonAnalytics analytics) {
  if (analytics.drivers.isEmpty) return null;
  final ids = analytics.drivers.map((d) => d.driverId).toList();

  String? selectedA = ref.watch(comparisonDriverAProvider);
  String? selectedB = ref.watch(comparisonDriverBProvider);
  if (selectedA != null && !ids.contains(selectedA)) selectedA = null;
  if (selectedB != null && !ids.contains(selectedB)) selectedB = null;

  final a = selectedA ?? ids.first;
  final b = selectedB ??
      ids.firstWhere((id) => id != a, orElse: () => ids.last);
  if (a == b) return null;
  return (a: a, b: b);
}

/// Drivers offered in the two pickers, ordered by championship position.
final comparisonDriverOptionsProvider =
    Provider<List<DriverAggregate>>((ref) {
  final season = ref.watch(comparisonSeasonProvider);
  final analytics =
      ref.watch(analyticsProvider(season)).valueOrNull?.dataOrNull;
  return analytics?.drivers ?? const [];
});
