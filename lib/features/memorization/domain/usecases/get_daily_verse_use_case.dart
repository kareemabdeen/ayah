import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/result.dart';
import '../../../onboarding/domain/repositories/preferences_repository.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
import '../../../quran/domain/entities/verse.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/daily_plan.dart';
import '../services/memorization_path.dart';

/// Builds today's plan: `goal − memorizedToday` next ayahs on the user's path.
/// Pass [extra] to offer one more ayah after the goal is reached (optional,
/// never pushed).
final class GetDailyVerseUseCase {
  const GetDailyVerseUseCase({
    required PreferencesRepository preferences,
    required ProgressRepository progress,
    required QuranRepository quran,
    required Clock clock,
  })  : _preferences = preferences,
        _progress = progress,
        _quran = quran,
        _clock = clock;

  final PreferencesRepository _preferences;
  final ProgressRepository _progress;
  final QuranRepository _quran;
  final Clock _clock;

  Future<Result<DailyPlan>> call({int extra = 0}) async {
    final prefs = await _preferences.load();
    final all = await _progress.getAllProgress();
    final today = await _progress.getDailyProgress(_clock.now().dayKey);

    final memorizedToday = today.newVersesMemorized.length;
    final owed = prefs.dailyGoal - memorizedToday;
    final remainingCount = (owed > 0 ? owed : 0) + extra;

    final candidates = MemorizationPath.nextUnmemorized(
      surahOrder: MemorizationPath.surahOrder(prefs),
      surahs: _quran.getSurahs(),
      memorized: {for (final p in all) p.key},
      count: remainingCount > 0 ? remainingCount : 1,
    );
    final keys = candidates.take(remainingCount).toList();

    final versesResult = keys.isEmpty ? const Success<List<Verse>>([]) : await _quran.getVerses(keys);

    return versesResult.fold<Result<DailyPlan>>(
      (f) => Err<DailyPlan>(f),
      (verses) => Success<DailyPlan>(DailyPlan(
        goal: prefs.dailyGoal,
        memorizedToday: memorizedToday,
        remaining: verses,
        isQuranComplete: candidates.isEmpty,
      )),
    );
  }
}
