import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';

class AudioTrimmerService {
  const AudioTrimmerService();

  Future<File> trim({
    required File inputFile,
    required File outputFile,
    required Duration start,
    required Duration end,
  }) async {
    if (start >= end) {
      throw Exception('Start time must be before end time.');
    }

    if (!await inputFile.exists()) {
      throw Exception('Selected audio file no longer exists.');
    }

    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    final startSeconds = start.inMilliseconds / 1000;
    final durationSeconds =
        (end.inMilliseconds - start.inMilliseconds) / 1000;

    final inputPath = _quotePath(inputFile.path);
    final outputPath = _quotePath(outputFile.path);

    final command =
        '-y -ss $startSeconds -i $inputPath '
        '-t $durationSeconds -vn -c:a libmp3lame -q:a 2 $outputPath';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final output = await session.getOutput();

      throw Exception(
        'Unable to trim audio.'
        '${output == null || output.isEmpty ? '' : '\n$output'}',
      );
    }

    if (!await outputFile.exists()) {
      throw Exception('Audio trimming completed but output was not created.');
    }

    return outputFile;
  }

  String _quotePath(String path) {
    return '"${path.replaceAll('"', r'\"')}"';
  }
}