import '../../../../core/utils/clock.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
import '../entities/memorization_session.dart';
import '../services/recitation_evaluator.dart';
import 'mark_verse_memorized_use_case.dart';

/// Evaluates a recall attempt, advances the session, persists a
/// memorized ayah, and stores a session record when the session ends.
final class SubmitRecallResultUseCase {
  const SubmitRecallResultUseCase({
    required RecitationEvaluator evaluator,
    required MarkVerseMemorizedUseCase markMemorized,
    required ProgressRepository progress,
    required Clock clock,
  })  : _evaluator = evaluator,
        _markMemorized = markMemorized,
        _progress = progress,
        _clock = clock;

  final RecitationEvaluator _evaluator;
  final MarkVerseMemorizedUseCase _markMemorized;
  final ProgressRepository _progress;
  final Clock _clock;

  Future<MemorizationSession> call(MemorizationSession session, {RecallOutcome? selfReported, String? recordingPath}) async {
    if (session.step != MemorizationStep.recall) return session;

    final result = await _evaluator.evaluate(
      RecitationAttempt(verse: session.current, selfReported: selfReported, recordingPath: recordingPath),
    );

    if (result.outcome == RecallOutcome.remembered) {
      await _markMemorized(session.current.key, attempts: session.attemptsForCurrent);
    }

    final next = session.applyRecall(result.outcome);

    if (next.isCompleted) {
      final now = _clock.now();
      await _progress.saveSessionRecord(MemorizationSessionRecord(
        id: 'memorize-${now.microsecondsSinceEpoch}',
        startedAt: session.startedAt,
        endedAt: now,
        verseIds: next.completedVerseIds,
        type: 'memorize',
      ));
    }
    return next;
  }
}
