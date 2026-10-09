import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_cubit.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/calm_page.dart';
import '../../../quran/presentation/widgets/surah_picker_sheet.dart';
import '../../domain/entities/user_preferences.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/choice_tile.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _finish(BuildContext context) async {
    final saved = await context.read<OnboardingCubit>().finish();
    if (saved == null || !context.mounted) return;
    context.read<AppCubit>().preferencesReplaced(saved);
    await Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        final s = context.s;
        final step = switch (state.page) {
          0 => const _WelcomeStep(),
          1 => _GoalStep(state: state),
          2 => _TimeStep(state: state),
          _ => _StartStep(state: state),
        };
        final primaryLabel = state.page == 0 ? s.onbStart : (state.isLastPage ? s.onbBegin : s.next);
        final busy = state.status != OnboardingStatus.editing;

        return PopScope(
          canPop: state.page == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.back();
          },
          child: CalmPage(
            body: AnimatedSwitcher(
              duration: AppDurations.of(context, AppDurations.normal),
              child: KeyedSubtree(key: ValueKey(state.page), child: step),
            ),
            bottom: Row(
              children: [
                if (state.page > 0) ...[
                  TextButton(onPressed: busy ? null : cubit.back, child: Text(s.back)),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: busy || !state.canContinue
                        ? null
                        : state.isLastPage
                            ? () => _finish(context)
                            : cubit.next,
                    child: Text(primaryLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: context.text.headlineSmall)),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hint!, style: context.text.bodyLarge?.copyWith(color: context.ayahColors.inkMuted)),
          ],
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final app = context.read<AppCubit>();
    return Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              final code = app.state.preferences.localeCode == 'ar' ? 'en' : 'ar';
              context.read<OnboardingCubit>().setLocale(code);
              app.preferencesReplaced(app.state.preferences.copyWith(localeCode: code));
            },
            child: Text(s.languageToggle),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(s.appName, style: context.text.displayMedium?.copyWith(color: context.colors.primary)),
        const SizedBox(height: AppSpacing.xl),
        Text(s.onbWelcomeTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          s.onbWelcomeBody,
          textAlign: TextAlign.center,
          style: context.text.titleMedium?.copyWith(color: context.ayahColors.inkMuted, height: 1.8),
        ),
      ],
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.state});
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<OnboardingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(title: s.onbGoalTitle, hint: s.onbChangeLater),
        for (final goal in AppConstants.dailyGoalOptions)
          ChoiceTile(
            label: s.goalOption(goal),
            selected: state.draft.dailyGoal == goal,
            onTap: () => cubit.selectDailyGoal(goal),
          ),
      ],
    );
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({required this.state});
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<OnboardingCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(title: s.onbTimeTitle, hint: s.onbTimeHint),
        for (final time in PreferredTime.values)
          ChoiceTile(
            label: preferredTimeLabel(s, time),
            selected: state.draft.preferredTime == time,
            onTap: () => cubit.selectPreferredTime(time),
          ),
      ],
    );
  }
}

String preferredTimeLabel(AppStrings s, PreferredTime t) => switch (t) {
      PreferredTime.afterFajr => s.timeAfterFajr,
      PreferredTime.morning => s.timeMorning,
      PreferredTime.afternoon => s.timeAfternoon,
      PreferredTime.afterMaghrib => s.timeAfterMaghrib,
      PreferredTime.beforeSleep => s.timeBeforeSleep,
    };

class _StartStep extends StatelessWidget {
  const _StartStep({required this.state});
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cubit = context.read<OnboardingCubit>();
    final point = state.draft.startingPoint;
    final chosenId = state.draft.startingSurahId;
    final isArabic = state.draft.localeCode == 'ar';
    final chosenName = chosenId == null
        ? null
        : (isArabic ? state.surahs[chosenId - 1].nameArabic : state.surahs[chosenId - 1].nameTransliterated);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(title: s.onbStartTitle),
        ChoiceTile(
          label: s.startLetAyahChoose,
          subtitle: s.startLetAyahChooseHint,
          selected: point == StartingPoint.letAyahChoose,
          onTap: () => cubit.selectStartingPoint(StartingPoint.letAyahChoose),
        ),
        ChoiceTile(
          label: s.startFatihah,
          selected: point == StartingPoint.alFatihah,
          onTap: () => cubit.selectStartingPoint(StartingPoint.alFatihah),
        ),
        ChoiceTile(
          label: s.startJuzAmma,
          selected: point == StartingPoint.juzAmma,
          onTap: () => cubit.selectStartingPoint(StartingPoint.juzAmma),
        ),
        ChoiceTile(
          label: s.startChooseSurah,
          subtitle: point == StartingPoint.chosenSurah ? chosenName : null,
          selected: point == StartingPoint.chosenSurah,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            final id = await showSurahPicker(context, surahs: state.surahs, selectedId: chosenId);
            if (id != null) cubit.selectStartingPoint(StartingPoint.chosenSurah, surahId: id);
          },
        ),
      ],
    );
  }
}
