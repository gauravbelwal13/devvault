import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';

class VideoTrimmerService {
  const VideoTrimmerService();

  Future<File> trim({
    required File inputFile,
    required File outputFile,
    required Duration start,
    required Duration end,
  }) async {
    if (!await inputFile.exists()) {
      throw Exception('Selected video no longer exists.');
    }

    if (start < Duration.zero) {
      throw Exception('Start time cannot be negative.');
    }

    if (end <= start) {
      throw Exception(
        'End time must be greater than start time.',
      );
    }

    final outputDirectory = outputFile.parent;

    if (!await outputDirectory.exists()) {
      await outputDirectory.create(
        recursive: true,
      );
    }

    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    final startSeconds =
        start.inMilliseconds / 1000.0;

    final durationSeconds =
        (end - start).inMilliseconds / 1000.0;

    final command = [
      '-y',

      // Fast seek before input.
      '-ss',
      startSeconds.toStringAsFixed(3),

      '-i',
      _quote(inputFile.path),

      '-t',
      durationSeconds.toStringAsFixed(3),

      // Keep Android-friendly resolution.
      '-vf',
      'scale=min(1920\\,iw):-2',

      // Android H.264 hardware encoder.
      '-c:v',
      'h264_mediacodec',

      '-pix_fmt',
      'yuv420p',

      '-b:v',
      '6M',

      '-maxrate',
      '8M',

      '-bufsize',
      '12M',

      // Android-friendly AAC audio.
      '-c:a',
      'aac',

      '-b:a',
      '128k',

      // Makes MP4 playable while it is being opened.
      '-movflags',
      '+faststart',

      _quote(outputFile.path),
    ].join(' ');

    final session = await FFmpegKit.execute(
      command,
    );

    final returnCode =
        await session.getReturnCode();

    final logs = await session.getLogs();

    final logText = logs
        .map((log) => log.getMessage())
        .join('\n');

    if (!ReturnCode.isSuccess(returnCode)) {
      if (await outputFile.exists()) {
        await outputFile.delete();
      }

      throw Exception(
        logText.isEmpty
            ? 'Video trimming failed.'
            : 'Video trimming failed.\n$logText',
      );
    }

    if (!await _isValidOutput(outputFile)) {
      if (await outputFile.exists()) {
        await outputFile.delete();
      }

      throw Exception(
        'FFmpeg completed, but the generated video '
        'is invalid or empty.',
      );
    }

    return outputFile;
  }

  Future<bool> _isValidOutput(File file) async {
    if (!await file.exists()) {
      return false;
    }

    final length = await file.length();

    return length > 1024;
  }

  String _quote(String path) {
    return '"${path.replaceAll('"', r'\"')}"';
  }
}