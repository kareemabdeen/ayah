import 'package:ayah/features/progress/domain/entities/verse_progress.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:ayah/features/review/domain/services/review_queue_policy.dart';
import 'package:flutter_test/flutter_test.dart';

VerseProgress progress(int ayah, {required DateTime due, int stage = 0, int surah = 78}) => VerseProgress(
      key: VerseKey(surah, ayah),
      status: VerseStatus.learning,
      stage: stage,
      repetitionCount: 0,
      lapses: 0,
      confidence: 0,
      difficulty: 0.3,
      memorizedAt: DateTime(2026, 1, 1),
      lastReviewedAt: DateTime(2026, 1, 1),
      nextReviewAt: due,
    );

void main() {
  const policy = ReviewQueuePolicy(maxDailyReviews: 10);
  final now = DateTime(2026, 3, 10, 9);

  test('only due items are selected', () {
    final items = [
      progress(1, due: DateTime(2026, 3, 10)), // due today at midnight
      progress(2, due: DateTime(2026, 3, 11)), // tomorrow
      progress(3, due: now.add(const Duration(minutes: 5))), // later today
    ];
    expect(policy.select(items, now).map((p) => p.key.ayahNumber), [1]);
  });

  test('missed days: 50 overdue ayahs never flood the user — capped to the daily max', () {
    final overdue = [for (var i = 1; i <= 40; i++) progress(i, due: DateTime(2026, 2, 1).add(Duration(days: i % 20)))];
    final selected = policy.select(overdue, now);
    expect(selected.length, 10);
    expect(policy.allDue(overdue, now).length, 40);
  });

  test('overdue backlog drains gradually over following days', () {
    var remaining = [for (var i = 1; i <= 25; i++) progress(i, due: DateTime(2026, 2, 1))];
    final perDay = <int>[];
    for (var day = 0; day < 3; day++) {
      final picked = policy.select(remaining, now.add(Duration(days: day)));
      perDay.add(picked.length);
      final pickedKeys = picked.map((p) => p.key).toSet();
      remaining = remaining.where((p) => !pickedKeys.contains(p.key)).toList();
    }
    expect(perDay, [10, 10, 5]);
  });

  test('weakest first (lower stage), then most overdue', () {
    final items = [
      progress(1, due: DateTime(2026, 3, 1), stage: 3),
      progress(2, due: DateTime(2026, 3, 9), stage: 0),
      progress(3, due: DateTime(2026, 3, 5), stage: 0),
      progress(4, due: DateTime(2026, 2, 1), stage: 2),
    ];
    expect(policy.select(items, now).map((p) => p.key.ayahNumber), [3, 2, 4, 1]);
  });

  test('ties are broken deterministically by mushaf order', () {
    final due = DateTime(2026, 3, 1);
    final items = [progress(5, due: due), progress(2, due: due), progress(9, due: due)];
    expect(policy.select(items, now).map((p) => p.key.ayahNumber), [2, 5, 9]);
  });

  test('reviews already done today reduce the remaining budget', () {
    final items = [for (var i = 1; i <= 20; i++) progress(i, due: DateTime(2026, 3, 1))];
    expect(policy.select(items, now, reviewedToday: 7).length, 3);
    expect(policy.select(items, now, reviewedToday: 10), isEmpty);
    expect(policy.select(items, now, reviewedToday: 15), isEmpty);
  });

  test('empty input yields empty queue', () {
    expect(policy.select(const [], now), isEmpty);
  });
}
