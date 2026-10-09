import '../../../../core/utils/result.dart';
import '../entities/surah.dart';
import '../entities/verse.dart';
import '../entities/verse_key.dart';

/// Source of Quran content. Implementations decide whether data comes from
/// a bundled asset, a local cache, or the network — callers never know.
abstract interface class QuranRepository {
  /// Surah metadata (names, ayah counts). Always available offline.
  List<Surah> getSurahs();

  Surah getSurah(int surahId);

  Future<Result<List<Verse>>> getVersesOfSurah(int surahId);

  Future<Result<Verse>> getVerse(VerseKey key);

  /// Fetches several verses, possibly across surahs, preserving order.
  Future<Result<List<Verse>>> getVerses(List<VerseKey> keys);
}
