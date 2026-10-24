import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';

class VoicePlayerControls extends StatelessWidget {
  const VoicePlayerControls({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onRestart,
    required this.onSeek,
    required this.formatDuration,
    super.key,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;

  final VoidCallback onToggle;
  final VoidCallback onRestart;
  final ValueChanged<Duration> onSeek;

  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    final safeDuration =
        duration <= Duration.zero
            ? const Duration(seconds: 1)
            : duration;

    final safePosition =
        position > safeDuration
            ? safeDuration
            : position;

    return Column(
      children: [
        Row(
          children: [
            Text(
              formatDuration(safePosition),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color:
                        AppColors.textMuted,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
            ),
            const Spacer(),
            Text(
              formatDuration(duration),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color:
                        AppColors.textMuted,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
            ),
          ],
        ),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape:
                const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            overlayShape:
                const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
            activeTrackColor:
                AppColors.primary,
            inactiveTrackColor:
                AppColors.border,
            thumbColor:
                AppColors.primaryLight,
            overlayColor:
                AppColors.primary.withValues(
              alpha: 0.12,
            ),
          ),
          child: Slider(
            min: 0,
            max: safeDuration.inMilliseconds
                .toDouble(),
            value: safePosition.inMilliseconds
                .clamp(
                  0,
                  safeDuration.inMilliseconds,
                )
                .toDouble(),
            onChanged: duration <=
                    Duration.zero
                ? null
                : (value) {
                    onSeek(
                      Duration(
                        milliseconds:
                            value.round(),
                      ),
                    );
                  },
          ),
        ),

        const SizedBox(
          height: AppSpacing.xs,
        ),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Restart',
              onPressed: onRestart,
              icon: const Icon(
                Icons.replay_rounded,
              ),
            ),

            const SizedBox(
              width: AppSpacing.sm,
            ),

            SizedBox(
              width: 48,
              height: 48,
              child: IconButton.filled(
                tooltip: isPlaying
                    ? 'Pause'
                    : 'Play',
                onPressed: onToggle,
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      Colors.white,
                ),
                icon: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}