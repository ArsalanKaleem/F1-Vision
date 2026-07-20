import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/result.dart';
import '../models/standings.dart';
import 'core_providers.dart';

final driverStandingsProvider =
    FutureProvider<Result<List<DriverStanding>>>((ref) {
  final season = ref.watch(selectedSeasonProvider);
  return ref.watch(standingsRepositoryProvider).drivers(season);
});

final constructorStandingsProvider =
    FutureProvider<Result<List<ConstructorStanding>>>((ref) {
  final season = ref.watch(selectedSeasonProvider);
  return ref.watch(standingsRepositoryProvider).constructors(season);
});
