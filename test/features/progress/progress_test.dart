import 'package:ayah/features/onboarding/domain/entities/user_preferences.dart';
import 'package:ayah/features/progress/domain/entities/daily_progress.dart';
import 'package:ayah/features/progress/domain/entities/surah_progress.dart';
import 'package:ayah/features/progress/domain/services/activity_stats.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_env.dart';

void main() {
  group('ActivityStats', () {
    final now = DateTime(2026, 3, 10, 9);
    DailyProgress day(String key, {int reviews = 1}) => DailyProgress(dayKey: key, reviewsCompleted: reviews);

    test('active days count only days with activity and never "break"', () {
      final days = [day('2026-03-01'), day('2026-03-02', reviews: 0), day('2026-03-08')];
      expect(ActivityStats.activeDays(days), 2);
    });

    test('days since last activity ignores today', () {
      final days = [day('2026-03-05'), day('2026-03-10')];
      expect(ActivityStats.daysSinceLastActivity(days, now), 5);
    });

    test('null when there is no earlier activity', () {
      expect(ActivityStats.daysSinceLastActivity(const [], now), isNull);
    });

    test('returning after break threshold', () {
      expect(ActivityStats.isReturningAfterBreak([day('2026-03-09')], now, afterDays: 2), isFalse);
      expect(ActivityStats.isReturningAfterBreak([day('2026-03-08')], now, afterDays: 2), isTrue);
    });
  });

  group('progress use cases', () {
    late TestEnv env;

    setUp(() async {
      env = TestEnv(now: DateTime(2026, 3, 1, 8));
      await env.savePrefs(const UserPreferences(startingPoint: StartingPoint.juzAmma));
    });

    test('user summary: memorized, due, active days', () async {
      await env.markMemorized(const VerseKey(114, 1));
      env.clock.setNow(DateTime(2026, 3, 2, 8));
      await env.markMemorized(const VerseKey(114, 2));
      final summary = await env.getUserProgress();
      expect(summary.memorizedCount, 2);
      expect(summary.dueReviewCount, 1); // 114:1 due today; 114:2 due tomorrow
      expect(summary.activeDays, 2);
      expect(summary.daysSinceLastActivity, 0);
    });

    test('surah progress counts memorized / needs review / not started', () async {
      await env.markMemorized(const VerseKey(114, 1));
      await env.markMemorized(const VerseKey(114, 2));
      env.clock.setNow(DateTime(2026, 3, 2, 8));
      await env.markMemorized(const VerseKey(114, 3));

      final p = await env.getSurahProgress(114);
      expect(p.memorizedCount, 3);
      expect(p.needsReviewCount, 2);
      expect(p.notStartedCount, 3);
      expect(p.isComplete, isFalse);

      final detail = await env.getSurahProgress.detail(114);
      expect(detail.ayahStates, [
        AyahState.needsReview,
        AyahState.needsReview,
        AyahState.memorized,
        AyahState.notStarted,
        AyahState.notStarted,
        AyahState.notStarted,
      ]);
    });

    test('surah completion is detected', () async {
      for (var a = 1; a <= 6; a++) {
        await env.markMemorized(VerseKey(114, a));
      }
      expect((await env.getSurahProgress(114)).isComplete, isTrue);
    });

    test('progress list: started surahs plus the next one on the path', () async {
      await env.markMemorized(const VerseKey(114, 1));
      final list = await env.getSurahProgress.onPath();
      expect(list.map((p) => p.surah.id), [114, 113]);
    });
  });
}
