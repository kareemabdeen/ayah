import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/audio/audio_player_service.dart';
import '../../../../core/utils/result.dart';
import '../entities/verse.dart';

/// Plays a verse's recitation, optionally slowed down.
final class PlayVerseAudioUseCase {
  const PlayVerseAudioUseCase(this._audio);
  final AudioPlayerService _audio;

  Future<Result<void>> call(Verse verse, {bool slow = false}) async {
    try {
      await _audio.play(
        verse.audioUrl,
        speed: slow ? AppConstants.slowPlaybackSpeed : AppConstants.normalPlaybackSpeed,
      );
      return const Success(null);
    } catch (e) {
      return Err(AudioFailure(e.toString()));
    }
  }
}

/// Pause / resume / speed / stop + a playback stream, grouped because they
/// are one cohesive capability and always injected together.
final class ControlPlaybackUseCase {
  const ControlPlaybackUseCase(this._audio);
  final AudioPlayerService _audio;

  Stream<PlaybackSnapshot> watch() => _audio.snapshots;
  PlaybackSnapshot get current => _audio.current;

  Future<void> pause() => _audio.pause();
  Future<void> resume() => _audio.resume();
  Future<void> replay() => _audio.replay();
  Future<void> stop() => _audio.stop();
  Future<void> setSlow({required bool slow}) =>
      _audio.setSpeed(slow ? AppConstants.slowPlaybackSpeed : AppConstants.normalPlaybackSpeed);
}
