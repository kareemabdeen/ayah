import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/verse_key.dart';

enum VerseStatus {
  /// Recently memorized, still on short intervals.
  learning,

  /// Stable, on growing intervals.
  reviewing,

  /// Long intervals (≈ a month or more).
  mastered,
}

/// Memorization state of one ayah. Created when the user first memorizes
/// it; updated by the [ReviewScheduler] after each review.
final class VerseProgress extends Equatable {
  const VerseProgress({
    required this.key,
    required this.status,
    required this.stage,
    required this.repetitionCount,
    required this.lapses,
    required this.confidence,
    required this.difficulty,
    required this.memorizedAt,
    required this.lastReviewedAt,
    required this.nextReviewAt,
  });

  final VerseKey key;
  final VerseStatus status;

  /// Index into the scheduler's interval ladder.
  final int stage;

  /// Number of reviews done (any rating).
  final int repetitionCount;

  /// Number of times the user forgot it during review.
  final int lapses;

  /// 0..1 — how well the user knows it (drives UI hints, not scheduling).
  final double confidence;

  /// 0..1 — how hard this ayah is for this user.
  final double difficulty;

  final DateTime memorizedAt;
  final DateTime lastReviewedAt;
  final DateTime nextReviewAt;

  bool isDueBy(DateTime moment) => !nextReviewAt.isAfter(moment);

  VerseProgress copyWith({
    VerseStatus? status,
    int? stage,
    int? repetitionCount,
    int? lapses,
    double? confidence,
    double? difficulty,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
  }) =>
      VerseProgress(
        key: key,
        status: status ?? this.status,
        stage: stage ?? this.stage,
        repetitionCount: repetitionCount ?? this.repetitionCount,
        lapses: lapses ?? this.lapses,
        confidence: confidence ?? this.confidence,
        difficulty: difficulty ?? this.difficulty,
        memorizedAt: memorizedAt,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      );

  @override
  List<Object?> get props => [
        key,
        status,
        stage,
        repetitionCount,
        lapses,
        confidence,
        difficulty,
        memorizedAt,
        lastReviewedAt,
        nextReviewAt,
      ];
}
