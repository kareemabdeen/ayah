import 'package:ayah/features/memorization/domain/services/memorization_path.dart';
import 'package:ayah/features/onboarding/domain/entities/user_preferences.dart';
import 'package:ayah/features/quran/data/datasources/surah_metadata.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('surahOrder', () {
    test('Juz Amma goes An-Nas (114) back to An-Naba (78)', () {
      final order = MemorizationPath.surahOrder(const UserPreferences(startingPoint: StartingPoint.juzAmma));
      expect(order.take(3), [114, 113, 112]);
      expect(order[36], 78);
    });

    test('Al-Fatihah and "let Ayah choose" start with 1 then Juz Amma', () {
      for (final sp in [StartingPoint.alFatihah, StartingPoint.letAyahChoose]) {
        final order = MemorizationPath.surahOrder(UserPreferences(startingPoint: sp));
        expect(order.take(3), [1, 114, 113]);
      }
    });

    test('chosen surah comes first and is not repeated later', () {
      final order = MemorizationPath.surahOrder(
        const UserPreferences(startingPoint: StartingPoint.chosenSurah, startingSurahId: 112),
      );
      expect(order.first, 112);
      expect(order.where((s) => s == 112).length, 1);
    });

    test('every path covers all 114 surahs exactly once', () {
      for (final sp in StartingPoint.values) {
        final order = MemorizationPath.surahOrder(UserPreferences(startingPoint: sp, startingSurahId: 67));
        expect(order.length, 114, reason: sp.name);
        expect(order.toSet().length, 114, reason: sp.name);
      }
    });
  });

  group('nextUnmemorized (daily verse selection)', () {
    final order = MemorizationPath.surahOrder(const UserPreferences(startingPoint: StartingPoint.juzAmma));

    test('starts at the first ayah of the first surah', () {
      final next = MemorizationPath.nextUnmemorized(surahOrder: order, surahs: kSurahMetadata, memorized: {}, count: 1);
      expect(next, [const VerseKey(114, 1)]);
    });

    test('skips memorized ayahs and continues in order', () {
      final next = MemorizationPath.nextUnmemorized(
        surahOrder: order,
        surahs: kSurahMetadata,
        memorized: {const VerseKey(114, 1), const VerseKey(114, 2)},
        count: 2,
      );
      expect(next, [const VerseKey(114, 3), const VerseKey(114, 4)]);
    });

    test('crosses into the next surah on the path', () {
      final memorized = {for (var a = 1; a <= 5; a++) VerseKey(114, a)};
      final next = MemorizationPath.nextUnmemorized(
        surahOrder: order,
        surahs: kSurahMetadata,
        memorized: memorized,
        count: 3,
      );
      expect(next, [const VerseKey(114, 6), const VerseKey(113, 1), const VerseKey(113, 2)]);
    });

    test('fills gaps (an ayah skipped earlier comes first)', () {
      final next = MemorizationPath.nextUnmemorized(
        surahOrder: order,
        surahs: kSurahMetadata,
        memorized: {const VerseKey(114, 1), const VerseKey(114, 3)},
        count: 1,
      );
      expect(next, [const VerseKey(114, 2)]);
    });

    test('count 0 returns nothing', () {
      expect(
        MemorizationPath.nextUnmemorized(surahOrder: order, surahs: kSurahMetadata, memorized: {}, count: 0),
        isEmpty,
      );
    });

    test('returns empty when everything is memorized', () {
      final all = <VerseKey>{
        for (final s in kSurahMetadata)
          for (var a = 1; a <= s.ayahCount; a++) VerseKey(s.id, a),
      };
      expect(
        MemorizationPath.nextUnmemorized(surahOrder: order, surahs: kSurahMetadata, memorized: all, count: 1),
        isEmpty,
      );
    });
  });
}
