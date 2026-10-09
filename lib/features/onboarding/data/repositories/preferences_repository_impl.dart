import '../../../../core/services/storage/local_store.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';

final class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._store);

  final LocalStore _store;
  static const String _key = 'user';

  @override
  Future<UserPreferences> load() async {
    final raw = await _store.read(StoreCollections.preferences, _key);
    return raw == null ? const UserPreferences() : PreferencesMapper.fromJson(raw);
  }

  @override
  Future<void> save(UserPreferences preferences) =>
      _store.write(StoreCollections.preferences, _key, PreferencesMapper.toJson(preferences));
}

/// Tolerant mapping: unknown/missing fields fall back to defaults so
/// adding fields never breaks existing installs.
abstract final class PreferencesMapper {
  static const _defaults = UserPreferences();

  static Map<String, dynamic> toJson(UserPreferences p) => {
        'onboardingCompleted': p.onboardingCompleted,
        'dailyGoal': p.dailyGoal,
        'preferredTime': p.preferredTime.name,
        'startingPoint': p.startingPoint.name,
        'startingSurahId': p.startingSurahId,
        'reminderEnabled': p.reminderEnabled,
        'reminderHour': p.reminderHour,
        'reminderMinute': p.reminderMinute,
        'localeCode': p.localeCode,
      };

  static UserPreferences fromJson(Map<String, dynamic> j) => UserPreferences(
        onboardingCompleted: j['onboardingCompleted'] as bool? ?? _defaults.onboardingCompleted,
        dailyGoal: j['dailyGoal'] as int? ?? _defaults.dailyGoal,
        preferredTime: _enum(PreferredTime.values, j['preferredTime'], _defaults.preferredTime),
        startingPoint: _enum(StartingPoint.values, j['startingPoint'], _defaults.startingPoint),
        startingSurahId: j['startingSurahId'] as int?,
        reminderEnabled: j['reminderEnabled'] as bool? ?? _defaults.reminderEnabled,
        reminderHour: j['reminderHour'] as int? ?? _defaults.reminderHour,
        reminderMinute: j['reminderMinute'] as int? ?? _defaults.reminderMinute,
        localeCode: j['localeCode'] as String? ?? _defaults.localeCode,
      );

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;
}
