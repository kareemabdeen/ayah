/// Helpers for comparing Arabic text structurally (never for display).
abstract final class ArabicText {
  /// Removes harakat, Quranic annotation marks and tatweel, and folds alef
  /// variants, so two spellings of the same words compare equal.
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (_isMark(rune)) continue;
      buffer.writeCharCode(_fold(rune));
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _isMark(int r) =>
      (r >= 0x0610 && r <= 0x061A) || // small high marks
      (r >= 0x064B && r <= 0x065F) || // harakat
      r == 0x0670 || // superscript alef
      (r >= 0x06D6 && r <= 0x06ED) || // Quranic annotation signs
      r == 0x0640; // tatweel

  static int _fold(int r) => switch (r) {
        0x0671 || 0x0622 || 0x0623 || 0x0625 => 0x0627, // ٱ آ أ إ → ا
        _ => r,
      };

  static const String _basmalaNormalized = 'بسم الله الرحمن الرحيم';
  static const int _basmalaWordCount = 4;

  /// Some text sources prefix ayah 1 of every surah (except Al-Fatihah,
  /// where the basmala *is* ayah 1, and At-Tawbah, which has none) with the
  /// basmala. It is not part of that ayah, so we strip it for memorization.
  static String stripLeadingBasmala({required int surahId, required int ayahNumber, required String text}) {
    if (ayahNumber != 1 || surahId == 1 || surahId == 9) return text;
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= _basmalaWordCount) return text;
    final head = normalize(words.take(_basmalaWordCount).join(' '));
    if (head != _basmalaNormalized) return text;
    return words.skip(_basmalaWordCount).join(' ');
  }
}
