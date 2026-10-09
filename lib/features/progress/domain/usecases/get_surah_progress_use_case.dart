import '../../../../core/utils/clock.dart';
import '../../../memorization/domain/services/memorization_path.dart';
import '../../../onboarding/domain/repositories/preferences_repository.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../entities/surah_progress.dart';
import '../entities/verse_progress.dart';
import '../repositories/progress_repository.dart';

final class GetSurahProgressUseCase {
  const GetSurahProgressUseCase({
    required ProgressRepository progress,
    required QuranRepository quran,
    required PreferencesRepository preferences,
    required Clock clock,
  })  : _progress = progress,
        _quran = quran,
        _preferences = preferences,
        _clock = clock;

  final ProgressRepository _progress;
  final QuranRepository _quran;
  final PreferencesRepository _preferences;
  final Clock _clock;

  Future<SurahProgress> call(int surahId) async {
    final all = await _progress.getAllProgress();
    return _build(surahId, all.where((p) => p.key.surahId == surahId), _clock.now());
  }

  Future<SurahProgressDetail> detail(int surahId) async {
    final now = _clock.now();
    final entries = (await _progress.getAllProgress()).where((p) => p.key.surahId == surahId).toList();
    final surah = _quran.getSurah(surahId);
    final states = List<AyahState>.filled(surah.ayahCount, AyahState.notStarted);
    for (final p in entries) {
      final i = p.key.ayahNumber - 1;
      if (i < 0 || i >= states.length) continue;
      states[i] = p.isDueBy(now) ? AyahState.needsReview : AyahState.memorized;
    }
    return SurahProgressDetail(summary: _build(surahId, entries, now), ayahStates: states);
  }

  /// Surahs on the user's path: started ones first (in path order), then
  /// the next not-started one so there's always "what's next".
  Future<List<SurahProgress>> onPath() async {
    final prefs = await _preferences.load();
    final all = await _progress.getAllProgress();
    final now = _clock.now();
    final bySurah = <int, List<VerseProgress>>{};
    for (final p in all) {
      bySurah.putIfAbsent(p.key.surahId, () => []).add(p);
    }

    final out = <SurahProgress>[];
    var addedNext = false;
    for (final id in MemorizationPath.surahOrder(prefs)) {
      final sp = _build(id, bySurah[id] ?? const [], now);
      if (sp.isStarted) {
        out.add(sp);
      } else if (!addedNext) {
        out.add(sp);
        addedNext = true;
      }
    }
    return out;
  }

  SurahProgress _build(int surahId, Iterable<VerseProgress> entries, DateTime now) {
    var memorized = 0;
    var due = 0;
    for (final p in entries) {
      memorized++;
      if (p.isDueBy(now)) due++;
    }
    return SurahProgress(surah: _quran.getSurah(surahId), memorizedCount: memorized, needsReviewCount: due);
  }
}
