import '../../../../core/services/storage/local_store.dart';
import '../../../memorization/domain/entities/memorization_session.dart';
import '../../../quran/domain/entities/verse_key.dart';
import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/verse_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../models/progress_mappers.dart';

/// Local-first progress storage. A future cloud-sync repository can wrap
/// this one (decorator) without changing any use case.
final class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._store);

  final LocalStore _store;

  @override
  Future<List<VerseProgress>> getAllProgress() async =>
      (await _store.readAll(StoreCollections.verseProgress)).map(VerseProgressMapper.fromJson).toList();

  @override
  Future<VerseProgress?> getProgress(VerseKey key) async {
    final raw = await _store.read(StoreCollections.verseProgress, key.id);
    return raw == null ? null : VerseProgressMapper.fromJson(raw);
  }

  @override
  Future<void> saveProgress(VerseProgress progress) =>
      _store.write(StoreCollections.verseProgress, progress.key.id, VerseProgressMapper.toJson(progress));

  @override
  Future<DailyProgress> getDailyProgress(String dayKey) async {
    final raw = await _store.read(StoreCollections.dailyProgress, dayKey);
    return raw == null ? DailyProgress(dayKey: dayKey) : DailyProgressMapper.fromJson(raw);
  }

  @override
  Future<List<DailyProgress>> getAllDailyProgress() async =>
      (await _store.readAll(StoreCollections.dailyProgress)).map(DailyProgressMapper.fromJson).toList();

  @override
  Future<void> saveDailyProgress(DailyProgress progress) =>
      _store.write(StoreCollections.dailyProgress, progress.dayKey, DailyProgressMapper.toJson(progress));

  @override
  Future<void> saveSessionRecord(MemorizationSessionRecord record) =>
      _store.write(StoreCollections.sessions, record.id, SessionRecordMapper.toJson(record));
}
