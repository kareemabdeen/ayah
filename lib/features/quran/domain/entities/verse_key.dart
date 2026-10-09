import 'package:equatable/equatable.dart';

/// Identifies an ayah as `surah:ayah` (e.g. `67:1`). This is the stable key
/// used across progress, review, and storage — independent of any data source.
final class VerseKey extends Equatable implements Comparable<VerseKey> {
  const VerseKey(this.surahId, this.ayahNumber)
      : assert(surahId >= 1 && surahId <= 114),
        assert(ayahNumber >= 1);

  factory VerseKey.parse(String id) {
    final parts = id.split(':');
    if (parts.length != 2) throw FormatException('Invalid verse key: $id');
    return VerseKey(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int surahId;
  final int ayahNumber;

  String get id => '$surahId:$ayahNumber';

  /// The following ayah in the same surah (used by Chain mode).
  VerseKey get nextInSurah => VerseKey(surahId, ayahNumber + 1);

  @override
  int compareTo(VerseKey other) =>
      surahId != other.surahId ? surahId.compareTo(other.surahId) : ayahNumber.compareTo(other.ayahNumber);

  @override
  List<Object?> get props => [surahId, ayahNumber];

  @override
  String toString() => id;
}
