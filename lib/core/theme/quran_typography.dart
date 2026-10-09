import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Quran text is typeset differently from UI text: a dedicated Uthmani-style
/// face, generous line height, and size that scales with the screen.
abstract final class QuranTypography {
  static const String _primaryFamily = 'Amiri Quran';
  static const String _fallbackFamily = 'Amiri';

  static const double _referenceWidth = 360;
  static const double _baseSize = 30;
  static const double _minSize = 26;
  static const double _maxSize = 40;
  static const double lineHeight = 2.1;

  /// Base size scaled to the available width. The OS text scale is applied
  /// on top by [Text] itself, so "large text" accessibility still works.
  static double sizeForWidth(double width) =>
      (_baseSize * width / _referenceWidth).clamp(_minSize, _maxSize);

  static TextStyle style({required double fontSize, required Color color}) {
    final base = TextStyle(fontSize: fontSize, height: lineHeight, color: color);
    try {
      return GoogleFonts.getFont(_primaryFamily, textStyle: base);
    } catch (_) {
      return GoogleFonts.getFont(_fallbackFamily, textStyle: base);
    }
  }
}
