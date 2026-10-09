import 'package:equatable/equatable.dart';

import 'verse_key.dart';

/// A single ayah with its verified text and recitation audio.
final class Verse extends Equatable {
  const Verse({
    required this.key,
    required this.surahName,
    required this.globalNumber,
    required this.arabicText,
    required this.audioUrl,
  });

  final VerseKey key;

  /// Arabic surah name (display only).
  final String surahName;

  /// Position in the whole mushaf, 1..6236.
  final int globalNumber;
  final String arabicText;
  final String audioUrl;

  String get id => key.id;
  int get surahId => key.surahId;
  int get ayahNumber => key.ayahNumber;

  @override
  List<Object?> get props => [key, surahName, globalNumber, arabicText, audioUrl];
}
