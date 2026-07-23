import 'package:isar/isar.dart';

part 'cached_response.g.dart';

/// One persisted API response.
///
/// The payload is stored as the raw JSON string exactly as it came off the
/// wire, so the schema never has to know about F1 domain models — new
/// endpoints and models cache for free.
///
/// NOTE: `cached_response.g.dart` is generated. After `flutter pub get`, run:
///   dart run build_runner build --delete-conflicting-outputs
@collection
class CachedResponse {
  Id id = Isar.autoIncrement;

  /// Full request URL including query — the same key the in-memory cache uses.
  @Index(unique: true, replace: true)
  late String key;

  /// The response body, JSON-encoded.
  late String payload;

  /// When this entry stops being served.
  late DateTime expiresAt;

  /// When it was written (used for cache statistics and pruning).
  late DateTime storedAt;
}
