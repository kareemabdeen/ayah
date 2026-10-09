import 'package:equatable/equatable.dart';

final class Surah extends Equatable {
  const Surah({
    required this.id,
    required this.nameArabic,
    required this.nameTransliterated,
    required this.ayahCount,
  });

  final int id;
  final String nameArabic;
  final String nameTransliterated;
  final int ayahCount;

  /// Juz Amma is surahs 78..114.
  bool get isInJuzAmma => id >= 78;

  @override
  List<Object?> get props => [id, nameArabic, nameTransliterated, ayahCount];
}
