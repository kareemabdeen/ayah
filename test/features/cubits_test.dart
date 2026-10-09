import 'package:ayah/core/errors/failures.dart';
import 'package:ayah/features/home/presentation/cubit/home_cubit.dart';
import 'package:ayah/features/memorization/domain/entities/memorization_session.dart';
import 'package:ayah/features/memorization/presentation/cubit/memorization_cubit.dart';
import 'package:ayah/features/onboarding/domain/entities/user_preferences.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:ayah/features/review/domain/entities/review_schedule.dart';
import 'package:ayah/features/review/presentation/cubit/review_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = TestEnv(now: DateTime(2026, 3, 1, 8));
    await env.savePrefs(const UserPreferences(startingPoint: StartingPoint.juzAmma));
  });

  MemorizationCubit memorizationCubit() => MemorizationCubit(
        startSession: env.startSession,
        submitRecall: env.submitRecall,
        playAudio: env.playAudio,
        controlPlayback: env.controlPlayback,
      );

  ReviewCubit reviewCubit() => ReviewCubit(
        getTodayItems: env.getTodayReviews,
        getSurahTestItems: env.getSurahTest,
        submitResult: env.submitReview,
        recordSession: env.recordSession,
        playAudio: env.playAudio,
        controlPlayback: env.controlPlayback,
      );

  group('MemorizationCubit', () {
    Future<void> repeatAll(MemorizationCubit c) async {
      c.goToRepeat();
      while (!c.state.session!.repetitionsSatisfied) {
        await c.registerRepetition();
      }
      await c.goToRecall();
    }

    test('listen → repeat → recall → success, and audio auto-plays on listen', () async {
      final c = memorizationCubit();
      await c.start();
      expect(c.state.status, MemorizationStatus.listening);
      expect(env.audio.played, isNotEmpty);

      c.goToRepeat();
      expect(c.state.status, MemorizationStatus.repeating);
      while (!c.state.session!.repetitionsSatisfied) {
        await c.registerRepetition();
      }
      await c.goToRecall();
      expect(c.state.status, MemorizationStatus.recalling);

      await c.submitRecall(RecallOutcome.remembered);
      expect(c.state.status, MemorizationStatus.success);
      expect(await env.progressRepo.getProgress(const VerseKey(114, 1)), isNotNull);
      await c.close();
    });

    test('"I forgot" shows the supportive moment, replays audio, then returns to listening', () async {
      final c = memorizationCubit();
      await c.start();
      await repeatAll(c);
      final playsBefore = env.audio.played.length;

      await c.submitRecall(RecallOutcome.forgot);
      expect(c.state.status, MemorizationStatus.forgotSupport);
      expect(env.audio.played.length, playsBefore + 1);

      c.continueAfterForgot();
      expect(c.state.status, MemorizationStatus.listening);
      await c.close();
    });

    test('"I need another try" returns to repeating with one more repetition', () async {
      final c = memorizationCubit();
      await c.start();
      await repeatAll(c);
      await c.submitRecall(RecallOutcome.needAnotherTry);
      expect(c.state.status, MemorizationStatus.repeating);
      expect(c.state.session!.repetitionsSatisfied, isFalse);
      await c.close();
    });

    test('hints are capped', () async {
      final c = memorizationCubit();
      await c.start();
      await repeatAll(c);
      for (var i = 0; i < 10; i++) {
        c.showHint();
      }
      expect(c.state.hintWords, MemorizationState.maxHintWords);
      await c.close();
    });

    test('empty when today\'s goal is already met', () async {
      await env.markMemorized(const VerseKey(114, 1));
      final c = memorizationCubit();
      await c.start();
      expect(c.state.status, MemorizationStatus.empty);
      await c.close();
    });

    test('failure state when content cannot load', () async {
      env.quran.failWith = const NetworkFailure();
      final c = memorizationCubit();
      await c.start();
      expect(c.state.status, MemorizationStatus.failure);
      expect(c.state.failure, isA<NetworkFailure>());
      await c.close();
    });

    test('closing stops audio', () async {
      final c = memorizationCubit();
      await c.start();
      await c.close();
      expect(env.audio.stopCount, greaterThan(0));
    });
  });

  group('ReviewCubit', () {
    setUp(() async {
      await env.markMemorized(const VerseKey(114, 1));
      await env.markMemorized(const VerseKey(114, 2));
      env.clock.setNow(DateTime(2026, 3, 2, 9));
    });

    test('intro → recall (hidden) → reveal → rate → finished', () async {
      final c = reviewCubit();
      await c.load();
      expect(c.state.status, ReviewStatus.intro);
      expect(c.state.items.length, 2);

      c.begin();
      expect(c.state.status, ReviewStatus.recalling);
      c.reveal();
      expect(c.state.status, ReviewStatus.revealed);
      await c.rate(ReviewRating.easy);
      expect(c.state.status, ReviewStatus.recalling);
      c.reveal();
      await c.rate(ReviewRating.good);
      expect(c.state.status, ReviewStatus.finished);
      await c.close();
    });

    test('a forgotten ayah comes back once at the end of the session', () async {
      final c = reviewCubit();
      await c.load();
      c
        ..begin()
        ..reveal();
      await c.rate(ReviewRating.forgot);
      expect(c.state.items.length, 3);
      expect(c.state.showForgotNote, isTrue);
      expect(c.state.items.last.verse.key, c.state.items.first.verse.key);

      c.reveal();
      await c.rate(ReviewRating.good);
      c.reveal();
      await c.rate(ReviewRating.forgot); // forgotten again: not re-added twice
      expect(c.state.status, ReviewStatus.finished);
      await c.close();
    });

    test('empty when nothing is due', () async {
      env.clock.setNow(DateTime(2026, 3, 1, 10));
      final c = reviewCubit();
      await c.load();
      expect(c.state.status, ReviewStatus.empty);
      await c.close();
    });

    test('rating is ignored until the ayah is revealed', () async {
      final c = reviewCubit();
      await c.load();
      c.begin();
      await c.rate(ReviewRating.easy);
      expect(c.state.index, 0);
      await c.close();
    });
  });

  group('HomeCubit', () {
    HomeCubit homeCubit() => HomeCubit(
          getDailyVerse: env.getDailyVerse,
          getUserProgress: env.getUserProgress,
          playAudio: env.playAudio,
          controlPlayback: env.controlPlayback,
        );

    test('ready with today\'s ayah', () async {
      final c = homeCubit();
      await c.load();
      expect(c.state.status, HomeStatus.ready);
      expect(c.state.plan!.todaysVerse!.key, const VerseKey(114, 1));
      expect(c.state.isWelcomeBack, isFalse);
      await c.close();
    });

    test('welcome back after missed days', () async {
      await env.markMemorized(const VerseKey(114, 1));
      env.clock.setNow(DateTime(2026, 3, 9, 9));
      final c = homeCubit();
      await c.load();
      expect(c.state.isWelcomeBack, isTrue);
      await c.close();
    });

    test('failure when offline on first run', () async {
      env.quran.failWith = const NetworkFailure();
      final c = homeCubit();
      await c.load();
      expect(c.state.status, HomeStatus.failure);
      await c.close();
    });
  });
}
