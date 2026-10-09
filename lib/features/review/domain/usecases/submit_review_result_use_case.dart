import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/utils/clock.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
import '../entities/review_item.dart';
import '../entities/review_schedule.dart';
import '../services/review_scheduler.dart';

final class SubmitReviewResultUseCase {
  const SubmitReviewResultUseCase({
    required ProgressRepository progress,
    required ReviewScheduler scheduler,
    required Clock clock,
  })  : _progress = progress,
        _scheduler = scheduler,
        _clock = clock;

  final ProgressRepository _progress;
  final ReviewScheduler _scheduler;
  final Clock _clock;

  /// Reschedules the ayah. [countsTowardDailyLimit] is false for an in-session
  /// retry of an ayah already rated once, so retries don't eat the budget.
  Future<ReviewItem> call(ReviewItem item, ReviewRating rating, {bool countsTowardDailyLimit = true}) async {
    final now = _clock.now();
    final updated = _scheduler.apply(item.progress, rating, now);
    await _progress.saveProgress(updated);

    if (countsTowardDailyLimit) {
      final day = await _progress.getDailyProgress(now.dayKey);
      await _progress.saveDailyProgress(day.copyWith(reviewsCompleted: day.reviewsCompleted + 1));
    }
    return item.withProgress(updated);
  }
}
