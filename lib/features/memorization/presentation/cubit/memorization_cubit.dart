import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../quran/domain/usecases/verse_audio_use_cases.dart';
import '../../../quran/presentation/playback_view_state.dart';
import '../../domain/entities/memorization_session.dart';
import '../../domain/usecases/start_memorization_session_use_case.dart';
import '../../domain/usecases/submit_recall_result_use_case.dart';

enum MemorizationStatus {
  initial,
  loading,
  listening,
  repeating,
  recalling,

  /// "That's okay. Let's listen once more." — shown after "I forgot".
  forgotSupport,
  success,

  /// Nothing to memorize right now (goal already met).
  empty,
  failure,
}

final class MemorizationState extends Equatable {
  const MemorizationState({
    this.status = MemorizationStatus.initial,
    this.session,
    this.hintWords = 0,
    this.isSubmitting = false,
    this.failure,
    this.playback = const PlaybackViewState(),
  });

  static const int maxHintWords = 3;

  final MemorizationStatus status;
  final MemorizationSession? session;

  /// Words revealed during recall (gentle scaffolding, max [maxHintWords]).
  final int hintWords;
  final bool isSubmitting;
  final Failure? failure;
  final PlaybackViewState playback;

  /// 0 listen, 1 repeat, 2 recall — for the step indicator.
  int get stepIndex => switch (status) {
        MemorizationStatus.repeating => 1,
        MemorizationStatus.recalling => 2,
        _ => 0,
      };

  MemorizationState copyWith({
    MemorizationStatus? status,
    MemorizationSession? session,
    int? hintWords,
    bool? isSubmitting,
    Failure? failure,
    PlaybackViewState? playback,
  }) =>
      MemorizationState(
        status: status ?? this.status,
        session: session ?? this.session,
        hintWords: hintWords ?? this.hintWords,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        failure: failure ?? this.failure,
        playback: playback ?? this.playback,
      );

  @override
  List<Object?> get props => [status, session, hintWords, isSubmitting, failure, playback];
}

final class MemorizationCubit extends Cubit<MemorizationState> {
  MemorizationCubit({
    required StartMemorizationSessionUseCase startSession,
    required SubmitRecallResultUseCase submitRecall,
    required PlayVerseAudioUseCase playAudio,
    required ControlPlaybackUseCase controlPlayback,
  })  : _startSession = startSession,
        _submitRecall = submitRecall,
        super(const MemorizationState()) {
    _audio = VerseAudioController(
      play: playAudio,
      control: controlPlayback,
      onChanged: (p) {
        if (!isClosed) emit(state.copyWith(playback: p));
      },
    );
  }

  final StartMemorizationSessionUseCase _startSession;
  final SubmitRecallResultUseCase _submitRecall;
  late final VerseAudioController _audio;

  MemorizationSession get _session => state.session!;

  Future<void> start({bool extraVerse = false}) async {
    emit(state.copyWith(status: MemorizationStatus.loading));
    final result = await _startSession(extraVerse: extraVerse);
    if (isClosed) return;
    await result.fold(
      (f) async => emit(state.copyWith(status: MemorizationStatus.failure, failure: f)),
      (session) async {
        if (session.isEmpty) {
          emit(state.copyWith(status: MemorizationStatus.empty, session: session));
          return;
        }
        emit(state.copyWith(status: MemorizationStatus.listening, session: session));
        await _audio.play(session.current);
      },
    );
  }

  // ── Audio ────────────────────────────────────────────────────────
  Future<void> togglePlay() async {
    if (state.session == null || _session.isEmpty) return;
    state.playback.isPlaying ? await _audio.pause() : await _audio.play(_session.current);
  }

  Future<void> replay() async {
    if (state.session == null || _session.isEmpty) return;
    await _audio.replay(_session.current);
  }

  Future<void> toggleSlow() => _audio.toggleSlow();

  // ── Flow ─────────────────────────────────────────────────────────
  void goToRepeat() {
    if (state.status != MemorizationStatus.listening) return;
    emit(state.copyWith(status: MemorizationStatus.repeating, session: _session.startRepeating()));
  }

  Future<void> registerRepetition() async {
    if (state.status != MemorizationStatus.repeating) return;
    final next = _session.registerRepetition();
    emit(state.copyWith(session: next));
    // Queue the next round with the reciter automatically.
    if (!next.repetitionsSatisfied) await _audio.replay(next.current);
  }

  Future<void> goToRecall() async {
    if (state.status != MemorizationStatus.repeating) return;
    await _audio.stop();
    emit(state.copyWith(status: MemorizationStatus.recalling, session: _session.startRecall(), hintWords: 0));
  }

  void showHint() {
    if (state.status != MemorizationStatus.recalling || state.hintWords >= MemorizationState.maxHintWords) return;
    emit(state.copyWith(hintWords: state.hintWords + 1));
  }

  Future<void> submitRecall(RecallOutcome outcome) async {
    if (state.status != MemorizationStatus.recalling || state.isSubmitting) return;
    emit(state.copyWith(isSubmitting: true));
    final next = await _submitRecall(_session, selfReported: outcome);
    if (isClosed) return;

    final status = switch (next.step) {
      MemorizationStep.completed => MemorizationStatus.success,
      MemorizationStep.repeat => MemorizationStatus.repeating,
      MemorizationStep.recall => MemorizationStatus.recalling,
      MemorizationStep.listen =>
        outcome == RecallOutcome.forgot ? MemorizationStatus.forgotSupport : MemorizationStatus.listening,
    };
    emit(state.copyWith(status: status, session: next, isSubmitting: false, hintWords: 0));

    if (status != MemorizationStatus.success) await _audio.play(next.current);
  }

  /// From the supportive "That's okay" moment back to listening.
  void continueAfterForgot() {
    if (state.status == MemorizationStatus.forgotSupport) {
      emit(state.copyWith(status: MemorizationStatus.listening));
    }
  }

  @override
  Future<void> close() async {
    await _audio.dispose();
    return super.close();
  }
}
