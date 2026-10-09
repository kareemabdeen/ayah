import 'package:ayah/core/services/storage/in_memory_local_store.dart';
import 'package:ayah/core/utils/clock.dart';
import 'package:ayah/features/memorization/domain/services/recitation_evaluator.dart';
import 'package:ayah/features/memorization/domain/usecases/get_daily_verse_use_case.dart';
import 'package:ayah/features/memorization/domain/usecases/mark_verse_memorized_use_case.dart';
import 'package:ayah/features/memorization/domain/usecases/start_memorization_session_use_case.dart';
import 'package:ayah/features/memorization/domain/usecases/submit_recall_result_use_case.dart';
import 'package:ayah/features/onboarding/data/repositories/preferences_repository_impl.dart';
import 'package:ayah/features/onboarding/domain/entities/user_preferences.dart';
import 'package:ayah/features/onboarding/domain/usecases/preferences_use_cases.dart';
import 'package:ayah/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:ayah/features/progress/domain/usecases/get_surah_progress_use_case.dart';
import 'package:ayah/features/progress/domain/usecases/get_user_progress_use_case.dart';
import 'package:ayah/features/progress/domain/usecases/record_session_use_case.dart';
import 'package:ayah/features/quran/domain/usecases/verse_audio_use_cases.dart';
import 'package:ayah/features/review/domain/services/review_queue_policy.dart';
import 'package:ayah/features/review/domain/services/review_scheduler.dart';
import 'package:ayah/features/review/domain/usecases/get_surah_test_items_use_case.dart';
import 'package:ayah/features/review/domain/usecases/get_today_review_items_use_case.dart';
import 'package:ayah/features/review/domain/usecases/submit_review_result_use_case.dart';

import 'fakes.dart';

/// Real use cases + real repositories over an in-memory store and a
/// controllable clock. Only Quran content, audio and reminders are faked.
final class TestEnv {
  TestEnv({DateTime? now, int maxDailyReviews = 10})
      : clock = FixedClock(now ?? DateTime(2026, 3, 10, 8)),
        policy = ReviewQueuePolicy(maxDailyReviews: maxDailyReviews);

  final FixedClock clock;
  final store = InMemoryLocalStore();
  final quran = FakeQuranRepository();
  final audio = FakeAudioPlayerService();
  final reminders = FakeReminderService();
  final scheduler = const LadderReviewScheduler();
  final ReviewQueuePolicy policy;

  late final preferencesRepo = PreferencesRepositoryImpl(store);
  late final progressRepo = ProgressRepositoryImpl(store);

  late final scheduleReminder = ScheduleDailyReminderUseCase(reminders);
  late final updatePreferences =
      UpdateUserPreferencesUseCase(repository: preferencesRepo, scheduleReminder: scheduleReminder);
  late final getDailyVerse =
      GetDailyVerseUseCase(preferences: preferencesRepo, progress: progressRepo, quran: quran, clock: clock);
  late final startSession = StartMemorizationSessionUseCase(getDailyVerse: getDailyVerse, clock: clock);
  late final markMemorized = MarkVerseMemorizedUseCase(progress: progressRepo, scheduler: scheduler, clock: clock);
  late final submitRecall = SubmitRecallResultUseCase(
    evaluator: const SelfAssessmentEvaluator(),
    markMemorized: markMemorized,
    progress: progressRepo,
    clock: clock,
  );
  late final getTodayReviews =
      GetTodayReviewItemsUseCase(progress: progressRepo, quran: quran, policy: policy, clock: clock);
  late final getSurahTest = GetSurahTestItemsUseCase(progress: progressRepo, quran: quran, clock: clock);
  late final submitReview = SubmitReviewResultUseCase(progress: progressRepo, scheduler: scheduler, clock: clock);
  late final getUserProgress = GetUserProgressUseCase(progress: progressRepo, policy: policy, clock: clock);
  late final getSurahProgress =
      GetSurahProgressUseCase(progress: progressRepo, quran: quran, preferences: preferencesRepo, clock: clock);
  late final recordSession = RecordSessionUseCase(progress: progressRepo, clock: clock);
  late final playAudio = PlayVerseAudioUseCase(audio);
  late final controlPlayback = ControlPlaybackUseCase(audio);

  Future<void> savePrefs(UserPreferences prefs) => preferencesRepo.save(prefs.copyWith(onboardingCompleted: true));
}
