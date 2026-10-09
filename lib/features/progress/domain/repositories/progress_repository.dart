import '../../../quran/domain/entities/verse_key.dart';
import '../../../memorization/domain/entities/memorization_session.dart';
import '../entities/daily_progress.dart';
import '../entities/verse_progress.dart';

abstract interface class ProgressRepository {
  Future<List<VerseProgress>> getAllProgress();

  Future<VerseProgress?> getProgress(VerseKey key);

  Future<void> saveProgress(VerseProgress progress);

  Future<DailyProgress> getDailyProgress(String dayKey);

  Future<List<DailyProgress>> getAllDailyProgress();

  Future<void> saveDailyProgress(DailyProgress progress);

  /// Session history (analytics-ready, kept local for now).
  Future<void> saveSessionRecord(MemorizationSessionRecord record);
}
