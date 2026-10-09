import 'package:ayah/core/errors/failures.dart';
import 'package:ayah/core/extensions/date_time_x.dart';
import 'package:ayah/features/memorization/domain/entities/memorization_session.dart';
import 'package:ayah/features/onboarding/domain/entities/user_preferences.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = TestEnv();
    await env.savePrefs(const UserPreferences(startingPoint: StartingPoint.juzAmma));
  });

  group('GetDailyVerseUseCase', () {
    test('default goal gives exactly one ayah: the first on the path', () async {
      final plan = (await env.getDailyVerse()).valueOrNull!;
      expect(plan.remaining.map((v) => v.key), [const VerseKey(114, 1)]);
      expect(plan.goal, 1);
      expect(plan.isGoalReached, isFalse);
    });

    test('goal of 2 gives two ayahs', () async {
      await env.savePrefs(const UserPreferences(startingPoint: StartingPoint.juzAmma, dailyGoal: 2));
      final plan = (await env.getDailyVerse()).valueOrNull!;
      expect(plan.remaining.length, 2);
    });

    test('after memorizing today\'s ayah the goal is reached', () async {
      await env.markMemorized(const VerseKey(114, 1));
      final plan = (await env.getDailyVerse()).valueOrNull!;
      expect(plan.isGoalReached, isTrue);
      expect(plan.memorizedToday, 1);
      expect(plan.todaysVerse, isNull);
    });

    test('next day continues with the following ayah', () async {
      await env.markMemorized(const VerseKey(114, 1));
      env.clock.setNow(DateTime(2026, 3, 11, 8));
      final plan = (await env.getDailyVerse()).valueOrNull!;
      expect(plan.todaysVerse!.key, const VerseKey(114, 2));
    });

    test('missed days do not pile up new ayahs: still just the daily goal', () async {
      await env.markMemorized(const VerseKey(114, 1));
      env.clock.setNow(DateTime(2026, 3, 20, 8)); // 10 days later
      final plan = (await env.getDailyVerse()).valueOrNull!;
      expect(plan.remaining.length, 1);
    });

    test('"one more ayah" (extra) after goal is reached', () async {
      await env.markMemorized(const VerseKey(114, 1));
      final plan = (await env.getDailyVerse(extra: 1)).valueOrNull!;
      expect(plan.remaining.map((v) => v.key), [const VerseKey(114, 2)]);
    });

    test('propagates content failures (e.g. offline first run)', () async {
      env.quran.failWith = const NetworkFailure();
      final result = await env.getDailyVerse();
      expect(result.isSuccess, isFalse);
    });
  });

  group('MarkVerseMemorizedUseCase', () {
    test('creates progress due tomorrow and records today\'s activity', () async {
      final p = await env.markMemorized(const VerseKey(114, 1));
      expect(p.nextReviewAt, DateTime(2026, 3, 11));
      final day = await env.progressRepo.getDailyProgress(env.clock.now().dayKey);
      expect(day.newVersesMemorized, ['114:1']);
    });

    test('is idempotent: never resets an existing schedule', () async {
      final first = await env.markMemorized(const VerseKey(114, 1));
      env.clock.advance(const Duration(days: 5));
      final second = await env.markMemorized(const VerseKey(114, 1));
      expect(second, first);
      expect((await env.progressRepo.getAllProgress()).length, 1);
    });
  });

  group('StartMemorizationSession + SubmitRecallResult', () {
    Future<MemorizationSession> toRecall(MemorizationSession s) async {
      var x = s.startRepeating();
      while (!x.repetitionsSatisfied) {
        x = x.registerRepetition();
      }
      return x.startRecall();
    }

    test('full happy path persists the ayah and a session record', () async {
      final session = (await env.startSession()).valueOrNull!;
      final done = await env.submitRecall(await toRecall(session), selfReported: RecallOutcome.remembered);
      expect(done.isCompleted, isTrue);
      expect(await env.progressRepo.getProgress(const VerseKey(114, 1)), isNotNull);
    });

    test('forgetting first makes the ayah start a bit harder (difficulty seed)', () async {
      var s = (await env.startSession()).valueOrNull!;
      s = await env.submitRecall(await toRecall(s), selfReported: RecallOutcome.forgot);
      expect(s.step, MemorizationStep.listen);
      expect(await env.progressRepo.getProgress(const VerseKey(114, 1)), isNull);

      s = await env.submitRecall(await toRecall(s), selfReported: RecallOutcome.remembered);
      final p = (await env.progressRepo.getProgress(const VerseKey(114, 1)))!;
      expect(p.difficulty, greaterThan(env.scheduler.config.initialDifficulty));
    });

    test('submitting outside the recall step is a no-op', () async {
      final s = (await env.startSession()).valueOrNull!;
      final same = await env.submitRecall(s, selfReported: RecallOutcome.remembered);
      expect(same, s);
      expect(await env.progressRepo.getAllProgress(), isEmpty);
    });

    test('session is empty once today\'s goal is met', () async {
      await env.markMemorized(const VerseKey(114, 1));
      final s = (await env.startSession()).valueOrNull!;
      expect(s.isEmpty, isTrue);
    });
  });
}
