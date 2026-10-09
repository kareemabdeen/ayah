import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/services/audio/audio_player_service.dart';
import '../core/services/audio/just_audio_player_service.dart';
import '../core/services/notifications/local_reminder_service.dart';
import '../core/services/notifications/reminder_service.dart';
import '../core/services/storage/hive_local_store.dart';
import '../core/services/storage/local_store.dart';
import '../core/utils/clock.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/memorization/domain/services/recitation_evaluator.dart';
import '../features/memorization/domain/usecases/get_daily_verse_use_case.dart';
import '../features/memorization/domain/usecases/mark_verse_memorized_use_case.dart';
import '../features/memorization/domain/usecases/start_memorization_session_use_case.dart';
import '../features/memorization/domain/usecases/submit_recall_result_use_case.dart';
import '../features/memorization/presentation/cubit/memorization_cubit.dart';
import '../features/onboarding/data/repositories/preferences_repository_impl.dart';
import '../features/onboarding/domain/repositories/preferences_repository.dart';
import '../features/onboarding/domain/usecases/preferences_use_cases.dart';
import '../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../features/progress/data/repositories/progress_repository_impl.dart';
import '../features/progress/domain/repositories/progress_repository.dart';
import '../features/progress/domain/usecases/get_surah_progress_use_case.dart';
import '../features/progress/domain/usecases/get_user_progress_use_case.dart';
import '../features/progress/domain/usecases/record_session_use_case.dart';
import '../features/progress/presentation/cubit/progress_cubit.dart';
import '../features/progress/presentation/cubit/surah_progress_cubit.dart';
import '../features/quran/data/datasources/quran_local_data_source.dart';
import '../features/quran/data/datasources/quran_remote_data_source.dart';
import '../features/quran/data/repositories/quran_repository_impl.dart';
import '../features/quran/domain/repositories/quran_repository.dart';
import '../features/quran/domain/usecases/get_surahs_use_case.dart';
import '../features/quran/domain/usecases/verse_audio_use_cases.dart';
import '../features/review/domain/services/review_queue_policy.dart';
import '../features/review/domain/services/review_scheduler.dart';
import '../features/review/domain/usecases/get_surah_test_items_use_case.dart';
import '../features/review/domain/usecases/get_today_review_items_use_case.dart';
import '../features/review/domain/usecases/submit_review_result_use_case.dart';
import '../features/review/presentation/cubit/review_cubit.dart';

final GetIt sl = GetIt.instance;

/// Composition root. The only place that knows concrete implementations.
/// To swap a package (audio, DB, evaluator, scheduler), change one line here.
Future<void> configureDependencies({LocalStore? store, Clock clock = const SystemClock()}) async {
  // ── Infrastructure ──────────────────────────────────────────────
  sl
    ..registerSingleton<Clock>(clock)
    ..registerSingleton<LocalStore>(store ?? await HiveLocalStore.open())
    ..registerLazySingleton<http.Client>(http.Client.new)
    ..registerLazySingleton<AudioPlayerService>(JustAudioPlayerService.new)
    ..registerLazySingleton<ReminderService>(LocalReminderService.new)
    ..registerLazySingleton<RecitationEvaluator>(() => const SelfAssessmentEvaluator())
    ..registerLazySingleton<ReviewScheduler>(() => const LadderReviewScheduler())
    ..registerLazySingleton(() => const ReviewQueuePolicy(maxDailyReviews: AppConstants.maxDailyReviews));

  // ── Data ────────────────────────────────────────────────────────
  sl
    ..registerLazySingleton<QuranLocalDataSource>(() => CachedQuranLocalDataSource(sl()))
    ..registerLazySingleton<QuranRemoteDataSource>(() => AlQuranCloudRemoteDataSource(sl()))
    ..registerLazySingleton<QuranRepository>(() => QuranRepositoryImpl(local: sl(), remote: sl()))
    ..registerLazySingleton<PreferencesRepository>(() => PreferencesRepositoryImpl(sl()))
    ..registerLazySingleton<ProgressRepository>(() => ProgressRepositoryImpl(sl()));

  // ── Use cases ───────────────────────────────────────────────────
  sl
    ..registerLazySingleton(() => GetSurahsUseCase(sl()))
    ..registerLazySingleton(() => PlayVerseAudioUseCase(sl()))
    ..registerLazySingleton(() => ControlPlaybackUseCase(sl()))
    ..registerLazySingleton(() => GetUserPreferencesUseCase(sl()))
    ..registerLazySingleton(() => ScheduleDailyReminderUseCase(sl()))
    ..registerLazySingleton(() => UpdateUserPreferencesUseCase(repository: sl(), scheduleReminder: sl()))
    ..registerLazySingleton(() => GetDailyVerseUseCase(preferences: sl(), progress: sl(), quran: sl(), clock: sl()))
    ..registerLazySingleton(() => StartMemorizationSessionUseCase(getDailyVerse: sl(), clock: sl()))
    ..registerLazySingleton(() => MarkVerseMemorizedUseCase(progress: sl(), scheduler: sl(), clock: sl()))
    ..registerLazySingleton(
      () => SubmitRecallResultUseCase(evaluator: sl(), markMemorized: sl(), progress: sl(), clock: sl()),
    )
    ..registerLazySingleton(
      () => GetTodayReviewItemsUseCase(progress: sl(), quran: sl(), policy: sl(), clock: sl()),
    )
    ..registerLazySingleton(() => GetSurahTestItemsUseCase(progress: sl(), quran: sl(), clock: sl()))
    ..registerLazySingleton(() => SubmitReviewResultUseCase(progress: sl(), scheduler: sl(), clock: sl()))
    ..registerLazySingleton(() => GetUserProgressUseCase(progress: sl(), policy: sl(), clock: sl()))
    ..registerLazySingleton(
      () => GetSurahProgressUseCase(progress: sl(), quran: sl(), preferences: sl(), clock: sl()),
    )
    ..registerLazySingleton(() => RecordSessionUseCase(progress: sl(), clock: sl()));

  // ── Presentation (fresh instance per screen) ────────────────────
  sl
    ..registerFactory(() => OnboardingCubit(updatePreferences: sl(), getSurahs: sl()))
    ..registerFactory(
      () => HomeCubit(getDailyVerse: sl(), getUserProgress: sl(), playAudio: sl(), controlPlayback: sl()),
    )
    ..registerFactory(
      () => MemorizationCubit(startSession: sl(), submitRecall: sl(), playAudio: sl(), controlPlayback: sl()),
    )
    ..registerFactory(
      () => ReviewCubit(
        getTodayItems: sl(),
        getSurahTestItems: sl(),
        submitResult: sl(),
        recordSession: sl(),
        playAudio: sl(),
        controlPlayback: sl(),
      ),
    )
    ..registerFactory(() => ProgressCubit(getSurahProgress: sl()))
    ..registerFactory(() => SurahProgressCubit(getSurahProgress: sl()));
}
