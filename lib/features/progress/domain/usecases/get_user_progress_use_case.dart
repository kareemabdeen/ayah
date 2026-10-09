import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/utils/clock.dart';
import '../../../review/domain/services/review_queue_policy.dart';
import '../entities/daily_progress.dart';
import '../repositories/progress_repository.dart';
import '../services/activity_stats.dart';

final class GetUserProgressUseCase {
  const GetUserProgressUseCase({
    required ProgressRepository progress,
    required ReviewQueuePolicy policy,
    required Clock clock,
  })  : _progress = progress,
        _policy = policy,
        _clock = clock;

  final ProgressRepository _progress;
  final ReviewQueuePolicy _policy;
  final Clock _clock;

  Future<UserProgressSummary> call() async {
    final now = _clock.now();
    final all = await _progress.getAllProgress();
    final history = await _progress.getAllDailyProgress();
    final today = await _progress.getDailyProgress(now.dayKey);

    return UserProgressSummary(
      memorizedCount: all.length,
      dueReviewCount: _policy.select(all, now, reviewedToday: today.reviewsCompleted).length,
      activeDays: ActivityStats.activeDays(history),
      daysSinceLastActivity: today.hasActivity ? 0 : ActivityStats.daysSinceLastActivity(history, now),
    );
  }
}
