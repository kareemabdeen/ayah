import 'dart:async';

import 'package:ayah/core/errors/failures.dart';
import 'package:ayah/core/services/audio/audio_player_service.dart';
import 'package:ayah/core/services/notifications/reminder_service.dart';
import 'package:ayah/core/utils/result.dart';
import 'package:ayah/features/quran/data/datasources/surah_metadata.dart';
import 'package:ayah/features/quran/domain/entities/surah.dart';
import 'package:ayah/features/quran/domain/entities/verse.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:ayah/features/quran/domain/repositories/quran_repository.dart';

/// Quran repository for tests. Uses obviously fake Latin placeholder text —
/// never real or invented Quran text.
final class FakeQuranRepository implements QuranRepository {
  FakeQuranRepository({this.failWith});

  Failure? failWith;

  static String placeholder(VerseKey k) => 'placeholder word1 word2 word3 ${k.id}';

  Verse _verse(VerseKey k) => Verse(
        key: k,
        surahName: kSurahMetadata[k.surahId - 1].nameArabic,
        globalNumber: k.ayahNumber,
        arabicText: placeholder(k),
        audioUrl: 'https://example.test/${k.id}.mp3',
      );

  @override
  List<Surah> getSurahs() => kSurahMetadata;

  @override
  Surah getSurah(int surahId) => kSurahMetadata[surahId - 1];

  @override
  Future<Result<Verse>> getVerse(VerseKey key) async =>
      failWith != null ? Err(failWith!) : Success(_verse(key));

  @override
  Future<Result<List<Verse>>> getVerses(List<VerseKey> keys) async =>
      failWith != null ? Err(failWith!) : Success([for (final k in keys) _verse(k)]);

  @override
  Future<Result<List<Verse>>> getVersesOfSurah(int surahId) async => failWith != null
      ? Err(failWith!)
      : Success([for (var a = 1; a <= getSurah(surahId).ayahCount; a++) _verse(VerseKey(surahId, a))]);
}

final class FakeAudioPlayerService implements AudioPlayerService {
  final _controller = StreamController<PlaybackSnapshot>.broadcast();
  PlaybackSnapshot _current = const PlaybackSnapshot();
  final List<String> played = [];
  int stopCount = 0;
  bool throwOnPlay = false;

  void _emit(PlaybackSnapshot s) {
    _current = s;
    _controller.add(s);
  }

  @override
  Stream<PlaybackSnapshot> get snapshots => _controller.stream;

  @override
  PlaybackSnapshot get current => _current;

  @override
  Future<void> play(String url, {double speed = 1.0}) async {
    if (throwOnPlay) throw Exception('no audio');
    played.add(url);
    _emit(_current.copyWith(source: url, phase: PlaybackPhase.playing, speed: speed));
  }

  @override
  Future<void> pause() async => _emit(_current.copyWith(phase: PlaybackPhase.paused));

  @override
  Future<void> resume() async => _emit(_current.copyWith(phase: PlaybackPhase.playing));

  @override
  Future<void> replay() async {
    if (_current.source != null) played.add(_current.source!);
    _emit(_current.copyWith(phase: PlaybackPhase.playing));
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async => _emit(_current.copyWith(speed: speed));

  @override
  Future<void> stop() async {
    stopCount++;
    _emit(_current.copyWith(phase: PlaybackPhase.idle));
  }

  @override
  Future<void> dispose() => _controller.close();
}

final class FakeReminderService implements ReminderService {
  final List<({int hour, int minute, ReminderContent content})> scheduled = [];
  int cancelCount = 0;
  bool permissionRequested = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionRequested = true;

  @override
  Future<void> scheduleDaily({required int hour, required int minute, required ReminderContent content}) async =>
      scheduled.add((hour: hour, minute: minute, content: content));

  @override
  Future<void> cancelAll() async => cancelCount++;
}
