import 'package:equatable/equatable.dart';

/// What the user did on one calendar day. A day with any activity counts
/// toward "days of memorization" — a total that never resets.
final class DailyProgress extends Equatable {
  const DailyProgress({
    required this.dayKey,
    this.newVersesMemorized = const [],
    this.reviewsCompleted = 0,
  });

  /// `yyyy-MM-dd`, local time.
  final String dayKey;

  /// Verse ids (`surah:ayah`) memorized for the first time that day.
  final List<String> newVersesMemorized;
  final int reviewsCompleted;

  bool get hasActivity => newVersesMemorized.isNotEmpty || reviewsCompleted > 0;

  DailyProgress copyWith({List<String>? newVersesMemorized, int? reviewsCompleted}) => DailyProgress(
        dayKey: dayKey,
        newVersesMemorized: newVersesMemorized ?? this.newVersesMemorized,
        reviewsCompleted: reviewsCompleted ?? this.reviewsCompleted,
      );

  @override
  List<Object?> get props => [dayKey, newVersesMemorized, reviewsCompleted];
}

/// Aggregate shown (minimally) on Home.
final class UserProgressSummary extends Equatable {
  const UserProgressSummary({
    required this.memorizedCount,
    required this.dueReviewCount,
    required this.activeDays,
    required this.daysSinceLastActivity,
  });

  final int memorizedCount;

  /// Already capped by the daily review workload.
  final int dueReviewCount;

  /// Total days with any activity — never resets on missed days.
  final int activeDays;

  /// `null` if the user has never been active.
  final int? daysSinceLastActivity;

  @override
  List<Object?> get props => [memorizedCount, dueReviewCount, activeDays, daysSinceLastActivity];
}
