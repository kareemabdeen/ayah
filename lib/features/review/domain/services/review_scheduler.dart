import '../../../../core/extensions/date_time_x.dart';
import '../../../progress/domain/entities/verse_progress.dart';
import '../../../quran/domain/entities/verse_key.dart';
import '../entities/review_schedule.dart';

/// Spaced-repetition strategy. Swap the implementation (SM-2, FSRS, …)
/// in DI without touching use cases or UI.
abstract interface class ReviewScheduler {
  /// Progress for an ayah memorized just now. First review: tomorrow.
  VerseProgress initial(VerseKey key, DateTime now, {int attempts = 1});

  /// When the ayah would come back for [rating] (no side effects).
  ReviewSchedule schedule(VerseProgress progress, ReviewRating rating, DateTime now);

  /// New progress after a review with [rating].
  VerseProgress apply(VerseProgress progress, ReviewRating rating, DateTime now);
}

/// Default "interval ladder" scheduler.
///
/// Day-based reviews are normalized to local midnight so an ayah due
/// "in 3 days" is due all of that day, regardless of the review hour.
final class LadderReviewScheduler implements ReviewScheduler {
  const LadderReviewScheduler([this.config = const ReviewSchedulerConfig()]);

  /// Validating constructor for configs built at runtime (e.g. remote config).
  factory LadderReviewScheduler.validated(ReviewSchedulerConfig config) {
    final days = config.ladderDays;
    if (days.isEmpty) throw ArgumentError('ladderDays must not be empty');
    for (var i = 1; i < days.length; i++) {
      if (days[i] <= days[i - 1]) throw ArgumentError('ladderDays must be strictly ascending');
    }
    return LadderReviewScheduler(config);
  }

  final ReviewSchedulerConfig config;

  @override
  VerseProgress initial(VerseKey key, DateTime now, {int attempts = 1}) {
    final extra = attempts > 1 ? attempts - 1 : 0;
    const stage = 0;
    return VerseProgress(
      key: key,
      status: _statusFor(stage),
      stage: stage,
      repetitionCount: 0,
      lapses: 0,
      confidence: _confidenceFor(stage),
      difficulty: _clamp01(config.initialDifficulty + extra * config.difficultyPerExtraAttempt),
      memorizedAt: now,
      lastReviewedAt: now,
      nextReviewAt: now.startOfDay.addDays(config.ladderDays[stage]),
    );
  }

  @override
  ReviewSchedule schedule(VerseProgress progress, ReviewRating rating, DateTime now) {
    if (rating == ReviewRating.forgot) {
      return ReviewSchedule(stage: 0, nextReviewAt: now.add(config.forgotDelay), interval: config.forgotDelay);
    }
    final stage = _nextStage(progress.stage, rating);
    final days = config.ladderDays[stage];
    return ReviewSchedule(
      stage: stage,
      nextReviewAt: now.startOfDay.addDays(days),
      interval: Duration(days: days),
    );
  }

  @override
  VerseProgress apply(VerseProgress progress, ReviewRating rating, DateTime now) {
    final s = schedule(progress, rating, now);
    final forgot = rating == ReviewRating.forgot;
    return progress.copyWith(
      stage: s.stage,
      status: _statusFor(s.stage),
      repetitionCount: progress.repetitionCount + 1,
      lapses: forgot ? progress.lapses + 1 : progress.lapses,
      confidence: forgot ? 0 : _confidenceFor(s.stage),
      difficulty: _clamp01(progress.difficulty + _difficultyDelta(rating)),
      lastReviewedAt: now,
      nextReviewAt: s.nextReviewAt,
    );
  }

  int _nextStage(int current, ReviewRating rating) {
    final raw = switch (rating) {
      ReviewRating.forgot => 0,
      ReviewRating.hard => current - config.hardStageDrop,
      ReviewRating.good => current + config.goodStageJump,
      ReviewRating.easy => current + config.easyStageJump,
    };
    return raw.clamp(0, config.maxStage);
  }

  double _difficultyDelta(ReviewRating r) => switch (r) {
        ReviewRating.forgot => config.difficultyOnForgot,
        ReviewRating.hard => config.difficultyOnHard,
        ReviewRating.good => config.difficultyOnGood,
        ReviewRating.easy => config.difficultyOnEasy,
      };

  VerseStatus _statusFor(int stage) {
    if (stage < config.learningBelowStage) return VerseStatus.learning;
    if (config.ladderDays[stage] >= config.masteredFromDays) return VerseStatus.mastered;
    return VerseStatus.reviewing;
  }

  double _confidenceFor(int stage) => (stage + 1) / config.ladderDays.length;

  static double _clamp01(double v) => v.clamp(0.0, 1.0);
}
