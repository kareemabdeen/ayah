import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../memorization/domain/entities/daily_plan.dart';
import '../../../memorization/domain/usecases/get_daily_verse_use_case.dart';
import '../../../progress/domain/entities/daily_progress.dart';
import '../../../progress/domain/usecases/get_user_progress_use_case.dart';
import '../../../quran/domain/usecases/verse_audio_use_cases.dart';
import '../../../quran/presentation/playback_view_state.dart';

enum HomeStatus { loading, ready, failure }

final class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.plan,
    this.summary,
    this.failure,
    this.playback = const PlaybackViewState(),
  });

  final HomeStatus status;
  final DailyPlan? plan;
  final UserProgressSummary? summary;
  final Failure? failure;
  final PlaybackViewState playback;

  bool get isWelcomeBack =>
      (summary?.daysSinceLastActivity ?? 0) >= AppConstants.welcomeBackAfterDays;

  int get estimatedMinutes {
    final verses = plan?.remaining.length ?? 0;
    final minutes = verses * AppConstants.timePerNewVerse.inMinutes;
    return minutes == 0 ? AppConstants.timePerNewVerse.inMinutes : minutes;
  }

  int get reviewMinutes => (summary?.dueReviewCount ?? 0) * AppConstants.timePerReview.inMinutes;

  HomeState copyWith({
    HomeStatus? status,
    DailyPlan? plan,
    UserProgressSummary? summary,
    Failure? failure,
    PlaybackViewState? playback,
  }) =>
      HomeState(
        status: status ?? this.status,
        plan: plan ?? this.plan,
        summary: summary ?? this.summary,
        failure: failure,
        playback: playback ?? this.playback,
      );

  @override
  List<Object?> get props => [status, plan, summary, failure, playback];
}

final class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetDailyVerseUseCase getDailyVerse,
    required GetUserProgressUseCase getUserProgress,
    required PlayVerseAudioUseCase playAudio,
    required ControlPlaybackUseCase controlPlayback,
  })  : _getDailyVerse = getDailyVerse,
        _getUserProgress = getUserProgress,
        super(const HomeState()) {
    _audio = VerseAudioController(
      play: playAudio,
      control: controlPlayback,
      onChanged: (p) {
        if (!isClosed) emit(state.copyWith(playback: p, failure: state.failure));
      },
    );
  }

  final GetDailyVerseUseCase _getDailyVerse;
  final GetUserProgressUseCase _getUserProgress;
  late final VerseAudioController _audio;

  Future<void> load() async {
    if (state.plan == null) emit(state.copyWith(status: HomeStatus.loading));
    final summary = await _getUserProgress();
    final plan = await _getDailyVerse();
    if (isClosed) return;
    plan.fold(
      (f) => emit(state.copyWith(status: HomeStatus.failure, summary: summary, failure: f)),
      (p) => emit(state.copyWith(status: HomeStatus.ready, plan: p, summary: summary)),
    );
  }

  Future<void> stopAudio() => _audio.stop();

  /// Called when returning from a session.
  Future<void> refresh() async {
    await _audio.stop();
    await load();
  }

  Future<void> toggleListen() async {
    final verse = state.plan?.todaysVerse;
    if (verse == null) return;
    state.playback.isPlaying ? await _audio.pause() : await _audio.play(verse);
  }

  @override
  Future<void> close() async {
    await _audio.dispose();
    return super.close();
  }
}
