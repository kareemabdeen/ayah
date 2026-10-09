import 'package:ayah/features/memorization/domain/entities/chain_segment.dart';
import 'package:ayah/features/memorization/domain/entities/memorization_session.dart';
import 'package:ayah/features/quran/domain/entities/verse.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:flutter_test/flutter_test.dart';

Verse verse(int ayah) => Verse(
      key: VerseKey(114, ayah),
      surahName: 'test',
      globalNumber: ayah,
      arabicText: 'placeholder $ayah',
      audioUrl: 'https://example.test/$ayah.mp3',
    );

void main() {
  MemorizationSession session({int verses = 1}) => MemorizationSession(
        verses: [for (var i = 1; i <= verses; i++) verse(i)],
        targetRepetitions: 3,
        startedAt: DateTime(2026, 3, 10),
      );

  MemorizationSession toRecall(MemorizationSession s) {
    var x = s.startRepeating();
    for (var i = 0; i < x.targetRepetitions; i++) {
      x = x.registerRepetition();
    }
    return x.startRecall();
  }

  test('starts in listen with zero repetitions', () {
    final s = session();
    expect(s.step, MemorizationStep.listen);
    expect(s.repetitionsDone, 0);
    expect(s.attemptsForCurrent, 1);
  });

  test('repetitions count up to target and never beyond', () {
    var s = session().startRepeating();
    for (var i = 0; i < 5; i++) {
      s = s.registerRepetition();
    }
    expect(s.repetitionsDone, 3);
    expect(s.repetitionsSatisfied, isTrue);
  });

  test('repetition is ignored outside the repeat step', () {
    expect(session().registerRepetition().repetitionsDone, 0);
  });

  test('remembered on the last verse completes the session', () {
    final s = toRecall(session()).applyRecall(RecallOutcome.remembered);
    expect(s.isCompleted, isTrue);
    expect(s.completedVerseIds, ['114:1']);
  });

  test('remembered with more verses moves to the next verse, fresh', () {
    final s = toRecall(session(verses: 2)).applyRecall(RecallOutcome.remembered);
    expect(s.index, 1);
    expect(s.step, MemorizationStep.listen);
    expect(s.repetitionsDone, 0);
    expect(s.attemptsForCurrent, 1);
    expect(s.completedVerseIds, ['114:1']);
  });

  test('"I need another try" → back to repeat, one more repetition, attempt counted', () {
    final s = toRecall(session()).applyRecall(RecallOutcome.needAnotherTry);
    expect(s.step, MemorizationStep.repeat);
    expect(s.repetitionsDone, 2);
    expect(s.repetitionsSatisfied, isFalse);
    expect(s.attemptsForCurrent, 2);
  });

  test('"I forgot" → gentle restart from listening, never ends the session', () {
    final s = toRecall(session()).applyRecall(RecallOutcome.forgot);
    expect(s.step, MemorizationStep.listen);
    expect(s.repetitionsDone, 0);
    expect(s.attemptsForCurrent, 2);
    expect(s.isCompleted, isFalse);
    expect(s.completedVerseIds, isEmpty);
  });

  test('empty session', () {
    final s = MemorizationSession(verses: const [], targetRepetitions: 3, startedAt: DateTime(2026));
    expect(s.isEmpty, isTrue);
  });

  group('ChainSegment (chain mode model)', () {
    const seg = ChainSegment(surahId: 67, fromAyah: 5, toAyah: 7);

    test('keys and links', () {
      expect(seg.keys, [const VerseKey(67, 5), const VerseKey(67, 6), const VerseKey(67, 7)]);
      expect(seg.links, [
        const ChainLink(VerseKey(67, 5), VerseKey(67, 6)),
        const ChainLink(VerseKey(67, 6), VerseKey(67, 7)),
      ]);
      expect(seg.length, 3);
    });

    test('contains', () {
      expect(seg.contains(const VerseKey(67, 6)), isTrue);
      expect(seg.contains(const VerseKey(67, 8)), isFalse);
      expect(seg.contains(const VerseKey(66, 6)), isFalse);
    });
  });
}
