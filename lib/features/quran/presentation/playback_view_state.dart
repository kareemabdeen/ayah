import 'dart:async';

import 'package:equatable/equatable.dart';

import '../../../core/services/audio/audio_player_service.dart';
import '../domain/entities/verse.dart';
import '../domain/usecases/verse_audio_use_cases.dart';

/// What the UI needs to know about playback.
final class PlaybackViewState extends Equatable {
  const PlaybackViewState({this.isPlaying = false, this.isLoading = false, this.isSlow = false, this.hasError = false});

  final bool isPlaying;
  final bool isLoading;
  final bool isSlow;
  final bool hasError;

  PlaybackViewState copyWith({bool? isPlaying, bool? isLoading, bool? isSlow, bool? hasError}) => PlaybackViewState(
        isPlaying: isPlaying ?? this.isPlaying,
        isLoading: isLoading ?? this.isLoading,
        isSlow: isSlow ?? this.isSlow,
        hasError: hasError ?? this.hasError,
      );

  @override
  List<Object?> get props => [isPlaying, isLoading, isSlow, hasError];
}

/// Composable helper owned by a cubit: wraps the audio use cases and
/// reports [PlaybackViewState] changes. Keeps the three audio-using
/// cubits free of duplicated stream plumbing.
final class VerseAudioController {
  VerseAudioController({
    required PlayVerseAudioUseCase play,
    required ControlPlaybackUseCase control,
    required void Function(PlaybackViewState) onChanged,
  })  : _play = play,
        _control = control,
        _onChanged = onChanged {
    _sub = _control.watch().listen(_onSnapshot);
  }

  final PlayVerseAudioUseCase _play;
  final ControlPlaybackUseCase _control;
  final void Function(PlaybackViewState) _onChanged;
  late final StreamSubscription<PlaybackSnapshot> _sub;

  PlaybackViewState _state = const PlaybackViewState();
  PlaybackViewState get state => _state;

  void _set(PlaybackViewState next) {
    if (next == _state) return;
    _state = next;
    _onChanged(next);
  }

  void _onSnapshot(PlaybackSnapshot s) => _set(_state.copyWith(
        isPlaying: s.phase == PlaybackPhase.playing,
        isLoading: s.phase == PlaybackPhase.loading,
        hasError: s.phase == PlaybackPhase.error,
      ));

  Future<void> play(Verse verse) async {
    _set(_state.copyWith(isLoading: true, hasError: false));
    final result = await _play(verse, slow: _state.isSlow);
    if (!result.isSuccess) _set(_state.copyWith(isLoading: false, isPlaying: false, hasError: true));
  }

  Future<void> pause() => _control.pause();

  Future<void> replay(Verse verse) async {
    final playingThisVerse = _control.current.source == verse.audioUrl;
    if (playingThisVerse) return _control.replay();
    return play(verse);
  }

  Future<void> toggleSlow() async {
    final slow = !_state.isSlow;
    _set(_state.copyWith(isSlow: slow));
    await _control.setSlow(slow: slow);
  }

  Future<void> stop() => _control.stop();

  Future<void> dispose() async {
    await _sub.cancel();
    await _control.stop();
  }
}
