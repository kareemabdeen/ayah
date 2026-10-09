import 'package:ayah/core/services/storage/in_memory_local_store.dart';
import 'package:ayah/features/onboarding/data/repositories/preferences_repository_impl.dart';
import 'package:ayah/features/onboarding/domain/entities/user_preferences.dart';
import 'package:ayah/features/onboarding/domain/usecases/preferences_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  test('mapper round-trips every field', () {
    const prefs = UserPreferences(
      onboardingCompleted: true,
      dailyGoal: 5,
      preferredTime: PreferredTime.beforeSleep,
      startingPoint: StartingPoint.chosenSurah,
      startingSurahId: 67,
      reminderEnabled: false,
      reminderHour: 21,
      reminderMinute: 15,
      localeCode: 'en',
    );
    expect(PreferencesMapper.fromJson(PreferencesMapper.toJson(prefs)), prefs);
  });

  test('unknown or missing fields fall back to defaults (forward compatible)', () {
    final p = PreferencesMapper.fromJson({'dailyGoal': 2, 'preferredTime': 'midnightSnack'});
    expect(p.dailyGoal, 2);
    expect(p.preferredTime, const UserPreferences().preferredTime);
  });

  group('UpdateUserPreferencesUseCase', () {
    late FakeReminderService reminders;
    late PreferencesRepositoryImpl repo;
    late UpdateUserPreferencesUseCase update;

    setUp(() {
      reminders = FakeReminderService();
      repo = PreferencesRepositoryImpl(InMemoryLocalStore());
      update = UpdateUserPreferencesUseCase(repository: repo, scheduleReminder: ScheduleDailyReminderUseCase(reminders));
    });

    test('completing onboarding saves, asks permission, and schedules at the preferred time', () async {
      final saved = await update.completeOnboarding(const UserPreferences(preferredTime: PreferredTime.afterMaghrib));
      expect(saved.onboardingCompleted, isTrue);
      expect((await repo.load()).onboardingCompleted, isTrue);
      expect(reminders.permissionRequested, isTrue);
      expect(reminders.scheduled.single.hour, PreferredTime.afterMaghrib.defaultHour);
      expect(reminders.scheduled.single.minute, PreferredTime.afterMaghrib.defaultMinute);
      expect(reminders.scheduled.single.content.bodies, isNotEmpty);
    });

    test('disabling the reminder cancels it', () async {
      final saved = await update.completeOnboarding(const UserPreferences());
      await update(saved.copyWith(reminderEnabled: false));
      expect(reminders.cancelCount, 1);
    });

    test('changing only the daily goal does not reschedule', () async {
      final saved = await update.completeOnboarding(const UserPreferences());
      await update(saved.copyWith(dailyGoal: 2));
      expect(reminders.scheduled.length, 1);
    });
  });
}
