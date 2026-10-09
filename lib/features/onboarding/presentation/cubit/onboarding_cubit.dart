import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../quran/domain/entities/surah.dart';
import '../../../quran/domain/usecases/get_surahs_use_case.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/usecases/preferences_use_cases.dart';

enum OnboardingStatus { editing, saving, completed }

final class OnboardingState extends Equatable {
  const OnboardingState({
    this.page = 0,
    this.draft = const UserPreferences(),
    this.surahs = const [],
    this.status = OnboardingStatus.editing,
  });

  static const int pageCount = 4;

  final int page;
  final UserPreferences draft;
  final List<Surah> surahs;
  final OnboardingStatus status;

  bool get isLastPage => page == pageCount - 1;

  /// "Choose a Surah" needs an actual surah before continuing.
  bool get canContinue => draft.startingPoint != StartingPoint.chosenSurah || draft.startingSurahId != null;

  OnboardingState copyWith({int? page, UserPreferences? draft, List<Surah>? surahs, OnboardingStatus? status}) =>
      OnboardingState(
        page: page ?? this.page,
        draft: draft ?? this.draft,
        surahs: surahs ?? this.surahs,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [page, draft, surahs, status];
}

final class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required UpdateUserPreferencesUseCase updatePreferences, required GetSurahsUseCase getSurahs})
      : _update = updatePreferences,
        super(OnboardingState(surahs: getSurahs()));

  final UpdateUserPreferencesUseCase _update;

  void next() {
    if (!state.isLastPage) emit(state.copyWith(page: state.page + 1));
  }

  void back() {
    if (state.page > 0) emit(state.copyWith(page: state.page - 1));
  }

  void setLocale(String code) => emit(state.copyWith(draft: state.draft.copyWith(localeCode: code)));

  void selectDailyGoal(int goal) => emit(state.copyWith(draft: state.draft.copyWith(dailyGoal: goal)));

  void selectPreferredTime(PreferredTime time) =>
      emit(state.copyWith(draft: state.draft.copyWith(preferredTime: time)));

  void selectStartingPoint(StartingPoint point, {int? surahId}) => emit(state.copyWith(
        draft: state.draft.copyWith(
          startingPoint: point,
          startingSurahId: () => point == StartingPoint.chosenSurah ? surahId : null,
        ),
      ));

  /// Persists preferences, schedules the reminder, returns the saved prefs.
  Future<UserPreferences?> finish() async {
    if (state.status != OnboardingStatus.editing || !state.canContinue) return null;
    emit(state.copyWith(status: OnboardingStatus.saving));
    final saved = await _update.completeOnboarding(state.draft);
    emit(state.copyWith(draft: saved, status: OnboardingStatus.completed));
    return saved;
  }
}
