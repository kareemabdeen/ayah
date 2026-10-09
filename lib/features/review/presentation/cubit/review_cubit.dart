import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../progress/domain/usecases/record_session_use_case.dart';
import '../../../quran/domain/usecases/verse_audio_use_cases.dart';
import '../../../quran/presentation/playback_view_state.dart';
import '../../domain/entities/review_item.dart';
import '../../domain/entities/review_schedule.dart';
import '../../domain/usecases/get_surah_test_items_use_case.dart';
import '../../domain/usecases/get_today_review_items_use_case.dart';
import '../../domain/usecases/submit_review_result_use_case.dart';

enum ReviewStatus { loading, intro, recalling, revealed, finished, empty, failure }

final class ReviewState extends Equatable {
  const ReviewState({
    this.status = ReviewStatus.loading,
    this.queue = ReviewQueue.empty,
    this.items = const [],
    this.index = 0,
    this.retriedIds = const {},
    this.hintWords = 0,
    this.showForgotNote = false,
    this.surahTestId,
    this.isSubmitting = false,
    this.failure,
    this.playback = const PlaybackViewState(),
  });

  static const int maxHintWords = 3;

  final ReviewStatus status;
  final ReviewQueue queue;

  /// Working list; a forgotten ayah is appended once more at the end.
  final List<ReviewItem> items;
  final int index;
  final Set<String> retriedIds;
  final int hintWords;
  final bool showForgotNote;
  final int? surahTestId;
  final bool isSubmitting;
  final Failure? failure;
  final PlaybackViewState playback;

  bool get isSurahTest => surahTestId != null;
  ReviewItem? get current => index < items.length ? items[index] : null;
  int get estimatedMinutes => queue.items.length * AppConstants.timePerReview.inMinutes;

  ReviewState copyWith({
    ReviewStatus? status,
    ReviewQueue? queue,
    List<ReviewItem>? items,
    int? index,
    Set<String>? retriedIds,
    int? hintWords,
    bool? showForgotNote,
    int? Function()? surahTestId,
    bool? isSubmitting,
    Failure? failure,
    PlaybackViewState? playback,
  }) =>
      ReviewState(
        status: status ?? this.status,
        queue: queue ?? this.queue,
        items: items ?? this.items,
        index: index ?? this.index,
        retriedIds: retriedIds ?? this.retriedIds,
        hintWords: hintWords ?? this.hintWords,
        showForgotNote: showForgotNote ?? this.showForgotNote,
        surahTestId: surahTestId != null ? surahTestId() : this.surahTestId,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        failure: failure ?? this.failure,
        playback: playback ?? this.playback,
      );

  @override
  List<Object?> get props => [
        status,
        queue,
        items,
        index,
        retriedIds,
        hintWords,
        showForgotNote,
        surahTestId,
        isSubmitting,
        failure,
        playback,
      ];
}

final class ReviewCubit extends Cubit<ReviewState> {
  ReviewCubit({
    required GetTodayReviewItemsUseCase getTodayItems,
    required GetSurahTestItemsUseCase getSurahTestItems,
    required SubmitReviewResultUseCase submitResult,
    required RecordSessionUseCase recordSession,
    required PlayVerseAudioUseCase playAudio,
    required ControlPlaybackUseCase controlPlayback,
  })  : _getTodayItems = getTodayItems,
        _getSurahTestItems = getSurahTestItems,
        _submitResult = submitResult,
        _recordSession = recordSession,
        super(const ReviewState()) {
    _audio = VerseAudioController(
      play: playAudio,
      control: controlPlayback,
      onChanged: (p) {
        if (!isClosed) emit(state.copyWith(playback: p));
      },
    );
  }

  final GetTodayReviewItemsUseCase _getTodayItems;
  final GetSurahTestItemsUseCase _getSurahTestItems;
  final SubmitReviewResultUseCase _submitResult;
  final RecordSessionUseCase _recordSession;
  late final VerseAudioController _audio;

  Future<void> load({int? surahTestId}) async {
    emit(state.copyWith(status: ReviewStatus.loading, surahTestId: () => surahTestId));
    final Result<ReviewQueue> result =
        surahTestId == null ? await _getTodayItems() : await _getSurahTestItems(surahTestId);
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(status: ReviewStatus.failure, failure: f)),
      (queue) => emit(state.copyWith(
        status: queue.isEmpty ? ReviewStatus.empty : ReviewStatus.intro,
        queue: queue,
        items: queue.items,
        index: 0,
        retriedIds: const {},
      )),
    );
  }

  void begin() {
    if (state.status == ReviewStatus.intro) emit(state.copyWith(status: ReviewStatus.recalling, hintWords: 0));
  }

  void showHint() {
    if (state.status != ReviewStatus.recalling || state.hintWords >= ReviewState.maxHintWords) return;
    emit(state.copyWith(hintWords: state.hintWords + 1));
  }

  void reveal() {
    if (state.status == ReviewStatus.recalling) {
      emit(state.copyWith(status: ReviewStatus.revealed, showForgotNote: false));
    }
  }

  Future<void> togglePlay() async {
    final item = state.current;
    if (item == null) return;
    state.playback.isPlaying ? await _audio.pause() : await _audio.play(item.verse);
  }

  Future<void> rate(ReviewRating rating) async {
    final item = state.current;
    if (state.status != ReviewStatus.revealed || item == null || state.isSubmitting) return;
    emit(state.copyWith(isSubmitting: true));
    await _audio.stop();

    final isRetry = state.retriedIds.contains(item.verse.id);
    final updated = await _submitResult(
      item,
      rating,
      countsTowardDailyLimit: !state.isSurahTest && !isRetry,
    );
    if (isClosed) return;

    var items = [...state.items]..[state.index] = updated;
    var retried = state.retriedIds;
    final forgot = rating == ReviewRating.forgot;
    if (forgot && !isRetry) {
      // Bring it back once at the end of this session, gently.
      items = [...items, updated];
      retried = {...retried, item.verse.id};
    }

    final nextIndex = state.index + 1;
    if (nextIndex >= items.length) {
      emit(state.copyWith(status: ReviewStatus.finished, items: items, index: nextIndex, isSubmitting: false));
      await _recordSession(
        type: state.isSurahTest ? 'surah_test' : 'review',
        startedAt: state.queue.startedAt ?? DateTime.now(),
        verseIds: [for (final i in state.queue.items) i.verse.id],
      );
      return;
    }
    emit(state.copyWith(
      status: ReviewStatus.recalling,
      items: items,
      index: nextIndex,
      retriedIds: retried,
      hintWords: 0,
      showForgotNote: forgot,
      isSubmitting: false,
    ));
  }

  @override
  Future<void> close() async {
    await _audio.dispose();
    return super.close();
  }
}
