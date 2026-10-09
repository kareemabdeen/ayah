import 'package:ayah/core/errors/exceptions.dart';
import 'package:ayah/core/errors/failures.dart';
import 'package:ayah/core/services/storage/in_memory_local_store.dart';
import 'package:ayah/core/utils/result.dart';
import 'package:ayah/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:ayah/features/quran/data/datasources/quran_remote_data_source.dart';
import 'package:ayah/features/quran/data/datasources/surah_metadata.dart';
import 'package:ayah/features/quran/data/models/verse_dto.dart';
import 'package:ayah/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:ayah/features/quran/data/utils/arabic_text.dart';
import 'package:ayah/features/quran/domain/entities/verse_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// Remote that returns placeholder (non-Quran) text; optionally prefixed
/// with the basmala, as some sources do for ayah 1.
final class _FakeRemote implements QuranRemoteDataSource {
  int calls = 0;
  bool offline = false;
  int? truncateTo;
  bool prefixBasmala = false;

  static const basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  @override
  Future<List<VerseDto>> fetchSurah(int surahId) async {
    calls++;
    if (offline) throw const NetworkException('offline');
    final count = truncateTo ?? kSurahMetadata[surahId - 1].ayahCount;
    return [
      for (var a = 1; a <= count; a++)
        VerseDto(
          surahId: surahId,
          ayahNumber: a,
          globalNumber: 1000 + a,
          text: (prefixBasmala && a == 1 ? '$basmala ' : '') + 'placeholder $surahId:$a',
        ),
    ];
  }
}

void main() {
  group('surah metadata', () {
    test('114 surahs, ids in order, 6236 ayahs total', () {
      expect(kSurahMetadata.length, 114);
      for (var i = 0; i < 114; i++) {
        expect(kSurahMetadata[i].id, i + 1);
      }
      expect(kSurahMetadata.fold<int>(0, (s, x) => s + x.ayahCount), 6236);
    });

    test('spot checks', () {
      expect(kSurahMetadata[0].ayahCount, 7);
      expect(kSurahMetadata[1].ayahCount, 286);
      expect(kSurahMetadata[66].ayahCount, 30); // Al-Mulk
      expect(kSurahMetadata[113].ayahCount, 6);
    });
  });

  group('ArabicText', () {
    test('normalize removes harakat and folds alef wasla', () {
      expect(ArabicText.normalize(_FakeRemote.basmala), 'بسم الله الرحمن الرحيم');
    });

    test('strips a leading basmala from ayah 1 of most surahs', () {
      final t = ArabicText.stripLeadingBasmala(surahId: 2, ayahNumber: 1, text: '${_FakeRemote.basmala} rest of ayah');
      expect(t, 'rest of ayah');
    });

    test('keeps it for Al-Fatihah (where it is ayah 1), At-Tawbah, and other ayahs', () {
      final text = '${_FakeRemote.basmala} x';
      expect(ArabicText.stripLeadingBasmala(surahId: 1, ayahNumber: 1, text: text), text);
      expect(ArabicText.stripLeadingBasmala(surahId: 9, ayahNumber: 1, text: text), text);
      expect(ArabicText.stripLeadingBasmala(surahId: 2, ayahNumber: 2, text: text), text);
    });

    test('leaves text without a basmala untouched', () {
      expect(ArabicText.stripLeadingBasmala(surahId: 2, ayahNumber: 1, text: 'a b c d e'), 'a b c d e');
    });
  });

  group('QuranRepositoryImpl', () {
    late _FakeRemote remote;
    late InMemoryLocalStore store;
    late QuranRepositoryImpl repo;

    setUp(() {
      remote = _FakeRemote();
      store = InMemoryLocalStore();
      repo = QuranRepositoryImpl(local: CachedQuranLocalDataSource(store), remote: remote);
    });

    test('fetches once, then serves from cache (offline-capable)', () async {
      final first = await repo.getVersesOfSurah(114);
      expect(first.valueOrNull!.length, 6);
      expect(remote.calls, 1);

      remote.offline = true;
      final fresh = QuranRepositoryImpl(local: CachedQuranLocalDataSource(store), remote: remote);
      final second = await fresh.getVersesOfSurah(114);
      expect(second.valueOrNull!.length, 6);
      expect(remote.calls, 1);
    });

    test('maps to entities with surah name and audio by global number', () async {
      final v = (await repo.getVerse(const VerseKey(114, 2))).valueOrNull!;
      expect(v.surahName, kSurahMetadata[113].nameArabic);
      expect(v.audioUrl, endsWith('/1002.mp3'));
    });

    test('strips basmala before caching', () async {
      remote.prefixBasmala = true;
      final v = (await repo.getVerse(const VerseKey(114, 1))).valueOrNull!;
      expect(v.arabicText, 'placeholder 114:1');
    });

    test('offline with no cache → NetworkFailure', () async {
      remote.offline = true;
      final r = await repo.getVersesOfSurah(114);
      expect((r as Err).failure, isA<NetworkFailure>());
    });

    test('never caches an incomplete surah', () async {
      remote.truncateTo = 3;
      final r = await repo.getVersesOfSurah(114);
      expect(r.isSuccess, isFalse);
      expect(await store.read('quran_cache', 'surah:114'), isNull);
    });

    test('concurrent requests for the same surah hit the network once', () async {
      await Future.wait([repo.getVersesOfSurah(113), repo.getVersesOfSurah(113)]);
      expect(remote.calls, 1);
    });

    test('unknown ayah → NotFoundFailure', () async {
      final r = await repo.getVerse(const VerseKey(114, 99));
      expect((r as Err).failure, isA<NotFoundFailure>());
    });
  });
}
