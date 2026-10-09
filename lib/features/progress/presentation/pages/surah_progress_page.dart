import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/calm_page.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../domain/entities/surah_progress.dart';
import '../cubit/surah_progress_cubit.dart';
import '../widgets/surah_progress_widgets.dart';

class SurahProgressPage extends StatelessWidget {
  const SurahProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SurahProgressCubit, SurahProgressState>(
      builder: (context, state) {
        if (state.isLoading) return Scaffold(appBar: AppBar(), body: const LoadingView());
        final s = context.s;
        final detail = state.detail!;
        final summary = detail.summary;
        final name = surahDisplayName(context, summary);

        return CalmPage(
          appBar: AppBar(title: Text(s.surahName(name))),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (summary.isComplete) ...[
                SupportiveMessage(
                  icon: Icons.verified_rounded,
                  title: s.mashaAllah,
                  body: s.surahCompleted(name),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                s.ayahsOfTotal(summary.memorizedCount, summary.totalCount),
                textAlign: TextAlign.center,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SurahProgressBar(progress: summary),
              const SizedBox(height: AppSpacing.sm),
              Center(child: SurahLegend(progress: summary)),
              const SizedBox(height: AppSpacing.lg),
              _AyahGrid(states: detail.ayahStates),
            ],
          ),
          bottom: summary.memorizedCount == 0 ? null : _SurahTestButton(summary: summary),
        );
      },
    );
  }
}

class _SurahTestButton extends StatelessWidget {
  const _SurahTestButton({required this.summary});
  final SurahProgress summary;

  Future<void> _open(BuildContext context) async {
    await Navigator.of(context).pushNamed(Routes.review, arguments: ReviewArgs(surahTestId: summary.surah.id));
    if (context.mounted) await context.read<SurahProgressCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(context.s.fullSurahTest);
    // Emphasized once the whole surah is memorized.
    return summary.isComplete
        ? FilledButton(onPressed: () => _open(context), child: label)
        : OutlinedButton(onPressed: () => _open(context), child: label);
  }
}

/// Ayah numbers with a state icon each — readable without color.
class _AyahGrid extends StatelessWidget {
  const _AyahGrid({required this.states});
  final List<AyahState> states;

  static const double _cell = 56;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colors = context.colors;
    final ayah = context.ayahColors;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < states.length; i++)
          Semantics(
            label: '${s.ayahNumber(i + 1)}: ${ayahStateLabel(s, states[i])}',
            excludeSemantics: true,
            child: Container(
              width: _cell,
              height: _cell,
              decoration: BoxDecoration(
                color: states[i] == AyahState.notStarted ? null : colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: states[i] == AyahState.notStarted ? ayah.divider : colors.primary),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${i + 1}', style: context.text.labelLarge),
                  Icon(ayahStateIcon(states[i]), size: AppSpacing.sm + AppSpacing.xxs, color: ayah.inkMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
