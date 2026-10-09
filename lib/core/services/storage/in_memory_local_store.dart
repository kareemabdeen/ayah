import 'dart:convert';

import 'local_store.dart';

/// In-memory [LocalStore] for tests and previews. Round-trips through JSON
/// so serialization bugs surface in tests exactly as they would with Hive.
final class InMemoryLocalStore implements LocalStore {
  final Map<String, Map<String, String>> _data = {};

  Map<String, String> _col(String c) => _data.putIfAbsent(c, () => {});

  @override
  Future<Map<String, dynamic>?> read(String collection, String key) async {
    final raw = _col(collection)[key];
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String collection, String key, Map<String, dynamic> value) async =>
      _col(collection)[key] = jsonEncode(value);

  @override
  Future<void> writeAll(String collection, Map<String, Map<String, dynamic>> entries) async {
    for (final e in entries.entries) {
      _col(collection)[e.key] = jsonEncode(e.value);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> readAll(String collection) async =>
      _col(collection).values.map((r) => jsonDecode(r) as Map<String, dynamic>).toList(growable: false);

  @override
  Future<void> delete(String collection, String key) async => _col(collection).remove(key);

  @override
  Future<void> clear(String collection) async => _col(collection).clear();
}
