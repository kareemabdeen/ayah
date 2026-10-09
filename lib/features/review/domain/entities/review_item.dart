import 'package:equatable/equatable.dart';

import '../../../progress/domain/entities/verse_progress.dart';
import '../../../quran/domain/entities/verse.dart';

final class ReviewItem extends Equatable {
  const ReviewItem({required this.verse, required this.progress});

  final Verse verse;
  final VerseProgress progress;

  ReviewItem withProgress(VerseProgress p) => ReviewItem(verse: verse, progress: p);

  @override
  List<Object?> get props => [verse, progress];
}

/// Today's review workload.
final class ReviewQueue extends Equatable {
  const ReviewQueue({
    required this.items,
    required this.totalDue,
    required this.isReturningAfterBreak,
    this.startedAt,
  });

  static const empty = ReviewQueue(items: [], totalDue: 0, isReturningAfterBreak: false);

  /// When this queue was built — used as the session start for history.
  final DateTime? startedAt;

  /// Capped to the daily maximum.
  final List<ReviewItem> items;

  /// All overdue ayahs, including those deferred to later days.
  final int totalDue;

  /// True when the user comes back after missing days ("Welcome back").
  final bool isReturningAfterBreak;

  bool get isEmpty => items.isEmpty;
  int get deferredCount => totalDue - items.length;

  @override
  List<Object?> get props => [items, totalDue, isReturningAfterBreak, startedAt];
}
