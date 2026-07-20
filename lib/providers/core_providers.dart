import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/cache_store.dart';
import '../core/network/dio_client.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/live_repository.dart';
import '../repositories/services/jolpica_service.dart';
import '../repositories/services/openf1_service.dart';
import '../repositories/standings_repository.dart';
import '../repositories/telemetry_repository.dart';

/// A shared cache instance for the whole app session.
final cacheStoreProvider = Provider<CacheStore>((ref) => CacheStore());

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

/// The season the app is currently exploring. Defaults to the live season.
final selectedSeasonProvider = StateProvider<String>((ref) {
  return DateTime.now().year.toString();
});
