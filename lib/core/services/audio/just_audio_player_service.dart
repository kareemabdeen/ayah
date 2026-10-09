import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'audio_player_service.dart';

/// [AudioPlayerService] backed by just_audio.
///
/// Uses [LockCachingAudioSource] so a verse played once is available
/// offline afterwards (memorization repeats the same audio many times).
final class JustAudioPlayerService implements AudioPlayerService {
  JustAudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _subscriptions.addAll([
      _player.playerStateStream.listen(_onPlayerState, onError: (_) => _emit(_current.copyWith(phase: PlaybackPhase.error))),
      _player.positionStream.listen((p) => _emit(_current.copyWith(position: p))),
      _player.durationStream.listen((d) => _emit(_current.copyWith(duration: d))),
      _player.speedStream.listen((s) => _emit(_current.copyWith(speed: s))),
    ]);
  }

  final AudioPlayer _player;
  final _controller = StreamController<PlaybackSnapshot>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  PlaybackSnapshot _current = const PlaybackSnapshot();

  @override
  Stream<PlaybackSnapshot> get snapshots => _controller.stream;

  @override
  PlaybackSnapshot get current => _current;

  void _emit(PlaybackSnapshot next) {
    if (next == _current) return;
    _current = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  void _onPlayerState(PlayerState state) {
    final phase = switch (state.processingState) {
      ProcessingState.idle => PlaybackPhase.idle,
      ProcessingState.loading || ProcessingState.buffering => PlaybackPhase.loading,
      ProcessingState.completed => PlaybackPhase.completed,
      ProcessingState.ready => state.playing ? PlaybackPhase.playing : PlaybackPhase.paused,
    };
    _emit(_current.copyWith(phase: phase));
  }

  @override
  Future<void> play(String url, {double speed = 1.0}) async {
    try {
      if (_current.source != url) {
        _emit(_current.copyWith(source: url, phase: PlaybackPhase.loading, position: Duration.zero));
        await _player.setAudioSource(LockCachingAudioSource(Uri.parse(url)));
      } else {
        await _player.seek(Duration.zero);
      }
      await _player.setSpeed(speed);
      // `play()` completes only when playback stops, so don't await it.
      unawaited(_player.play());
    } catch (_) {
      _emit(_current.copyWith(phase: PlaybackPhase.error));
      rethrow;
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() async => unawaited(_player.play());

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> replay() async {
    await _player.seek(Duration.zero);
    unawaited(_player.play());
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _controller.close();
    await _player.dispose();
  }
}
