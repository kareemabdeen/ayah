import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/calm_page.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/quran_verse.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_summary_row.dart';

/// One screen, one primary action: start today's ayah (or review, once
/// the day's ayah is done). Everything else is secondary and quiet.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _open(BuildContext context, String route, {Object? args}) async {
    final cubit = context.read<HomeCubit>();
    await cubit.stopAudio();
    if (!context.mounted) return;
    await Navigator.of(context).pushNamed(route, arguments: args);
    await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final appBar = AppBar(
          leading: IconButton(
            tooltip: s.settingsTooltip,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _open(context, Routes.settings),
          ),
          actions: [
            IconButton(
              tooltip: s.progressTooltip,
              icon: const Icon(Icons.auto_stories_outlined),
              onPressed: () => _open(context, Routes.progress),
            ),
          ],
        );

        return switch (state.status) {
          HomeStatus.loading => Scaffold(appBar: appBar, body: const LoadingView()),
          HomeStatus.failure => Scaffold(
              appBar: appBar,
              body: FailureView(failure: state.failure!, onRetry: context.read<HomeCubit>().load),
            ),
          HomeStatus.ready => CalmPage(
              appBar: appBar,
              body: _HomeBody(state: state, onOpen: (r, {args}) => _open(context, r, args: args)),
              bottom: _PrimaryAction(state: state, onOpen: (r, {args}) => _open(context, r, args: args)),
            ),
        };
      },
    );
  }
}

typedef _Open = Future<void> Function(String route, {Object? args});

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state, required this.onOpen});

  final HomeState state;
  final _Open onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final plan = state.plan!;
    final summary = state.summary!;
    final verse = plan.todaysVerse;
    final muted = context.ayahColors.inkMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          state.isWelcomeBack ? s.welcomeBackTitle : s.greeting,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall,
        ),
        if (state.isWelcomeBack) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(s.welcomeBackBody, textAlign: TextAlign.center, style: context.text.bodyLarge?.copyWith(color: muted)),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (verse != null) ...[
          Text(s.todaysAyah, textAlign: TextAlign.center, style: context.text.titleMedium?.copyWith(color: muted)),
          const SizedBox(height: AppSpacing.sm),
          VerseCard(text: verse.arabicText, surahName: verse.surahName, ayahNumber: verse.ayahNumber),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinedButton.icon(
              onPressed: context.read<HomeCubit>().toggleListen,
              icon: Icon(state.playback.isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded),
              label: Text(state.playback.isPlaying ? s.pause : s.listen),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: SupportiveMessage(
              icon: Icons.check_circle_outline_rounded,
              title: plan.isQuranComplete ? s.quranCompleteTitle : s.goalReachedTitle,
              body: plan.isQuranComplete ? s.quranCompleteBody : s.goalReachedBody,
              extra: plan.isQuranComplete
                  ? null
                  : TextButton(
                      onPressed: () => onOpen(Routes.memorize, args: const MemorizeArgs(extraVerse: true)),
                      child: Text(s.oneMoreAyah),
                    ),
            ),
          ),
        // A quiet review prompt while today's ayah is still pending.
        if (verse != null && summary.dueReviewCount > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(s.reviewWaiting(summary.dueReviewCount)),
              subtitle: Text(s.minutes(state.reviewMinutes)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onOpen(Routes.review),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        HomeSummaryRow(summary: summary),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.state, required this.onOpen});

  final HomeState state;
  final _Open onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final hasVerse = state.plan?.todaysVerse != null;
    final dueReviews = state.summary?.dueReviewCount ?? 0;

    if (!hasVerse && dueReviews == 0) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: () => hasVerse ? onOpen(Routes.memorize) : onOpen(Routes.review),
          child: Text(hasVerse ? s.startMemorizing : s.startReview),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasVerse ? s.minutesToday(state.estimatedMinutes) : s.reviewWaiting(dueReviews),
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: context.ayahColors.inkMuted),
        ),
      ],
    );
  }
}
