import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/onboarding/domain/entities/user_preferences.dart';
import '../features/onboarding/domain/usecases/preferences_use_cases.dart';

/// App-wide state: the user's preferences (locale, onboarding flag, goal,
/// reminder). Every preference change goes through here so the whole app
/// (e.g. locale) reacts immediately.
final class AppState extends Equatable {
  const AppState({required this.preferences});

  final UserPreferences preferences;

  Locale get locale => Locale(preferences.localeCode);

  @override
  List<Object?> get props => [preferences];
}

final class AppCubit extends Cubit<AppState> {
  AppCubit({
    required UserPreferences initial,
    required UpdateUserPreferencesUseCase updatePreferences,
  })  : _update = updatePreferences,
        super(AppState(preferences: initial));

  final UpdateUserPreferencesUseCase _update;

  Future<void> updatePreferences(UserPreferences prefs) async {
    emit(AppState(preferences: prefs));
    await _update(prefs);
  }

  /// Called by onboarding after it persisted the final preferences.
  void preferencesReplaced(UserPreferences prefs) => emit(AppState(preferences: prefs));

  Future<void> setLocale(String code) => updatePreferences(state.preferences.copyWith(localeCode: code));
}
