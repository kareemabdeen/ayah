import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// "Listen · Repeat · Recall" — labeled segments; the current one is bold
/// and filled, completed ones show a check (not color-only).
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.labels, required this.current});

  final List<String> labels;
  final int current;

  static const double _barHeight = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = context.ayahColors.surfaceMuted;
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Semantics(
              selected: i == current,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(height: _barHeight, color: i <= current ? colors.primary : muted),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (i < current) ...[
                        Icon(Icons.check_rounded, size: AppSpacing.md, color: colors.primary),
                        const SizedBox(width: AppSpacing.xxs),
                      ],
                      Flexible(
                        child: Text(
                          labels[i],
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(
                            fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                            color: i == current ? colors.onSurface : context.ayahColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple "2 of 3" dots for repetitions. Deliberately not game-like.
class RepetitionDots extends StatelessWidget {
  const RepetitionDots({super.key, required this.done, required this.total, required this.label});

  final int done;
  final int total;
  final String label;

  static const double _dot = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < total; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: Container(
                    width: _dot,
                    height: _dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < done ? colors.primary : Colors.transparent,
                      border: Border.all(color: colors.primary, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: context.text.bodyMedium?.copyWith(color: context.ayahColors.inkMuted)),
        ],
      ),
    );
  }
}
