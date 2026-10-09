import '../../../../core/errors/exceptions.dart';

/// Raw ayah record as stored in cache / received from a source.
final class VerseDto {
  const VerseDto({
    required this.surahId,
    required this.ayahNumber,
    required this.globalNumber,
    required this.text,
  });

  final int surahId;
  final int ayahNumber;
  final int globalNumber;
  final String text;

  /// AlQuran Cloud `ayahs[]` item: `{number, text, numberInSurah, ...}`.
  factory VerseDto.fromAlQuranCloud(int surahId, Map<String, dynamic> json) {
    final number = json['number'];
    final inSurah = json['numberInSurah'];
    final text = json['text'];
    if (number is! int || inSurah is! int || text is! String || text.isEmpty) {
      throw const DataFormatException('Unexpected ayah payload');
    }
    return VerseDto(surahId: surahId, ayahNumber: inSurah, globalNumber: number, text: text);
  }

  factory VerseDto.fromCache(Map<String, dynamic> json) => VerseDto(
        surahId: json['s'] as int,
        ayahNumber: json['a'] as int,
        globalNumber: json['g'] as int,
        text: json['t'] as String,
      );

  Map<String, dynamic> toCache() => {'s': surahId, 'a': ayahNumber, 'g': globalNumber, 't': text};

  VerseDto withText(String newText) =>
      VerseDto(surahId: surahId, ayahNumber: ayahNumber, globalNumber: globalNumber, text: newText);
}
