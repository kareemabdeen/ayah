import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/surah.dart';
import '../../domain/entities/verse.dart';
import '../../domain/entities/verse_key.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';
import '../datasources/quran_remote_data_source.dart';
import '../datasources/surah_metadata.dart';
import '../models/verse_dto.dart';
import '../utils/arabic_text.dart';

/// Cache-first repository: memory → local store → network (then cached).
final class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({
    required QuranLocalDataSource local,
    required QuranRemoteDataSource remote,
    List<Surah> metadata = kSurahMetadata,
    String reciter = QuranSourceConstants.defaultReciter,
  })  : _local = local,
        _remote = remote,
        _metadata = metadata,
        _reciter = reciter;

  final QuranLocalDataSource _local;
  final QuranRemoteDataSource _remote;
  final List<Surah> _metadata;
  final String _reciter;

  final Map<int, List<Verse>> _memory = {};
  final Map<int, Future<Result<List<Verse>>>> _inFlight = {};

  @override
  List<Surah> getSurahs() => _metadata;

  @override
  Surah getSurah(int surahId) => _metadata[surahId - 1];

  @override
  Future<Result<List<Verse>>> getVersesOfSurah(int surahId) {
    final cached = _memory[surahId];
    if (cached != null) return Future.value(Success(cached));
    return _inFlight[surahId] ??= _load(surahId).whenComplete(() => _inFlight.remove(surahId));
  }

  Future<Result<List<Verse>>> _load(int surahId) async {
    try {
      List<VerseDto> dtos;
      try {
        dtos = await _local.getSurah(surahId);
      } on CacheMissException {
        dtos = (await _remote.fetchSurah(surahId))
            .map((d) => d.withText(
                  ArabicText.stripLeadingBasmala(surahId: d.surahId, ayahNumber: d.ayahNumber, text: d.text),
                ))
            .toList(growable: false);
        _assertComplete(surahId, dtos);
        await _local.cacheSurah(surahId, dtos);
      }
      final surah = getSurah(surahId);
      final verses = [for (final d in dtos) _toEntity(d, surah)];
      _memory[surahId] = verses;
      return Success(verses);
    } on NetworkException catch (e) {
      return Err(NetworkFailure(e.message));
    } on DataFormatException catch (e) {
      return Err(UnexpectedFailure(e.message));
    } catch (e) {
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  /// Never cache a partial surah — memorization must be on complete text.
  void _assertComplete(int surahId, List<VerseDto> dtos) {
    final expected = getSurah(surahId).ayahCount;
    if (dtos.length != expected) {
      throw DataFormatException('Surah $surahId: expected $expected ayahs, got ${dtos.length}');
    }
  }

  Verse _toEntity(VerseDto d, Surah surah) => Verse(
        key: VerseKey(d.surahId, d.ayahNumber),
        surahName: surah.nameArabic,
        globalNumber: d.globalNumber,
        arabicText: d.text,
        audioUrl: QuranSourceConstants.audioUrl(d.globalNumber, reciter: _reciter),
      );

  @override
  Future<Result<Verse>> getVerse(VerseKey key) async {
    final result = await getVersesOfSurah(key.surahId);
    return result.fold<Result<Verse>>((f) => Err<Verse>(f), (verses) {
      final index = key.ayahNumber - 1;
      if (index < 0 || index >= verses.length) return Err<Verse>(NotFoundFailure(key.id));
      return Success<Verse>(verses[index]);
    });
  }

  @override
  Future<Result<List<Verse>>> getVerses(List<VerseKey> keys) async {
    final out = <Verse>[];
    for (final key in keys) {
      final r = await getVerse(key);
      switch (r) {
        case Success(:final value):
          out.add(value);
        case Err(:final failure):
          return Err(failure);
      }
    }
    return Success(out);
  }
}
