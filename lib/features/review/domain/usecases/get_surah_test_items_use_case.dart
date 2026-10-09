import '../../../../core/utils/clock.dart';
import '../../../../core/utils/result.dart';
import '../../../progress/domain/repositories/progress_repository.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/review_item.dart';

/// "Full Surah Test": every memorized ayah of a surah, in mushaf order,
/// uncapped. Ratings still feed the scheduler.
final class GetSurahTestItemsUseCase {
  const GetSurahTestItemsUseCase({
    required ProgressRepository progress,
    required QuranRepository quran,
    required Clock clock,
  })  : _progress = progress,
        _quran = quran,
        _clock = clock;

  final ProgressRepository _progress;
  final QuranRepository _quran;
  final Clock _clock;

  Future<Result<ReviewQueue>> call(int surahId) async {
    final progress = (await _progress.getAllProgress()).where((p) => p.key.surahId == surahId).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (progress.isEmpty) return const Success(ReviewQueue.empty);

    final verses = await _quran.getVerses([for (final p in progress) p.key]);
    return verses.fold<Result<ReviewQueue>>(
      (f) => Err<ReviewQueue>(f),
      (list) => Success<ReviewQueue>(ReviewQueue(
        items: [for (var i = 0; i < list.length; i++) ReviewItem(verse: list[i], progress: progress[i])],
        totalDue: list.length,
        isReturningAfterBreak: false,
        startedAt: _clock.now(),
      )),
    );
  }
}
