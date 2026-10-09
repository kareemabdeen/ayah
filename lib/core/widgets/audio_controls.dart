import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Play/pause, replay and slow toggle. Dumb widget: state + callbacks only.
class AudioControls extends StatelessWidget {
  const AudioControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.isSlow,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
    required this.onToggleSlow,
  });

  final bool isPlaying;
  final bool isLoading;
  final bool isSlow;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;
  final VoidCallback onToggleSlow;

  static const double _mainButtonSize = 72;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onReplay,
          tooltip: s.replay,
          iconSize: AppSpacing.lg + AppSpacing.xxs,
          icon: const Icon(Icons.replay_rounded),
        ),
        const SizedBox(width: AppSpacing.lg),
        SizedBox.square(
          dimension: _mainButtonSize,
          child: IconButton.filled(
            onPressed: isLoading ? null : (isPlaying ? onPause : onPlay),
            tooltip: isPlaying ? s.pause : s.listen,
            iconSize: AppSpacing.xl + AppSpacing.xxs,
            icon: isLoading
                ? SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.onPrimary),
                  )
                : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // Shows text, not just an icon, so state isn't conveyed by color alone.
        TextButton.icon(
          onPressed: onToggleSlow,
          icon: Icon(isSlow ? Icons.slow_motion_video_rounded : Icons.speed_rounded),
          label: Text(isSlow ? s.slow : s.normalSpeed),
        ),
      ],
    );
  }
}
