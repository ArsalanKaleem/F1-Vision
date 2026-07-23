# Offline cache (Isar)

F1 Vision persists API responses on-device with [Isar](https://isar.dev), so
screens you have already opened keep working without a connection.

## ⚠️ One-time codegen step

Isar generates its schema. **The project will not compile until you run it:**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

This creates `lib/core/data/cached_response.g.dart` (git-ignored). Re-run it
whenever you change a `@collection` class.

## How it works

```
DioClient.getJson(path, cacheTtl: …)
        │
        ▼
   CacheStore  ←— the seam
        │
        ├── CacheStore          (in-memory only; fallback)
        └── OfflineCacheStore   (memory L1 → Isar L2)
```

* **L1 — memory.** Same map the app has always used; sub-millisecond reads.
* **L2 — Isar.** Survives restarts. Reads are synchronous (`findFirstSync`), so
  the existing synchronous `CacheStore` surface is unchanged — `DioClient`,
  services and repositories needed no modification.

Entries store the raw JSON body keyed by the full request URL, so **new
endpoints cache automatically** — the schema never learns about F1 models.

TTLs come from `ApiConstants`:

| Data | TTL |
|---|---|
| Live/session data | `defaultCacheTtl` (30 s) |
| Completed seasons, races, replays | `historicalCacheTtl` (6 h) |

At startup the store prunes rows older than `OfflineCacheStore.staleGrace`
(7 days). Settings → **Offline data** shows how many responses are cached and
offers a manual purge.

## Graceful degradation

If Isar can't open — unsupported platform, missing generated schema, a
sandboxed environment — `main()` catches it, logs a line, and the app runs on
the in-memory cache instead. Nothing else changes, and no feature is lost while
online. This mirrors how optional Firebase auth is handled.

## Testing offline behaviour

1. Run the app and open Standings, Analytics and a race replay.
2. Kill the app, enable airplane mode, relaunch.
3. Those screens render from Isar; screens you never opened show their normal
   error state with a retry.
