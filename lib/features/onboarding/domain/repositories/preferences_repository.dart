import '../entities/user_preferences.dart';

abstract interface class PreferencesRepository {
  Future<UserPreferences> load();

  Future<void> save(UserPreferences preferences);
}
