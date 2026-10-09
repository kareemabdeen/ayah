import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Semantic colors that Material's ColorScheme doesn't cover.
@immutable
final class AyahColors extends ThemeExtension<AyahColors> {
  const AyahColors({
    required this.quranInk,
    required this.inkMuted,
    required this.surfaceMuted,
    required this.accent,
    required this.divider,
  });

  final Color quranInk;
  final Color inkMuted;
  final Color surfaceMuted;
  final Color accent;
  final Color divider;

  static const light = AyahColors(
    quranInk: AppPalette.lightQuranInk,
    inkMuted: AppPalette.lightInkMuted,
    surfaceMuted: AppPalette.lightSurfaceMuted,
    accent: AppPalette.lightAccent,
    divider: AppPalette.lightDivider,
  );

  static const dark = AyahColors(
    quranInk: AppPalette.darkQuranInk,
    inkMuted: AppPalette.darkInkMuted,
    surfaceMuted: AppPalette.darkSurfaceMuted,
    accent: AppPalette.darkAccent,
    divider: AppPalette.darkDivider,
  );

  @override
  AyahColors copyWith({Color? quranInk, Color? inkMuted, Color? surfaceMuted, Color? accent, Color? divider}) =>
      AyahColors(
        quranInk: quranInk ?? this.quranInk,
        inkMuted: inkMuted ?? this.inkMuted,
        surfaceMuted: surfaceMuted ?? this.surfaceMuted,
        accent: accent ?? this.accent,
        divider: divider ?? this.divider,
      );

  @override
  AyahColors lerp(ThemeExtension<AyahColors>? other, double t) {
    if (other is! AyahColors) return this;
    return AyahColors(
      quranInk: Color.lerp(quranInk, other.quranInk, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension AyahThemeX on BuildContext {
  AyahColors get ayahColors => Theme.of(this).extension<AyahColors>() ?? AyahColors.light;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class AppTheme {
  static const String uiFontFamily = 'IBM Plex Sans Arabic';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppPalette.lightPrimary,
          onPrimary: AppPalette.lightOnPrimary,
          secondary: AppPalette.lightAccent,
          onSecondary: AppPalette.lightOnPrimary,
          error: Color(0xFFB3261E),
          onError: Color(0xFFFFFFFF),
          surface: AppPalette.lightSurface,
          onSurface: AppPalette.lightInk,
          surfaceContainerHighest: AppPalette.lightSurfaceMuted,
          outline: AppPalette.lightDivider,
        ),
        background: AppPalette.lightBackground,
        extension: AyahColors.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppPalette.darkPrimary,
          onPrimary: AppPalette.darkOnPrimary,
          secondary: AppPalette.darkAccent,
          onSecondary: AppPalette.darkOnPrimary,
          error: Color(0xFFF2B8B5),
          onError: Color(0xFF601410),
          surface: AppPalette.darkSurface,
          onSurface: AppPalette.darkInk,
          surfaceContainerHighest: AppPalette.darkSurfaceMuted,
          outline: AppPalette.darkDivider,
        ),
        background: AppPalette.darkBackground,
        extension: AyahColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required AyahColors extension,
  }) {
    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final textTheme = GoogleFonts.getTextTheme(uiFontFamily, base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    const buttonMinSize = Size(AppSpacing.minTouchTarget * 2, AppSpacing.minTouchTarget + AppSpacing.xs);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      extensions: [extension],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: extension.divider),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: buttonShape,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: buttonShape,
          side: BorderSide(color: extension.divider),
          foregroundColor: scheme.onSurface,
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
          foregroundColor: extension.inkMuted,
          textStyle: textTheme.bodyLarge,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: extension.surfaceMuted,
      ),
      dividerTheme: DividerThemeData(color: extension.divider, space: 1),
      // Calm transitions: fade-through instead of sliding pages.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
