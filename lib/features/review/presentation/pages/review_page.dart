import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/calm_page.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/quran_verse.dart';
import '../../domain/entities/review_schedule.dart';
import '../cubit/review_cubit.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewCubit, ReviewState>(
      builder: (context, state) {
        final cubit = context.read<ReviewCubit>();
        return switch (state.status) {
          ReviewStatus.loading => const Scaffold(body: LoadingView()),
          ReviewStatus.failure => Scaffold(
              appBar: AppBar(),
              body: FailureView(failure: state.failure!, onRetry: () => cubit.load(surahTestId: state.surahTestId)),
            ),
          ReviewStatus.empty => const _EmptyView(),
          ReviewStatus.intro => _IntroView(state: state),
          ReviewStatus.finished => const _FinishedView(),
          ReviewStatus.recalling || ReviewStatus.revealed => _ItemView(state: state),
        };
      },
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.state});
  final ReviewState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final count = state.queue.items.length;
    final lines = <String>[
      if (state.queue.isReturningAfterBreak) s.welcomeBackReview,
      s.reviewCount(count),
      s.estimatedTime(state.estimatedMinutes),
      if (!state.isSurahTest && state.queue.deferredCount > 0) s.deferredNote,
    ];
    return CalmPage(
      appBar: AppBar(leading: const CloseButton()),
      centerBody: true,
      body: SupportiveMessage(
        icon: Icons.history_rounded,
        title: state.isSurahTest ? s.surahTestTitle : s.reviewTitle,
        body: lines.join('\n'),
      ),
      bottom: FilledButton(onPressed: context.read<ReviewCubit>().begin, child: Text(s.startReview)),
    );
  }
}

class _ItemView extends StatelessWidget {
  const _ItemView({required this.state});
  final ReviewState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<ReviewCubit>();
    final item = state.current!;
    final revealed = state.status == ReviewStatus.revealed;
    final muted = context.ayahColors.inkMuted;

    return CalmPage(
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text(s.verseCounter(state.index + 1, state.items.length)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.showForgotNote && !revealed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(s.forgotInReview, textAlign: TextAlign.center, style: context.text.bodyLarge?.copyWith(color: muted)),
            ),
          Semantics(
            liveRegion: true,
            child: Text(
              revealed ? s.howDidItFeel : s.reviewRecallInstruction,
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          VerseCard(
            text: item.verse.arabicText,
            surahName: item.verse.surahName,
            ayahNumber: item.verse.ayahNumber,
            hidden: !revealed,
            hintWords: state.hintWords,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: revealed
                ? OutlinedButton.icon(
                    onPressed: cubit.togglePlay,
                    icon: Icon(state.playback.isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded),
                    label: Text(state.playback.isPlaying ? s.pause : s.listen),
                  )
                : TextButton.icon(
                    onPressed: state.hintWords < ReviewState.maxHintWords ? cubit.showHint : null,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: Text(s.showFirstWord),
                  ),
          ),
        ],
      ),
      bottom: revealed
          ? _RatingButtons(enabled: !state.isSubmitting, onRate: cubit.rate)
          : FilledButton(onPressed: cubit.reveal, child: Text(s.revealAyah)),
    );
  }
}

/// Four honest choices. "I forgot" is a normal option, not a red alarm.
class _RatingButtons extends StatelessWidget {
  const _RatingButtons({required this.enabled, required this.onRate});

  final bool enabled;
  final Future<void> Function(ReviewRating) onRate;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget button(ReviewRating r, String label, IconData icon) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: OutlinedButton(
              onPressed: enabled ? () => onRate(r) : null,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(icon), const SizedBox(height: AppSpacing.xxs), Text(label, maxLines: 1)],
              ),
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          button(ReviewRating.easy, s.rateEasy, Icons.sentiment_very_satisfied_rounded),
          button(ReviewRating.good, s.rateGood, Icons.sentiment_satisfied_rounded),
        ]),
        Row(children: [
          button(ReviewRating.hard, s.rateHard, Icons.sentiment_neutral_rounded),
          button(ReviewRating.forgot, s.rateForgot, Icons.replay_rounded),
        ]),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return CalmPage(
      centerBody: true,
      body: SupportiveMessage(icon: Icons.spa_outlined, title: s.noReviewTitle, body: s.noReviewBody),
      bottom: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.backHome)),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return CalmPage(
      centerBody: true,
      body: SupportiveMessage(icon: Icons.check_circle_outline_rounded, title: s.mashaAllah, body: s.reviewDoneBody),
      bottom: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.finish)),
    );
  }
}
