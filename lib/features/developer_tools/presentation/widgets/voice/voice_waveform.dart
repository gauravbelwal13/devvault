import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';

class VoiceWaveform extends StatelessWidget {
  const VoiceWaveform({
    super.key,
    required this.amplitude,
    this.isRecording = false,
    this.barCount = 32,
    this.height = 96,
  });

  final double amplitude;
  final bool isRecording;
  final int barCount;
  final double height;

  double _normalizedAmplitude() {
    if (!isRecording) {
      return 0.08;
    }

    // Android normally reports microphone amplitude in dBFS.
    // Silence is close to -160 and louder audio approaches 0.
    final normalized =
        (amplitude + 60) / 60;

    return normalized.clamp(0.05, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final level = _normalizedAmplitude();

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: CustomPaint(
        painter: _WaveformPainter(
          amplitude: level,
          barCount: barCount,
          isRecording: isRecording,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.amplitude,
    required this.barCount,
    required this.isRecording,
  });

  final double amplitude;
  final int barCount;
  final bool isRecording;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final centerY = size.height / 2;

    final spacing = 4.0;

    final totalSpacing =
        spacing * (barCount - 1);

    final barWidth =
        (size.width - totalSpacing) /
            barCount;

    final random =
        math.Random(42);

    for (var i = 0; i < barCount; i++) {
      final distanceFromCenter =
          (i - (barCount - 1) / 2).abs();

      final centerFactor =
          1 -
              (distanceFromCenter /
                  (barCount / 2));

      final randomFactor =
          0.65 + random.nextDouble() * 0.35;

      final pulse =
          isRecording
              ? amplitude
              : 0.08;

      final normalizedHeight =
          (8 +
                  54 *
                      pulse *
                      centerFactor *
                      randomFactor)
              .clamp(6.0, 62.0);

      final left =
          i * (barWidth + spacing);

      final top =
          centerY -
              normalizedHeight / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          top,
          barWidth,
          normalizedHeight,
        ),
        const Radius.circular(8),
      );

      final paint = Paint()
        ..color = isRecording
            ? AppColors.primary
            : AppColors.textSecondary;

      canvas.drawRRect(
        rect,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _WaveformPainter oldDelegate,
  ) {
    return oldDelegate.amplitude != amplitude ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.barCount != barCount;
  }
}