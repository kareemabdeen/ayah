import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/storage/local_store.dart';
import '../models/verse_dto.dart';

abstract interface class QuranLocalDataSource {
  /// Throws [CacheMissException] when the surah isn't cached.
  Future<List<VerseDto>> getSurah(int surahId);

  Future<void> cacheSurah(int surahId, List<VerseDto> verses);
}

/// Offline cache of surah text in the app's [LocalStore].
///
/// To ship fully offline from first launch, add an asset-backed
/// implementation (e.g. a bundled Tanzil JSON) and compose it before this
/// one in the repository — nothing above the data layer changes.
final class CachedQuranLocalDataSource implements QuranLocalDataSource {
  CachedQuranLocalDataSource(this._store);

  final LocalStore _store;

  /// Bump if the cached format or the text edition changes.
  static const int _schemaVersion = 1;

  String _key(int surahId) => 'surah:$surahId';

  @override
  Future<List<VerseDto>> getSurah(int surahId) async {
    final raw = await _store.read(StoreCollections.quranCache, _key(surahId));
    if (raw == null ||
        raw['v'] != _schemaVersion ||
        raw['edition'] != QuranSourceConstants.textEdition ||
        raw['ayahs'] is! List) {
      throw CacheMissException('surah $surahId');
    }
    return [
      for (final a in raw['ayahs'] as List) VerseDto.fromCache(a as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> cacheSurah(int surahId, List<VerseDto> verses) => _store.write(
        StoreCollections.quranCache,
        _key(surahId),
        {
          'v': _schemaVersion,
          'edition': QuranSourceConstants.textEdition,
          'ayahs': [for (final v in verses) v.toCache()],
        },
      );
}
