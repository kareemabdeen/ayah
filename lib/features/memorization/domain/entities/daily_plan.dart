import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/verse.dart';

/// Today's new-ayah task.
final class DailyPlan extends Equatable {
  const DailyPlan({
    required this.goal,
    required this.memorizedToday,
    required this.remaining,
    required this.isQuranComplete,
  });

  final int goal;
  final int memorizedToday;

  /// Ayahs still to memorize today, in order (first = "آية اليوم").
  final List<Verse> remaining;

  /// Every ayah on the path is memorized.
  final bool isQuranComplete;

  bool get isGoalReached => remaining.isEmpty;
  Verse? get todaysVerse => remaining.isEmpty ? null : remaining.first;

  @override
  List<Object?> get props => [goal, memorizedToday, remaining, isQuranComplete];
}
