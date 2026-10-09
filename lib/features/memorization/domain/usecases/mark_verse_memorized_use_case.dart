import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/utils/clock.dart';
import '../../../progress/domain/entities/verse_progress.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
import '../../../quran/domain/entities/verse_key.dart';
import '../../../review/domain/services/review_scheduler.dart';

/// Records a newly memorized ayah and schedules its first review (tomorrow).
/// Idempotent: memorizing an ayah twice never resets its review history.
final class MarkVerseMemorizedUseCase {
  const MarkVerseMemorizedUseCase({
    required ProgressRepository progress,
    required ReviewScheduler scheduler,
    required Clock clock,
  })  : _progress = progress,
        _scheduler = scheduler,
        _clock = clock;

  final ProgressRepository _progress;
  final ReviewScheduler _scheduler;
  final Clock _clock;

  Future<VerseProgress> call(VerseKey key, {int attempts = 1}) async {
    final existing = await _progress.getProgress(key);
    if (existing != null) return existing;

    final now = _clock.now();
    final created = _scheduler.initial(key, now, attempts: attempts);
    await _progress.saveProgress(created);

    final day = await _progress.getDailyProgress(now.dayKey);
    if (!day.newVersesMemorized.contains(key.id)) {
      await _progress.saveDailyProgress(day.copyWith(newVersesMemorized: [...day.newVersesMemorized, key.id]));
    }
    return created;
  }
}
