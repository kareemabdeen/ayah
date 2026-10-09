import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'local_store.dart';

/// Hive-backed [LocalStore]. Values are stored as JSON strings in
/// `Box<String>` so we need no TypeAdapters and no build_runner.
final class HiveLocalStore implements LocalStore {
  HiveLocalStore._(this._boxes);

  final Map<String, Box<String>> _boxes;

  static Future<HiveLocalStore> open({List<String> collections = StoreCollections.all}) async {
    await Hive.initFlutter('ayah');
    final boxes = <String, Box<String>>{};
    for (final name in collections) {
      boxes[name] = await Hive.openBox<String>(name);
    }
    return HiveLocalStore._(boxes);
  }

  Box<String> _box(String collection) {
    final box = _boxes[collection];
    if (box == null) throw StateError('Unknown collection "$collection". Register it in StoreCollections.all.');
    return box;
  }

  @override
  Future<Map<String, dynamic>?> read(String collection, String key) async {
    final raw = _box(collection).get(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String collection, String key, Map<String, dynamic> value) =>
      _box(collection).put(key, jsonEncode(value));

  @override
  Future<void> writeAll(String collection, Map<String, Map<String, dynamic>> entries) =>
      _box(collection).putAll(entries.map((k, v) => MapEntry(k, jsonEncode(v))));

  @override
  Future<List<Map<String, dynamic>>> readAll(String collection) async =>
      _box(collection).values.map((raw) => jsonDecode(raw) as Map<String, dynamic>).toList(growable: false);

  @override
  Future<void> delete(String collection, String key) => _box(collection).delete(key);

  @override
  Future<void> clear(String collection) => _box(collection).clear();
}
