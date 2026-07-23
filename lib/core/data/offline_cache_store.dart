import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../network/cache_store.dart';
import 'cached_response.dart';

/// A [CacheStore] backed by Isar, giving the app genuine offline support.
///
/// Two tiers:
///   * L1 — the in-memory map inherited from [CacheStore] (fast path).
///   * L2 — Isar, which survives restarts so a previously-viewed season,
///     replay or standings table still renders with no connection.
///
/// The synchronous read/write surface of [CacheStore] is preserved by using
/// Isar's sync APIs, so nothing upstream (DioClient, repositories) changes.
class OfflineCacheStore extends CacheStore {
  OfflineCacheStore(this._isar);

  final Isar _isar;

  /// Entries whose TTL expired are still served when the network is
  /// unavailable; [staleGrace] bounds how old that fallback may be.
  static const Duration staleGrace = Duration(days: 7);

  @override
  Object? read(String key) {
    final memory = super.read(key);
    if (memory != null) return memory;

    try {
      final row = _isar.cachedResponses
          .where()
          .keyEqualTo(key)
          .findFirstSync();
      if (row == null) return null;

      if (DateTime.now().isAfter(row.expiresAt)) return null;

      final decoded = jsonDecode(row.payload) as Object;
      // Warm L1 for the remainder of the entry's life.
      final remaining = row.expiresAt.difference(DateTime.now());
      if (remaining > Duration.zero) {
        super.write(key, decoded, remaining);
      }
      return decoded;
    } catch (e) {
      debugPrint('OfflineCacheStore read failed for "$key": $e');
      return null;
    }
  }

  @override
  void write(String key, Object value, Duration ttl) {
    super.write(key, value, ttl);
    try {
      final row = CachedResponse()
        ..key = key
        ..payload = jsonEncode(value)
        ..expiresAt = DateTime.now().add(ttl)
        ..storedAt = DateTime.now();
      _isar.writeTxnSync(() => _isar.cachedResponses.putSync(row));
    } catch (e) {
      // Persistence is best-effort: a failed write must never break a request.
      debugPrint('OfflineCacheStore write failed for "$key": $e');
    }
  }

  /// Last-resort read used when the network fails: returns a stale entry if one
  /// exists and is younger than [staleGrace].
  Object? readStale(String key) {
    try {
      final row = _isar.cachedResponses
          .where()
          .keyEqualTo(key)
          .findFirstSync();
      if (row == null) return null;
      if (DateTime.now().difference(row.storedAt) > staleGrace) return null;
      return jsonDecode(row.payload) as Object;
    } catch (_) {
      return null;
    }
  }

  @override
  void clear() {
    super.clear();
    try {
      _isar.writeTxnSync(() => _isar.cachedResponses.clearSync());
    } catch (e) {
      debugPrint('OfflineCacheStore clear failed: $e');
    }
  }

  /// Removes entries that are past their TTL and older than [staleGrace].
  /// Called once at startup to keep the database small.
  void prune() {
    try {
      final cutoff = DateTime.now().subtract(staleGrace);
      _isar.writeTxnSync(() {
        _isar.cachedResponses
            .filter()
            .storedAtLessThan(cutoff)
            .deleteAllSync();
      });
    } catch (e) {
      debugPrint('OfflineCacheStore prune failed: $e');
    }
  }

  /// Number of persisted entries — surfaced in Settings.
  int get entryCount {
    try {
      return _isar.cachedResponses.countSync();
    } catch (_) {
      return 0;
    }
  }
}
