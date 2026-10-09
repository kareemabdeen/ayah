import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../progress/domain/entities/daily_progress.dart';

/// Three quiet numbers. Deliberately not a dashboard.
class HomeSummaryRow extends StatelessWidget {
  const HomeSummaryRow({super.key, required this.summary});

  final UserProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        _Stat(icon: Icons.menu_book_rounded, label: s.statMemorized(summary.memorizedCount)),
        _Stat(icon: Icons.history_rounded, label: s.statToReview(summary.dueReviewCount)),
        _Stat(icon: Icons.wb_sunny_outlined, label: s.statDays(summary.activeDays)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final muted = context.ayahColors.inkMuted;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.md + AppSpacing.xxs, color: muted),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: context.text.bodyMedium?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
