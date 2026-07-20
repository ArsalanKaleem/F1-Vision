import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/result.dart';
import '../models/live_entry.dart';
import '../models/session.dart';
import '../models/weather.dart';
import 'core_providers.dart';

/// Re-invalidates [ref] on a fixed interval so a [FutureProvider] re-fetches
/// while it is being listened to. The timer is torn down automatically when the
/// provider is disposed (i.e. when no widget is watching it anymore), which
/// prevents orphaned polling loops from hammering the API in the background.
void _poll(Ref ref, Duration interval) {
  final timer = Timer(interval, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
}

/// The latest / live session. Auto-refreshes every 30s while watched.
final latestSessionProvider = FutureProvider<Result<F1Session>>((ref) {
  _poll(ref, const Duration(seconds: 30));
  return ref.watch(liveRepositoryProvider).latestSession();
});

/// Weather for a given session. Refreshes every 30s while watched.
final weatherProvider =
    FutureProvider.family<Result<F1Weather?>, int>((ref, sessionKey) {
  _poll(ref, const Duration(seconds: 30));
  return ref.watch(liveRepositoryProvider).weather(sessionKey);
});

/// True while the latest session is actually in progress.
final sessionIsLiveProvider = Provider<bool>((ref) {
  final session =
      ref.watch(latestSessionProvider).valueOrNull?.dataOrNull;
  return session?.isLive ?? false;
});

/// The composed live leaderboard for a session. Polls every 5s during a live
/// session; when the session is over the classification is final, so it only
/// re-checks occasionally (which also spares the API).
final leaderboardProvider =
    FutureProvider.family<Result<List<LiveEntry>>, int>((ref, sessionKey) {
  final live = ref.watch(sessionIsLiveProvider);
  _poll(ref, live ? const Duration(seconds: 5) : const Duration(minutes: 2));
  return ref.watch(liveRepositoryProvider).leaderboard(sessionKey);
});
