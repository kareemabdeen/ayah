import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/result.dart';
import '../entities/memorization_session.dart';
import 'get_daily_verse_use_case.dart';

/// Creates a session over today's remaining ayahs (or one extra ayah).
final class StartMemorizationSessionUseCase {
  const StartMemorizationSessionUseCase({
    required GetDailyVerseUseCase getDailyVerse,
    required Clock clock,
    this.targetRepetitions = AppConstants.targetRepetitions,
  })  : _getDailyVerse = getDailyVerse,
        _clock = clock;

  final GetDailyVerseUseCase _getDailyVerse;
  final Clock _clock;
  final int targetRepetitions;

  Future<Result<MemorizationSession>> call({bool extraVerse = false}) async {
    final plan = await _getDailyVerse(extra: extraVerse ? 1 : 0);
    return plan.fold<Result<MemorizationSession>>(
      (f) => Err<MemorizationSession>(f),
      (p) => Success<MemorizationSession>(MemorizationSession(
        verses: p.remaining,
        targetRepetitions: targetRepetitions,
        startedAt: _clock.now(),
      )),
    );
  }
}
