import 'package:equatable/equatable.dart';

import '../../../quran/domain/entities/verse_key.dart';

/// A contiguous run of ayahs within one surah — the unit of Chain mode
/// ("start from ayah 5, continue to 6, then 7"). P1 feature: the model is
/// here so sessions, review and storage can already speak in segments.
final class ChainSegment extends Equatable {
  const ChainSegment({required this.surahId, required this.fromAyah, required this.toAyah})
      : assert(fromAyah >= 1),
        assert(toAyah >= fromAyah);

  final int surahId;
  final int fromAyah;
  final int toAyah;

  int get length => toAyah - fromAyah + 1;

  List<VerseKey> get keys => [for (var a = fromAyah; a <= toAyah; a++) VerseKey(surahId, a)];

  /// Each transition the user must make: (5→6), (6→7)...
  /// Chain mode scores these links, not the ayahs alone.
  List<ChainLink> get links => [
        for (var a = fromAyah; a < toAyah; a++) ChainLink(VerseKey(surahId, a), VerseKey(surahId, a + 1)),
      ];

  bool contains(VerseKey key) => key.surahId == surahId && key.ayahNumber >= fromAyah && key.ayahNumber <= toAyah;

  @override
  List<Object?> get props => [surahId, fromAyah, toAyah];
}

final class ChainLink extends Equatable {
  const ChainLink(this.from, this.to);
  final VerseKey from;
  final VerseKey to;

  @override
  List<Object?> get props => [from, to];
}
