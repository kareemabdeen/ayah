import '../../../onboarding/domain/entities/user_preferences.dart';
import '../../../quran/domain/entities/surah.dart';
import '../../../quran/domain/entities/verse_key.dart';

/// The order in which surahs are memorized, derived from preferences.
///
/// Juz Amma is traversed the traditional way for memorizers: from An-Nas
/// (114) back to An-Naba (78), each surah from its first ayah. After the
/// chosen path, the rest of the mushaf follows from Al-Mulk's juz backwards
/// (77 → 2) so the user never "runs out".
abstract final class MemorizationPath {
  static const int _juzAmmaFirst = 78;
  static const int _lastSurah = 114;

  static List<int> get juzAmmaOrder => [for (var s = _lastSurah; s >= _juzAmmaFirst; s--) s];

  static List<int> surahOrder(UserPreferences prefs) {
    final head = switch (prefs.startingPoint) {
      StartingPoint.alFatihah || StartingPoint.letAyahChoose => [1, ...juzAmmaOrder],
      StartingPoint.juzAmma => juzAmmaOrder,
      StartingPoint.chosenSurah => [prefs.startingSurahId ?? 1, ...juzAmmaOrder],
    };
    final seen = <int>{};
    final ordered = <int>[
      for (final s in head)
        if (seen.add(s)) s,
    ];
    for (var s = _juzAmmaFirst - 1; s >= 1; s--) {
      if (seen.add(s)) ordered.add(s);
    }
    return ordered;
  }

  /// Next [count] ayahs not yet memorized, following [surahOrder].
  static List<VerseKey> nextUnmemorized({
    required List<int> surahOrder,
    required List<Surah> surahs,
    required Set<VerseKey> memorized,
    required int count,
  }) {
    if (count <= 0) return const [];
    final out = <VerseKey>[];
    for (final surahId in surahOrder) {
      final ayahCount = surahs[surahId - 1].ayahCount;
      for (var a = 1; a <= ayahCount; a++) {
        final key = VerseKey(surahId, a);
        if (memorized.contains(key)) continue;
        out.add(key);
        if (out.length == count) return out;
      }
    }
    return out;
  }
}
