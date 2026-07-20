/// A tiny TTL-based in-memory cache.
///
/// Keyed by full request URL. This is the seam the brief calls "caching" — for
/// real offline support, implement the same surface backed by isar/hive and
/// inject it where [CacheStore] is used.
class CacheStore {
  final Map<String, _CacheEntry> _entries = {};

  Object? read(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  void write(String key, Object value, Duration ttl) {
    _entries[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  void clear() => _entries.clear();
}

class _CacheEntry {
  _CacheEntry(this.value, this.expiresAt);
  final Object value;
  final DateTime expiresAt;
}
