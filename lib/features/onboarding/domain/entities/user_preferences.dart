import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

enum PreferredTime {
  afterFajr(5, 30),
  morning(9, 0),
  afternoon(15, 0),
  afterMaghrib(18, 30),
  beforeSleep(22, 0);

  const PreferredTime(this.defaultHour, this.defaultMinute);

  /// Suggested reminder time; the user can change it in Settings.
  final int defaultHour;
  final int defaultMinute;
}

enum StartingPoint {
  alFatihah,
  juzAmma,
  chosenSurah,

  /// "Let Ayah choose" — we pick the gentlest path (Al-Fatihah → Juz Amma).
  letAyahChoose,
}

final class UserPreferences extends Equatable {
  const UserPreferences({
    this.onboardingCompleted = false,
    this.dailyGoal = AppConstants.defaultDailyGoal,
    this.preferredTime = PreferredTime.afterFajr,
    this.startingPoint = StartingPoint.letAyahChoose,
    this.startingSurahId,
    this.reminderEnabled = true,
    this.reminderHour = 5,
    this.reminderMinute = 30,
    this.localeCode = 'ar',
  });

  final bool onboardingCompleted;

  /// New ayahs per day (1, 2 or 5).
  final int dailyGoal;
  final PreferredTime preferredTime;
  final StartingPoint startingPoint;

  /// Only used when [startingPoint] is [StartingPoint.chosenSurah].
  final int? startingSurahId;

  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  /// 'ar' or 'en'.
  final String localeCode;

  UserPreferences copyWith({
    bool? onboardingCompleted,
    int? dailyGoal,
    PreferredTime? preferredTime,
    StartingPoint? startingPoint,
    int? Function()? startingSurahId,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? localeCode,
  }) =>
      UserPreferences(
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        preferredTime: preferredTime ?? this.preferredTime,
        startingPoint: startingPoint ?? this.startingPoint,
        startingSurahId: startingSurahId != null ? startingSurahId() : this.startingSurahId,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        localeCode: localeCode ?? this.localeCode,
      );

  @override
  List<Object?> get props => [
        onboardingCompleted,
        dailyGoal,
        preferredTime,
        startingPoint,
        startingSurahId,
        reminderEnabled,
        reminderHour,
        reminderMinute,
        localeCode,
      ];
}
