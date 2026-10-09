import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/verse.dart';

enum MemorizationStep { listen, repeat, recall, completed }

enum RecallOutcome { remembered, needAnotherTry, forgot }

/// Pure, immutable state machine for one memorization session.
///
///   listen → repeat (N times) → recall ─ remembered ─→ next verse / completed
///                    ↑             ├─ needAnotherTry → repeat (1 more)
///                    └── listen ←──┴─ forgot (gentle restart)
///
/// No I/O here — persistence happens in use cases. Fully unit-testable.
final class MemorizationSession extends Equatable {
  const MemorizationSession({
    required this.verses,
    required this.targetRepetitions,
    required this.startedAt,
    this.index = 0,
    this.step = MemorizationStep.listen,
    this.repetitionsDone = 0,
    this.attemptsForCurrent = 1,
    this.completedVerseIds = const [],
  }) : assert(targetRepetitions >= 1);

  final List<Verse> verses;
  final int targetRepetitions;
  final DateTime startedAt;
  final int index;
  final MemorizationStep step;
  final int repetitionsDone;

  /// 1 on first try; grows each time the user forgets. Seeds difficulty.
  final int attemptsForCurrent;
  final List<String> completedVerseIds;

  bool get isEmpty => verses.isEmpty;
  bool get isCompleted => step == MemorizationStep.completed;
  Verse get current => verses[index];
  int get total => verses.length;
  bool get hasMoreVerses => index + 1 < verses.length;
  bool get repetitionsSatisfied => repetitionsDone >= targetRepetitions;

  MemorizationSession startRepeating() => _copy(step: MemorizationStep.repeat);

  MemorizationSession registerRepetition() {
    if (step != MemorizationStep.repeat) return this;
    final next = repetitionsDone + 1;
    return _copy(repetitionsDone: next > targetRepetitions ? targetRepetitions : next);
  }

  MemorizationSession startRecall() => _copy(step: MemorizationStep.recall);

  /// Applies a recall outcome and returns the next session state.
  MemorizationSession applyRecall(RecallOutcome outcome) => switch (outcome) {
        RecallOutcome.remembered => _advance(),
        RecallOutcome.needAnotherTry => _copy(
            step: MemorizationStep.repeat,
            repetitionsDone: targetRepetitions - 1,
            attemptsForCurrent: attemptsForCurrent + 1,
          ),
        RecallOutcome.forgot => _copy(
            step: MemorizationStep.listen,
            repetitionsDone: 0,
            attemptsForCurrent: attemptsForCurrent + 1,
          ),
      };

  MemorizationSession _advance() {
    final done = [...completedVerseIds, current.id];
    if (!hasMoreVerses) {
      return _copy(step: MemorizationStep.completed, completedVerseIds: done);
    }
    return _copy(
      index: index + 1,
      step: MemorizationStep.listen,
      repetitionsDone: 0,
      attemptsForCurrent: 1,
      completedVerseIds: done,
    );
  }

  MemorizationSession _copy({
    int? index,
    MemorizationStep? step,
    int? repetitionsDone,
    int? attemptsForCurrent,
    List<String>? completedVerseIds,
  }) =>
      MemorizationSession(
        verses: verses,
        targetRepetitions: targetRepetitions,
        startedAt: startedAt,
        index: index ?? this.index,
        step: step ?? this.step,
        repetitionsDone: repetitionsDone ?? this.repetitionsDone,
        attemptsForCurrent: attemptsForCurrent ?? this.attemptsForCurrent,
        completedVerseIds: completedVerseIds ?? this.completedVerseIds,
      );

  @override
  List<Object?> get props =>
      [verses, targetRepetitions, startedAt, index, step, repetitionsDone, attemptsForCurrent, completedVerseIds];
}

/// Persisted summary of a finished session (history / future analytics).
final class MemorizationSessionRecord extends Equatable {
  const MemorizationSessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.verseIds,
    required this.type,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<String> verseIds;

  /// 'memorize' | 'review' | 'surah_test' | 'chain'
  final String type;

  Duration get duration => endedAt.difference(startedAt);

  @override
  List<Object?> get props => [id, startedAt, endedAt, verseIds, type];
}
