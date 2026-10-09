import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_cubit.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/calm_page.dart';

/// Minimal settings: goal, reminder, language. Backed by [AppCubit], which
/// persists through UpdateUserPreferencesUseCase (reminder resync included).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final prefs = state.preferences;
        final app = context.read<AppCubit>();
        final time = TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute);

        return CalmPage(
          appBar: AppBar(title: Text(s.settingsTitle)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(s.dailyGoal),
              SegmentedButton<int>(
                segments: [
                  for (final g in AppConstants.dailyGoalOptions)
                    ButtonSegment(value: g, label: Text(s.goalOption(g), maxLines: 1)),
                ],
                selected: {prefs.dailyGoal},
                onSelectionChanged: (v) => app.updatePreferences(prefs.copyWith(dailyGoal: v.first)),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.reminder),
                value: prefs.reminderEnabled,
                onChanged: (v) => app.updatePreferences(prefs.copyWith(reminderEnabled: v)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: prefs.reminderEnabled,
                title: Text(s.reminderTime),
                trailing: Text(time.format(context), style: context.text.titleMedium),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: time);
                  if (picked == null) return;
                  await app.updatePreferences(
                    prefs.copyWith(reminderHour: picked.hour, reminderMinute: picked.minute),
                  );
                },
              ),
              const Divider(),
              _SectionTitle(s.language),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'ar', label: Text(s.arabic)),
                  ButtonSegment(value: 'en', label: Text(s.english)),
                ],
                selected: {prefs.localeCode},
                onSelectionChanged: (v) => app.setLocale(v.first),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Semantics(
          header: true,
          child: Text(text, style: context.text.titleSmall?.copyWith(color: context.ayahColors.inkMuted)),
        ),
      );
}
