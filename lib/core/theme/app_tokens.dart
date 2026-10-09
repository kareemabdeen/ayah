import 'package:flutter/material.dart';

/// Spacing scale (4-pt). Use these instead of raw numbers in widgets.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Max content width so text lines stay readable on tablets.
  static const double maxContentWidth = 560;

  /// Minimum interactive size (Material/WCAG ≥ 48dp).
  static const double minTouchTarget = 48;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration calm = Duration(milliseconds: 400);

  /// Respects the OS "reduce motion" setting.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}

/// Raw palette. Calm, warm "paper & ink" with a deep green accent.
/// Contrast pairs were chosen to meet WCAG AA for body text.
abstract final class AppPalette {
  // Light
  static const lightBackground = Color(0xFFF6F3EC);
  static const lightSurface = Color(0xFFFFFDF8);
  static const lightSurfaceMuted = Color(0xFFEEE9DE);
  static const lightInk = Color(0xFF1E2B2A);
  static const lightInkMuted = Color(0xFF55625F);
  static const lightPrimary = Color(0xFF2E6A5B);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightAccent = Color(0xFF8C6A33);
  static const lightQuranInk = Color(0xFF14201E);
  static const lightDivider = Color(0xFFE2DCCF);

  // Dark — low glare for night reading.
  static const darkBackground = Color(0xFF101513);
  static const darkSurface = Color(0xFF18201D);
  static const darkSurfaceMuted = Color(0xFF222B28);
  static const darkInk = Color(0xFFE9E5DA);
  static const darkInkMuted = Color(0xFFA3ADA8);
  static const darkPrimary = Color(0xFF86BFAE);
  static const darkOnPrimary = Color(0xFF0D1A16);
  static const darkAccent = Color(0xFFCFAE73);
  static const darkQuranInk = Color(0xFFF1EDE2);
  static const darkDivider = Color(0xFF2A3330);
}
