import '../../../progress/domain/entities/verse_progress.dart';

/// Picks which due ayahs are reviewed today.
///
/// Missed days never produce a flood: at most [maxDailyReviews] per day.
/// Priority: weakest first (lowest stage — e.g. freshly memorized or just
/// forgotten), then most overdue. The rest wait for following days.
final class ReviewQueuePolicy {
  const ReviewQueuePolicy({required this.maxDailyReviews});

  final int maxDailyReviews;

  List<VerseProgress> allDue(Iterable<VerseProgress> all, DateTime now) =>
      all.where((p) => p.isDueBy(now)).toList()..sort(_priority);

  /// [reviewedToday] lowers the remaining budget so reopening the app
  /// doesn't hand out a second full batch on the same day.
  List<VerseProgress> select(Iterable<VerseProgress> all, DateTime now, {int reviewedToday = 0}) {
    final budget = maxDailyReviews - reviewedToday;
    if (budget <= 0) return const [];
    return allDue(all, now).take(budget).toList(growable: false);
  }

  static int _priority(VerseProgress a, VerseProgress b) {
    final byStage = a.stage.compareTo(b.stage);
    if (byStage != 0) return byStage;
    final byDue = a.nextReviewAt.compareTo(b.nextReviewAt);
    if (byDue != 0) return byDue;
    return a.key.compareTo(b.key);
  }
}
