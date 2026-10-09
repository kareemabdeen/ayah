import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/surah.dart';

final class SurahProgress extends Equatable {
  const SurahProgress({
    required this.surah,
    required this.memorizedCount,
    required this.needsReviewCount,
  });

  final Surah surah;

  /// Ayahs memorized at least once (includes those needing review).
  final int memorizedCount;

  /// Memorized ayahs currently due for review.
  final int needsReviewCount;

  int get totalCount => surah.ayahCount;
  int get notStartedCount => totalCount - memorizedCount;
  int get strongCount => memorizedCount - needsReviewCount;
  bool get isComplete => memorizedCount >= totalCount;
  bool get isStarted => memorizedCount > 0;
  double get fraction => totalCount == 0 ? 0 : memorizedCount / totalCount;

  @override
  List<Object?> get props => [surah, memorizedCount, needsReviewCount];
}

enum AyahState { notStarted, memorized, needsReview }

/// Per-ayah view of a surah for the Surah progress screen.
final class SurahProgressDetail extends Equatable {
  const SurahProgressDetail({required this.summary, required this.ayahStates});

  final SurahProgress summary;

  /// Index 0 = ayah 1.
  final List<AyahState> ayahStates;

  @override
  List<Object?> get props => [summary, ayahStates];
}
