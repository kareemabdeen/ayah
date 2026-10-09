import '../../../../core/constants/reminder_copy.dart';
import '../../../../core/services/notifications/reminder_service.dart';
import '../entities/user_preferences.dart';
import '../repositories/preferences_repository.dart';

final class GetUserPreferencesUseCase {
  const GetUserPreferencesUseCase(this._repository);
  final PreferencesRepository _repository;

  Future<UserPreferences> call() => _repository.load();
}

/// (Re)schedules — or cancels — the daily reminder to match preferences.
final class ScheduleDailyReminderUseCase {
  const ScheduleDailyReminderUseCase(this._reminders);
  final ReminderService _reminders;

  Future<void> call(UserPreferences prefs) async {
    if (!prefs.onboardingCompleted || !prefs.reminderEnabled) {
      await _reminders.cancelAll();
      return;
    }
    await _reminders.scheduleDaily(
      hour: prefs.reminderHour,
      minute: prefs.reminderMinute,
      content: ReminderCopy.forLocale(prefs.localeCode),
    );
  }

  Future<bool> requestPermission() => _reminders.requestPermission();
}

/// Saves preferences and keeps the reminder schedule in sync.
final class UpdateUserPreferencesUseCase {
  const UpdateUserPreferencesUseCase({
    required PreferencesRepository repository,
    required ScheduleDailyReminderUseCase scheduleReminder,
  })  : _repository = repository,
        _scheduleReminder = scheduleReminder;

  final PreferencesRepository _repository;
  final ScheduleDailyReminderUseCase _scheduleReminder;

  Future<UserPreferences> call(UserPreferences prefs) async {
    final previous = await _repository.load();
    await _repository.save(prefs);
    if (_reminderChanged(previous, prefs)) {
      try {
        await _scheduleReminder(prefs);
      } catch (_) {
        // A reminder failure must never block saving preferences.
      }
    }
    return prefs;
  }

  /// Completes onboarding: applies the chosen preferred time as the reminder.
  Future<UserPreferences> completeOnboarding(UserPreferences draft) async {
    final prefs = draft.copyWith(
      onboardingCompleted: true,
      reminderHour: draft.preferredTime.defaultHour,
      reminderMinute: draft.preferredTime.defaultMinute,
    );
    if (prefs.reminderEnabled) {
      try {
        await _scheduleReminder.requestPermission();
      } catch (_) {
        // Permission denied/unavailable: the app works fully without reminders.
      }
    }
    return call(prefs);
  }

  static bool _reminderChanged(UserPreferences a, UserPreferences b) =>
      a.onboardingCompleted != b.onboardingCompleted ||
      a.reminderEnabled != b.reminderEnabled ||
      a.reminderHour != b.reminderHour ||
      a.reminderMinute != b.reminderMinute ||
      a.localeCode != b.localeCode;
}
