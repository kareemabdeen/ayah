import 'package:equatable/equatable.dart';

/// How the user felt recalling an ayah.
enum ReviewRating {
  forgot,
  hard,

  /// "Okay" in the UI.
  good,
  easy,
}

/// Output of the scheduler for one rating: when the ayah comes back.
final class ReviewSchedule extends Equatable {
  const ReviewSchedule({required this.stage, required this.nextReviewAt, required this.interval});

  final int stage;
  final DateTime nextReviewAt;
  final Duration interval;

  @override
  List<Object?> get props => [stage, nextReviewAt, interval];
}

/// All tunables of the default ladder algorithm.
///
/// Defaults reproduce the product spec for a fresh ayah:
/// forgot → minutes, hard → 1 day, okay → 3 days, easy → 7 days,
/// then 14 → 30 → 60 → 120 days as it keeps succeeding.
final class ReviewSchedulerConfig extends Equatable {
  const ReviewSchedulerConfig({
    this.ladderDays = const [1, 3, 7, 14, 30, 60, 120],
    this.forgotDelay = const Duration(minutes: 10),
    this.easyStageJump = 2,
    this.goodStageJump = 1,
    this.hardStageDrop = 1,
    this.learningBelowStage = 2,
    this.masteredFromDays = 30,
    this.initialDifficulty = 0.3,
    this.difficultyPerExtraAttempt = 0.1,
    this.difficultyOnForgot = 0.15,
    this.difficultyOnHard = 0.05,
    this.difficultyOnGood = -0.02,
    this.difficultyOnEasy = -0.08,
  });

  /// Must be non-empty and ascending (checked by [LadderReviewScheduler]).
  final List<int> ladderDays;
  final Duration forgotDelay;
  final int easyStageJump;
  final int goodStageJump;
  final int hardStageDrop;
  final int learningBelowStage;
  final int masteredFromDays;
  final double initialDifficulty;
  final double difficultyPerExtraAttempt;
  final double difficultyOnForgot;
  final double difficultyOnHard;
  final double difficultyOnGood;
  final double difficultyOnEasy;

  int get maxStage => ladderDays.length - 1;

  @override
  List<Object?> get props => [
        ladderDays,
        forgotDelay,
        easyStageJump,
        goodStageJump,
        hardStageDrop,
        learningBelowStage,
        masteredFromDays,
        initialDifficulty,
        difficultyPerExtraAttempt,
        difficultyOnForgot,
        difficultyOnHard,
        difficultyOnGood,
        difficultyOnEasy,
      ];
}
