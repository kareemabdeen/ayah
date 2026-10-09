import 'package:ayah/core/extensions/date_time_x.dart';
import 'package:ayah/features/onboarding/domain/entities/user_preferences.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:ayah/features/review/domain/entities/review_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = TestEnv(now: DateTime(2026, 3, 1, 8), maxDailyReviews: 5);
    await env.savePrefs(const UserPreferences(startingPoint: StartingPoint.juzAmma));
  });

  Future<void> memorize(List<VerseKey> keys) async {
    for (final k in keys) {
      await env.markMemorized(k);
    }
  }

  test('nothing is due on the day an ayah is memorized', () async {
    await memorize([const VerseKey(114, 1)]);
    final queue = (await env.getTodayReviews()).valueOrNull!;
    expect(queue.isEmpty, isTrue);
  });

  test('yesterday\'s ayah is due today', () async {
    await memorize([const VerseKey(114, 1)]);
    env.clock.setNow(DateTime(2026, 3, 2, 7));
    final queue = (await env.getTodayReviews()).valueOrNull!;
    expect(queue.items.single.verse.key, const VerseKey(114, 1));
  });

  test('returning after a break: capped workload + welcome-back flag', () async {
    await memorize([for (var a = 1; a <= 6; a++) VerseKey(114, a), for (var a = 1; a <= 5; a++) VerseKey(113, a)]);
    env.clock.setNow(DateTime(2026, 3, 15, 9)); // two weeks away
    final queue = (await env.getTodayReviews()).valueOrNull!;
    expect(queue.items.length, 5);
    expect(queue.totalDue, 11);
    expect(queue.deferredCount, 6);
    expect(queue.isReturningAfterBreak, isTrue);
  });

  test('no welcome-back the day after activity', () async {
    await memorize([const VerseKey(114, 1)]);
    env.clock.setNow(DateTime(2026, 3, 2, 9));
    expect((await env.getTodayReviews()).valueOrNull!.isReturningAfterBreak, isFalse);
  });

  test('submitting a review reschedules and counts toward today\'s budget', () async {
    await memorize([for (var a = 1; a <= 6; a++) VerseKey(114, a)]);
    env.clock.setNow(DateTime(2026, 3, 2, 9));
    final queue = (await env.getTodayReviews()).valueOrNull!;
    expect(queue.items.length, 5);

    final updated = await env.submitReview(queue.items.first, ReviewRating.good);
    expect(updated.progress.nextReviewAt, DateTime(2026, 3, 5));
    final day = await env.progressRepo.getDailyProgress(env.clock.now().dayKey);
    expect(day.reviewsCompleted, 1);

    // Reopening the review the same day only offers the remaining budget.
    final again = (await env.getTodayReviews()).valueOrNull!;
    expect(again.items.length, 4);
  });

  test('in-session retries do not consume the daily budget', () async {
    await memorize([const VerseKey(114, 1)]);
    env.clock.setNow(DateTime(2026, 3, 2, 9));
    final item = (await env.getTodayReviews()).valueOrNull!.items.single;
    final forgotten = await env.submitReview(item, ReviewRating.forgot);
    await env.submitReview(forgotten, ReviewRating.hard, countsTowardDailyLimit: false);
    final day = await env.progressRepo.getDailyProgress(env.clock.now().dayKey);
    expect(day.reviewsCompleted, 1);
  });

  test('surah test returns all memorized ayahs of that surah in order, uncapped', () async {
    await memorize([const VerseKey(114, 3), const VerseKey(114, 1), const VerseKey(114, 2), const VerseKey(113, 1)]);
    final queue = (await env.getSurahTest(114)).valueOrNull!;
    expect(queue.items.map((i) => i.verse.ayahNumber), [1, 2, 3]);
  });
}
