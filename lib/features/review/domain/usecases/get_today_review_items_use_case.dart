import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/result.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
import '../../../progress/domain/services/activity_stats.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/review_item.dart';
import '../services/review_queue_policy.dart';

final class GetTodayReviewItemsUseCase {
  const GetTodayReviewItemsUseCase({
    required ProgressRepository progress,
    required QuranRepository quran,
    required ReviewQueuePolicy policy,
    required Clock clock,
  })  : _progress = progress,
        _quran = quran,
        _policy = policy,
        _clock = clock;

  final ProgressRepository _progress;
  final QuranRepository _quran;
  final ReviewQueuePolicy _policy;
  final Clock _clock;

  Future<Result<ReviewQueue>> call() async {
    final now = _clock.now();
    final all = await _progress.getAllProgress();
    final history = await _progress.getAllDailyProgress();
    final today = await _progress.getDailyProgress(now.dayKey);

    final due = _policy.allDue(all, now);
    final selected = _policy.select(all, now, reviewedToday: today.reviewsCompleted);
    final returning = !today.hasActivity &&
        ActivityStats.isReturningAfterBreak(history, now, afterDays: AppConstants.welcomeBackAfterDays);

    if (selected.isEmpty) {
      return Success(
        ReviewQueue(items: const [], totalDue: due.length, isReturningAfterBreak: returning, startedAt: now),
      );
    }

    final verses = await _quran.getVerses([for (final p in selected) p.key]);
    return verses.fold<Result<ReviewQueue>>(
      (f) => Err<ReviewQueue>(f),
      (list) => Success<ReviewQueue>(ReviewQueue(
        items: [for (var i = 0; i < list.length; i++) ReviewItem(verse: list[i], progress: selected[i])],
        totalDue: due.length,
        isReturningAfterBreak: returning,
        startedAt: now,
      )),
    );
  }
}
