import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/quran_typography.dart';

/// Renders ayah text with Quran typography. Always RTL, whatever the UI
/// language, and announced to screen readers with its surah/ayah label.
class QuranVerseText extends StatelessWidget {
  const QuranVerseText({super.key, required this.text, this.semanticsLabel});

  final String text;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = QuranTypography.sizeForWidth(constraints.maxWidth);
        return Semantics(
          label: semanticsLabel,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: QuranTypography.style(fontSize: size, color: context.ayahColors.quranInk),
            ),
          ),
        );
      },
    );
  }
}

/// Small "Surah · Ayah N" caption shown under a verse.
class VerseReference extends StatelessWidget {
  const VerseReference({super.key, required this.surahName, required this.ayahNumber});

  final String surahName;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Text(
      '${s.surahName(surahName)} · ${s.ayahNumber(ayahNumber)}',
      textAlign: TextAlign.center,
      style: context.text.bodyMedium?.copyWith(color: context.ayahColors.inkMuted),
    );
  }
}

/// Card holding an ayah. When [hidden] the text is replaced by a calm
/// placeholder (active recall); [hintWords] optionally reveals the start.
class VerseCard extends StatelessWidget {
  const VerseCard({
    super.key,
    required this.text,
    required this.surahName,
    required this.ayahNumber,
    this.hidden = false,
    this.hintWords = 0,
  });

  final String text;
  final String surahName;
  final int ayahNumber;
  final bool hidden;
  final int hintWords;

  @override
  Widget build(BuildContext context) {
    final colors = context.ayahColors;
    final hint = hintWords > 0 ? text.split(RegExp(r'\s+')).take(hintWords).join(' ') : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.of(context, AppDurations.calm),
              child: hidden
                  ? _HiddenVerse(key: const ValueKey('hidden'), hint: hint, color: colors.inkMuted)
                  : QuranVerseText(
                      key: const ValueKey('shown'),
                      text: text,
                      semanticsLabel: '${context.s.surahName(surahName)}, ${context.s.ayahNumber(ayahNumber)}',
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            VerseReference(surahName: surahName, ayahNumber: ayahNumber),
          ],
        ),
      ),
    );
  }
}

class _HiddenVerse extends StatelessWidget {
  const _HiddenVerse({super.key, required this.hint, required this.color});

  final String? hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: QuranVerseText(text: '$hint …'),
          )
        else
          Icon(Icons.visibility_off_outlined, size: AppSpacing.xxl, color: color),
        Text(context.s.ayahHidden, style: context.text.bodyLarge?.copyWith(color: color)),
      ],
    );
  }
}
