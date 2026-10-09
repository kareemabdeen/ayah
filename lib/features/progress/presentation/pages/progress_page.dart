import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../domain/entities/surah_progress.dart';
import '../cubit/progress_cubit.dart';
import '../widgets/surah_progress_widgets.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.progressTitle)),
      body: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) {
          if (state.status == ProgressStatus.loading) return const LoadingView();
          final started = state.surahs.any((p) => p.isStarted);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (!started)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Text(
                        s.nothingYet,
                        textAlign: TextAlign.center,
                        style: context.text.bodyLarge?.copyWith(color: context.ayahColors.inkMuted),
                      ),
                    ),
                  for (final p in state.surahs) _SurahTile(progress: p),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.progress});
  final SurahProgress progress;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).pushNamed(Routes.surah, arguments: progress.surah.id);
            if (context.mounted) await context.read<ProgressCubit>().load();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(s.surahName(surahDisplayName(context, progress)), style: context.text.titleMedium),
                    ),
                    if (progress.isComplete)
                      Icon(Icons.verified_rounded, color: context.colors.primary, semanticLabel: s.mashaAllah),
                    Text(
                      s.ayahsOfTotal(progress.memorizedCount, progress.totalCount),
                      style: context.text.bodyMedium?.copyWith(color: context.ayahColors.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SurahProgressBar(progress: progress),
                const SizedBox(height: AppSpacing.sm),
                SurahLegend(progress: progress),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
