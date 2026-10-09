import 'package:ayah/core/extensions/date_time_x.dart';
import 'package:ayah/features/progress/domain/entities/verse_progress.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:ayah/features/review/domain/entities/review_schedule.dart';
import 'package:ayah/features/review/domain/services/review_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scheduler = LadderReviewScheduler();
  const key = VerseKey(67, 1);
  final memorizedAt = DateTime(2026, 3, 10, 21, 45); // evening session
  final midnightOf10th = DateTime(2026, 3, 10);

  VerseProgress fresh() => scheduler.initial(key, memorizedAt);

  group('initial', () {
    test('first review is tomorrow at local midnight', () {
      final p = fresh();
      expect(p.nextReviewAt, DateTime(2026, 3, 11));
      expect(p.stage, 0);
      expect(p.status, VerseStatus.learning);
      expect(p.repetitionCount, 0);
      expect(p.lapses, 0);
      expect(p.memorizedAt, memorizedAt);
    });

    test('extra attempts while memorizing raise initial difficulty', () {
      final easy = scheduler.initial(key, memorizedAt);
      final struggled = scheduler.initial(key, memorizedAt, attempts: 3);
      expect(struggled.difficulty, greaterThan(easy.difficulty));
      expect(struggled.difficulty, closeTo(0.5, 1e-9));
    });

    test('difficulty is clamped to 1', () {
      expect(scheduler.initial(key, memorizedAt, attempts: 100).difficulty, 1.0);
    });
  });

  group('spec intervals from a fresh ayah', () {
    final reviewAt = DateTime(2026, 3, 11, 9, 30);

    test('forgot → again in minutes, not days', () {
      final s = scheduler.schedule(fresh(), ReviewRating.forgot, reviewAt);
      expect(s.nextReviewAt, reviewAt.add(const Duration(minutes: 10)));
      expect(s.stage, 0);
    });

    test('hard → 1 day', () {
      expect(scheduler.schedule(fresh(), ReviewRating.hard, reviewAt).nextReviewAt, DateTime(2026, 3, 12));
    });

    test('okay (good) → 3 days', () {
      expect(scheduler.schedule(fresh(), ReviewRating.good, reviewAt).nextReviewAt, DateTime(2026, 3, 14));
    });

    test('easy → 7 days', () {
      expect(scheduler.schedule(fresh(), ReviewRating.easy, reviewAt).nextReviewAt, DateTime(2026, 3, 18));
    });
  });

  group('progression', () {
    test('consistent "good" walks the ladder 3 → 7 → 14 → 30 → 60 → 120 days', () {
      var p = fresh();
      var now = DateTime(2026, 3, 11, 9);
      final intervals = <int>[];
      for (var i = 0; i < 6; i++) {
        p = scheduler.apply(p, ReviewRating.good, now);
        intervals.add(p.nextReviewAt.calendarDaysSince(now));
        now = p.nextReviewAt.add(const Duration(hours: 9));
      }
      expect(intervals, [3, 7, 14, 30, 60, 120]);
    });

    test('caps at the last ladder step', () {
      var p = fresh();
      final now = DateTime(2026, 3, 11, 9);
      for (var i = 0; i < 20; i++) {
        p = scheduler.apply(p, ReviewRating.easy, now);
      }
      expect(p.stage, const ReviewSchedulerConfig().maxStage);
      expect(p.nextReviewAt, DateTime(2026, 3, 11 + 120));
    });

    test('hard steps back one stage but never below 0', () {
      var p = fresh();
      final now = DateTime(2026, 3, 11, 9);
      p = scheduler.apply(p, ReviewRating.easy, now); // stage 2
      p = scheduler.apply(p, ReviewRating.hard, now);
      expect(p.stage, 1);
      p = scheduler.apply(p, ReviewRating.hard, now);
      p = scheduler.apply(p, ReviewRating.hard, now);
      expect(p.stage, 0);
    });

    test('forgot resets stage, counts a lapse, zeroes confidence', () {
      var p = fresh();
      final now = DateTime(2026, 3, 11, 9);
      p = scheduler.apply(p, ReviewRating.easy, now);
      p = scheduler.apply(p, ReviewRating.good, now);
      final before = p.difficulty;
      p = scheduler.apply(p, ReviewRating.forgot, now);
      expect(p.stage, 0);
      expect(p.lapses, 1);
      expect(p.confidence, 0);
      expect(p.difficulty, greaterThan(before));
      expect(p.status, VerseStatus.learning);
    });

    test('every review increments repetitionCount and sets lastReviewedAt', () {
      final now = DateTime(2026, 3, 11, 9);
      final p = scheduler.apply(fresh(), ReviewRating.hard, now);
      expect(p.repetitionCount, 1);
      expect(p.lastReviewedAt, now);
    });

    test('memorizedAt never changes', () {
      final p = scheduler.apply(fresh(), ReviewRating.good, DateTime(2026, 4, 1));
      expect(p.memorizedAt, memorizedAt);
    });
  });

  group('status', () {
    test('learning → reviewing → mastered as intervals grow', () {
      var p = fresh();
      final now = DateTime(2026, 3, 11, 9);
      expect(p.status, VerseStatus.learning);
      p = scheduler.apply(p, ReviewRating.good, now); // stage 1, 3d
      expect(p.status, VerseStatus.learning);
      p = scheduler.apply(p, ReviewRating.good, now); // stage 2, 7d
      expect(p.status, VerseStatus.reviewing);
      p = scheduler.apply(p, ReviewRating.good, now); // 14d
      p = scheduler.apply(p, ReviewRating.good, now); // 30d
      expect(p.status, VerseStatus.mastered);
    });
  });

  group('confidence & difficulty', () {
    test('confidence rises with stage and stays within 0..1', () {
      var p = fresh();
      final now = DateTime(2026, 3, 11, 9);
      var last = p.confidence;
      for (var i = 0; i < 10; i++) {
        p = scheduler.apply(p, ReviewRating.good, now);
        expect(p.confidence, greaterThanOrEqualTo(last));
        expect(p.confidence, inInclusiveRange(0, 1));
        last = p.confidence;
      }
      expect(p.confidence, 1.0);
    });

    test('difficulty decreases with easy and is clamped at 0', () {
      var p = fresh();
      for (var i = 0; i < 50; i++) {
        p = scheduler.apply(p, ReviewRating.easy, DateTime(2026, 3, 11));
      }
      expect(p.difficulty, 0.0);
    });
  });

  group('configurable', () {
    test('custom ladder and forgot delay are honored', () {
      const custom = LadderReviewScheduler(ReviewSchedulerConfig(ladderDays: [2, 5], forgotDelay: Duration(hours: 1)));
      final p = custom.initial(key, memorizedAt);
      expect(p.nextReviewAt, DateTime(2026, 3, 12));
      final now = DateTime(2026, 3, 12, 8);
      expect(custom.schedule(p, ReviewRating.forgot, now).nextReviewAt, DateTime(2026, 3, 12, 9));
      expect(custom.schedule(p, ReviewRating.easy, now).nextReviewAt, DateTime(2026, 3, 17)); // capped stage 1
    });
  });

  test('day intervals are DST-safe (calendar days, not 24h multiples)', () {
    // Across a typical spring-forward boundary the time stays midnight.
    final p = scheduler.apply(fresh(), ReviewRating.easy, DateTime(2026, 3, 25, 10));
    expect(p.nextReviewAt.hour, 0);
    expect(p.nextReviewAt, DateTime(2026, 4, 1));
  });

  test('validated constructor rejects bad ladders', () {
    expect(() => LadderReviewScheduler.validated(const ReviewSchedulerConfig(ladderDays: [])), throwsArgumentError);
    expect(() => LadderReviewScheduler.validated(const ReviewSchedulerConfig(ladderDays: [3, 1])), throwsArgumentError);
  });

  test('preview (schedule) has no side effects', () {
    final p = fresh();
    scheduler.schedule(p, ReviewRating.easy, midnightOf10th);
    expect(p, fresh());
  });
}
