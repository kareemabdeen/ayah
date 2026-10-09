import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/verse.dart';
import '../entities/memorization_session.dart';

/// Everything an evaluator might use. MVP only fills [selfReported];
/// later versions add a recording path for speech-to-text / tajweed models.
final class RecitationAttempt extends Equatable {
  const RecitationAttempt({required this.verse, this.selfReported, this.recordingPath});

  final Verse verse;
  final RecallOutcome? selfReported;
  final String? recordingPath;

  @override
  List<Object?> get props => [verse, selfReported, recordingPath];
}

final class RecitationResult extends Equatable {
  const RecitationResult({required this.outcome, this.score, this.missedWordIndexes = const []});

  final RecallOutcome outcome;

  /// 0..1 when an automatic evaluator is used.
  final double? score;

  /// Word positions the evaluator thinks were missed (for future hints).
  final List<int> missedWordIndexes;

  @override
  List<Object?> get props => [outcome, score, missedWordIndexes];
}

/// Decides how a recall attempt went. The UI never knows which
/// implementation is active.
abstract interface class RecitationEvaluator {
  /// Whether this evaluator needs the user to record audio.
  bool get requiresRecording;

  Future<RecitationResult> evaluate(RecitationAttempt attempt);
}

/// MVP: trust the user's own judgement.
final class SelfAssessmentEvaluator implements RecitationEvaluator {
  const SelfAssessmentEvaluator();

  @override
  bool get requiresRecording => false;

  @override
  Future<RecitationResult> evaluate(RecitationAttempt attempt) async =>
      RecitationResult(outcome: attempt.selfReported ?? RecallOutcome.needAnotherTry);
}
