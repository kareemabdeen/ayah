/// Tiny document-store abstraction over whatever local DB we use.
///
/// Data sources talk to this, never to Hive directly, so the engine
/// (Hive today, SQLite/Drift tomorrow) is swappable without touching
/// repositories or anything above them.
abstract interface class LocalStore {
  Future<Map<String, dynamic>?> read(String collection, String key);

  Future<void> write(String collection, String key, Map<String, dynamic> value);

  Future<void> writeAll(String collection, Map<String, Map<String, dynamic>> entries);

  Future<List<Map<String, dynamic>>> readAll(String collection);

  Future<void> delete(String collection, String key);

  Future<void> clear(String collection);
}

/// Collection names in one place.
abstract final class StoreCollections {
  static const String preferences = 'preferences';
  static const String verseProgress = 'verse_progress';
  static const String dailyProgress = 'daily_progress';
  static const String sessions = 'sessions';
  static const String quranCache = 'quran_cache';

  static const List<String> all = [preferences, verseProgress, dailyProgress, sessions, quranCache];
}
