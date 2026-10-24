import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';

class VoiceRecordButton extends StatelessWidget {
  const VoiceRecordButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
    this.enabled = true,
  });

  final bool isRecording;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = isRecording
        ? Colors.redAccent
        : AppColors.primary;

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: isRecording ? 92 : 84,
        height: isRecording ? 92 : 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(
                alpha: isRecording ? 0.22 : 0.10,
              ),
              blurRadius: isRecording ? 24 : 14,
              spreadRadius: isRecording ? 4 : 1,
            ),
          ],
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: isRecording ? 58 : 64,
            height: isRecording ? 58 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? color
                  : AppColors.textMuted,
            ),
            child: Icon(
              isRecording
                  ? Icons.stop_rounded
                  : Icons.mic_rounded,
              color: Colors.white,
              size: isRecording ? 30 : 32,
            ),
          ),
        ),
      ),
    );
  }
}