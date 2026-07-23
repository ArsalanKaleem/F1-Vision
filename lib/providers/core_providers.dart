import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:isar/isar.dart';

import '../core/constants/api_constants.dart';
import '../core/data/offline_cache_store.dart';
import '../core/network/cache_store.dart';
import '../core/network/dio_client.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/live_repository.dart';
import '../repositories/replay/replay_enrichment.dart';
import '../repositories/replay_repository.dart';
import '../repositories/services/jolpica_service.dart';
import '../repositories/services/openf1_service.dart';
import '../repositories/standings_repository.dart';
import '../repositories/telemetry_repository.dart';

/// The opened Isar instance, or null when persistence is unavailable
/// (overridden in `main()`).
final isarProvider = Provider<Isar?>((ref) => null);

/// The app-wide response cache.
///
/// Backed by Isar when persistence opened successfully — giving real offline
/// support across restarts — and by a plain in-memory store otherwise, so the
/// app is fully functional either way.
final cacheStoreProvider = Provider<CacheStore>((ref) {
  final isar = ref.watch(isarProvider);
  if (isar == null) return CacheStore();
  final store = OfflineCacheStore(isar)..prune();
  return store;
});

// ── Dio clients (one per upstream) ─────────────────────────────────────
final openF1ClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: ApiConstants.openF1BaseUrl,
    cache: ref.watch(cacheStoreProvider),
  );
});

final jolpicaClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: ApiConstants.jolpicaBaseUrl,
    cache: ref.watch(cacheStoreProvider),
  );
});

// ── Services ───────────────────────────────────────────────────────────
final openF1ServiceProvider = Provider<OpenF1Service>(
  (ref) => OpenF1Service(ref.watch(openF1ClientProvider)),
);

final jolpicaServiceProvider = Provider<JolpicaService>(
  (ref) => JolpicaService(ref.watch(jolpicaClientProvider)),
);

// ── Repositories ───────────────────────────────────────────────────────
final liveRepositoryProvider = Provider<LiveRepository>(
  (ref) => LiveRepository(ref.watch(openF1ServiceProvider)),
);

final standingsRepositoryProvider = Provider<StandingsRepository>(
  (ref) => StandingsRepository(ref.watch(jolpicaServiceProvider)),
);

final telemetryRepositoryProvider = Provider<TelemetryRepository>(
  (ref) => TelemetryRepository(ref.watch(openF1ServiceProvider)),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.watch(jolpicaServiceProvider)),
);

/// Telemetry providers that can enrich a race replay, tried in order.
///
/// Register additional providers here — the replay models, repository and UI
/// stay untouched.
final replayEnrichmentSourcesProvider =
    Provider<List<ReplayEnrichmentSource>>((ref) {
  return [OpenF1EnrichmentSource(ref.watch(openF1ServiceProvider))];
});

final replayRepositoryProvider = Provider<ReplayRepository>(
  (ref) => ReplayRepository(
    ref.watch(jolpicaServiceProvider),
    ref.watch(replayEnrichmentSourcesProvider),
  ),
);

/// The season the app is currently exploring. Defaults to the live season.
final selectedSeasonProvider = StateProvider<String>((ref) {
  return DateTime.now().year.toString();
});
