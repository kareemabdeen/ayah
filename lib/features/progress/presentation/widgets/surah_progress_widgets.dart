import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/surah_progress.dart';

/// Icon per ayah state, so state is never conveyed by color alone.
IconData ayahStateIcon(AyahState s) => switch (s) {
      AyahState.memorized => Icons.check_circle_rounded,
      AyahState.needsReview => Icons.history_rounded,
      AyahState.notStarted => Icons.circle_outlined,
    };

String ayahStateLabel(AppStrings s, AyahState state) => switch (state) {
      AyahState.memorized => s.stateMemorized,
      AyahState.needsReview => s.stateNeedsReview,
      AyahState.notStarted => s.stateNotStarted,
    };

String surahDisplayName(BuildContext context, SurahProgress p) =>
    Localizations.localeOf(context).languageCode == 'ar' ? p.surah.nameArabic : p.surah.nameTransliterated;

class SurahProgressBar extends StatelessWidget {
  const SurahProgressBar({super.key, required this.progress});
  final SurahProgress progress;

  static const double _height = 8;

  @override
  Widget build(BuildContext context) => Semantics(
        value: context.s.ayahsOfTotal(progress.memorizedCount, progress.totalCount),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(value: progress.fraction, minHeight: _height),
        ),
      );
}

class SurahLegend extends StatelessWidget {
  const SurahLegend({super.key, required this.progress});
  final SurahProgress progress;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xxs,
      children: [
        _LegendItem(icon: ayahStateIcon(AyahState.memorized), label: s.legendMemorized(progress.strongCount)),
        _LegendItem(icon: ayahStateIcon(AyahState.needsReview), label: s.legendNeedsReview(progress.needsReviewCount)),
        _LegendItem(icon: ayahStateIcon(AyahState.notStarted), label: s.legendNotStarted(progress.notStartedCount)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final muted = context.ayahColors.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.md, color: muted),
        const SizedBox(width: AppSpacing.xxs),
        Text(label, style: context.text.bodySmall?.copyWith(color: muted)),
      ],
    );
  }
}
