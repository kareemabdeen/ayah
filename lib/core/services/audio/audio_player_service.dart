import 'package:equatable/equatable.dart';

enum PlaybackPhase { idle, loading, playing, paused, completed, error }

final class PlaybackSnapshot extends Equatable {
  const PlaybackSnapshot({
    this.phase = PlaybackPhase.idle,
    this.source,
    this.position = Duration.zero,
    this.duration,
    this.speed = 1.0,
  });

  final PlaybackPhase phase;
  final String? source;
  final Duration position;
  final Duration? duration;
  final double speed;

  bool get isPlaying => phase == PlaybackPhase.playing;

  PlaybackSnapshot copyWith({
    PlaybackPhase? phase,
    String? source,
    Duration? position,
    Duration? duration,
    double? speed,
  }) =>
      PlaybackSnapshot(
        phase: phase ?? this.phase,
        source: source ?? this.source,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        speed: speed ?? this.speed,
      );

  @override
  List<Object?> get props => [phase, source, position, duration, speed];
}

/// Package-agnostic audio contract. The UI and use cases only know this.
abstract interface class AudioPlayerService {
  Stream<PlaybackSnapshot> get snapshots;

  PlaybackSnapshot get current;

  /// Loads [url] if it is not already loaded, then plays from the start.
  Future<void> play(String url, {double speed = 1.0});

  Future<void> pause();

  Future<void> resume();

  Future<void> seek(Duration position);

  /// Restarts the currently loaded source.
  Future<void> replay();

  Future<void> setSpeed(double speed);

  Future<void> stop();

  Future<void> dispose();
}
