import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/audio_controls.dart';
import '../../../../core/widgets/calm_page.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/quran_verse.dart';
import '../../../../core/widgets/step_indicator.dart';
import '../../domain/entities/memorization_session.dart';
import '../cubit/memorization_cubit.dart';

/// Listen → Repeat → Recall, one task on screen at a time.
class MemorizationPage extends StatelessWidget {
  const MemorizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemorizationCubit, MemorizationState>(
      builder: (context, state) {
        final cubit = context.read<MemorizationCubit>();
        return switch (state.status) {
          MemorizationStatus.initial || MemorizationStatus.loading => const Scaffold(body: LoadingView()),
          MemorizationStatus.failure => Scaffold(
              appBar: AppBar(),
              body: FailureView(failure: state.failure!, onRetry: cubit.start),
            ),
          MemorizationStatus.empty => const _DoneForToday(),
          MemorizationStatus.success => _CompletionView(count: state.session!.completedVerseIds.length),
          MemorizationStatus.forgotSupport => _ForgotView(onContinue: cubit.continueAfterForgot),
          _ => _SessionView(state: state),
        };
      },
    );
  }
}

class _SessionView extends StatelessWidget {
  const _SessionView({required this.state});
  final MemorizationState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<MemorizationCubit>();
    final session = state.session!;
    final verse = session.current;
    final isRecall = state.status == MemorizationStatus.recalling;

    final instruction = switch (state.status) {
      MemorizationStatus.repeating => s.repeatWithReciter,
      MemorizationStatus.recalling => s.recallInstruction,
      _ => s.listenCarefully,
    };

    return CalmPage(
      appBar: AppBar(
        leading: CloseButton(onPressed: () => Navigator.of(context).maybePop()),
        title: session.total > 1 ? Text(s.verseCounter(session.index + 1, session.total)) : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepIndicator(labels: [s.stepListen, s.stepRepeat, s.stepRecall], current: state.stepIndex),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            liveRegion: true,
            child: Text(instruction, textAlign: TextAlign.center, style: context.text.titleLarge),
          ),
          const SizedBox(height: AppSpacing.lg),
          VerseCard(
            text: verse.arabicText,
            surahName: verse.surahName,
            ayahNumber: verse.ayahNumber,
            hidden: isRecall,
            hintWords: state.hintWords,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isRecall)
            Center(
              child: TextButton.icon(
                onPressed: state.hintWords < MemorizationState.maxHintWords ? cubit.showHint : null,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: Text(s.showFirstWord),
              ),
            )
          else ...[
            AudioControls(
              isPlaying: state.playback.isPlaying,
              isLoading: state.playback.isLoading,
              isSlow: state.playback.isSlow,
              onPlay: cubit.togglePlay,
              onPause: cubit.togglePlay,
              onReplay: cubit.replay,
              onToggleSlow: cubit.toggleSlow,
            ),
            if (state.status == MemorizationStatus.repeating) ...[
              const SizedBox(height: AppSpacing.lg),
              RepetitionDots(
                done: session.repetitionsDone,
                total: session.targetRepetitions,
                label: s.repetitionProgress(session.repetitionsDone, session.targetRepetitions),
              ),
            ],
          ],
        ],
      ),
      bottom: _ActionArea(state: state),
    );
  }
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({required this.state});
  final MemorizationState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<MemorizationCubit>();
    final session = state.session!;

    return switch (state.status) {
      MemorizationStatus.listening => FilledButton(onPressed: cubit.goToRepeat, child: Text(s.goRepeat)),
      MemorizationStatus.repeating => session.repetitionsSatisfied
          ? FilledButton(onPressed: cubit.goToRecall, child: Text(s.tryFromMemory))
          : FilledButton.tonal(onPressed: cubit.registerRepetition, child: Text(s.iRepeatedIt)),
      MemorizationStatus.recalling => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: state.isSubmitting ? null : () => cubit.submitRecall(RecallOutcome.remembered),
              child: Text(s.iRemembered),
            ),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              onPressed: state.isSubmitting ? null : () => cubit.submitRecall(RecallOutcome.needAnotherTry),
              child: Text(s.needAnotherTry),
            ),
            TextButton(
              onPressed: state.isSubmitting ? null : () => cubit.submitRecall(RecallOutcome.forgot),
              child: Text(s.iForgot),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ForgotView extends StatelessWidget {
  const _ForgotView({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return CalmPage(
      centerBody: true,
      body: SupportiveMessage(icon: Icons.spa_outlined, title: s.forgotTitle, body: s.forgotBody),
      bottom: FilledButton(onPressed: onContinue, child: Text(s.listenAgain)),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return CalmPage(
      centerBody: true,
      body: SupportiveMessage(
        icon: Icons.check_circle_outline_rounded,
        title: s.mashaAllah,
        body: '${s.memorizedToday}\n${s.reviewTomorrow}',
        extra: Chip(
          avatar: const Icon(Icons.menu_book_rounded),
          label: Text(s.memorizedTodayCount(count)),
          side: BorderSide(color: context.ayahColors.divider),
        ),
      ),
      bottom: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.finish)),
    );
  }
}

class _DoneForToday extends StatelessWidget {
  const _DoneForToday();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return CalmPage(
      centerBody: true,
      body: SupportiveMessage(icon: Icons.check_circle_outline_rounded, title: s.goalReachedTitle, body: s.goalReachedBody),
      bottom: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.backHome)),
    );
  }
}
