import '../../../../core/utils/clock.dart';
import '../../../memorization/domain/entities/memorization_session.dart';
import '../repositories/progress_repository.dart';

final class RecordSessionUseCase {
  const RecordSessionUseCase({required ProgressRepository progress, required Clock clock})
      : _progress = progress,
        _clock = clock;

  final ProgressRepository _progress;
  final Clock _clock;

  Future<void> call({required String type, required DateTime startedAt, required List<String> verseIds}) {
    final now = _clock.now();
    return _progress.saveSessionRecord(MemorizationSessionRecord(
      id: '$type-${now.microsecondsSinceEpoch}',
      startedAt: startedAt,
      endedAt: now,
      verseIds: verseIds,
      type: type,
    ));
  }
}
