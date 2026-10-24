import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';

/// Audio effects available in Voice Studio.
///
/// These effects are processed completely locally using FFmpeg.
/// No network connection or AI model is required.
enum VoiceEffect {
  normal,
  deepVoice,
  highPitch,
  robot,
  echo,
  reverb,
  chipmunk,
  slow,
  fast,
}

/// Applies local audio effects using FFmpeg.
///
/// The service does not know anything about Flutter UI, Riverpod,
/// collections, or database storage. It only receives an input file
/// and produces an output file.
///
/// This keeps the architecture consistent with the existing
/// AudioTrimmerService.
class VoiceEffectService {
  const VoiceEffectService();

  /// Applies [effect] to [inputFile] and writes the result to
  /// [outputFile].
  Future<File> applyEffect({
    required File inputFile,
    required File outputFile,
    required VoiceEffect effect,
  }) async {
      await printAvailableAudioEncoders();
    if (!await inputFile.exists()) {
      throw Exception(
        'Selected audio file no longer exists.',
      );
    }

    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    final outputDirectory = outputFile.parent;

    if (!await outputDirectory.exists()) {
      await outputDirectory.create(
        recursive: true,
      );
    }

    final filter = _filterFor(effect);

    final command = <String>[
  '-y',
  '-i',
  _quotePath(inputFile.path),
  '-vn',
  '-af',
  _quoteFilter(filter),
'-c:a',
'aac',
'-b:a',
'192k',
'-ar',
'44100',
'-ac',
'2',
'-movflags',
'+faststart',
_quotePath(outputFile.path),
].join(' ');

    // ------------------------------------------------------------
    // DEVVAULT FFmpeg DEBUG INFORMATION
    // ------------------------------------------------------------
    //
    // Keep this enabled while we are developing Voice Studio.
    // It lets us see exactly which effect, filter and command
    // FFmpeg received.
    //
    _debugPrint(
      'VOICE EFFECT START',
      'Effect: ${_displayName(effect)}',
    );

    _debugPrint(
      'FFMPEG FILTER',
      filter,
    );

    _debugPrint(
      'FFMPEG COMMAND',
      command,
    );

    _debugPrint(
      'INPUT',
      inputFile.path,
    );

    _debugPrint(
      'OUTPUT',
      outputFile.path,
    );

    final session = await FFmpegKit.execute(command);

    final returnCode = await session.getReturnCode();

    // FFmpeg's complete textual output.
    final output = await session.getOutput();

    // FFmpegKit's structured logs.
    final logs = await session.getLogs();

    final logText = logs
        .map((log) => log.getMessage())
        .join('\n');

    // Native FFmpeg failure stack trace, when available.
    final failStackTrace =
        await session.getFailStackTrace();

    // ------------------------------------------------------------
    // DEBUG OUTPUT
    // ------------------------------------------------------------

    _debugPrint(
      'FFMPEG RETURN CODE',
      returnCode?.toString() ?? 'null',
    );

    if (output != null && output.trim().isNotEmpty) {
      _debugPrint(
        'FFMPEG OUTPUT',
        output,
      );
    }

    if (logText.trim().isNotEmpty) {
      _debugPrint(
        'FFMPEG LOGS',
        logText,
      );
    }

    if (failStackTrace != null &&
        failStackTrace.trim().isNotEmpty) {
      _debugPrint(
        'FFMPEG FAILURE STACK TRACE',
        failStackTrace,
      );
    }

    // ------------------------------------------------------------
    // FAILURE
    // ------------------------------------------------------------

    if (!ReturnCode.isSuccess(returnCode)) {
      final usefulError = _extractUsefulError(
        output: output,
        logs: logText,
        failStackTrace: failStackTrace,
      );

      throw Exception(
        'Unable to apply ${_displayName(effect)} effect.'
        '\n\nFFmpeg error:\n$usefulError',
      );
    }

    // ------------------------------------------------------------
    // OUTPUT VALIDATION
    // ------------------------------------------------------------

    if (!await outputFile.exists()) {
      throw Exception(
        'Voice effect completed but the output file '
        'was not created.',
      );
    }

    final fileSize = await outputFile.length();

    if (fileSize <= 1024) {
      if (await outputFile.exists()) {
        await outputFile.delete();
      }

      throw Exception(
        'Voice effect completed but the generated '
        'audio is invalid.',
      );
    }

    _debugPrint(
      'VOICE EFFECT SUCCESS',
      '${_displayName(effect)} completed successfully.\n'
          'Output size: $fileSize bytes',
    );

    return outputFile;
  }

  /// Extracts a useful human-readable error from FFmpeg output.
  ///
  /// FFmpeg produces a lot of normal information such as:
  ///
  /// Copyright ...
  /// configuration ...
  /// libavcodec ...
  ///
  /// Those lines are not useful to the user.
  ///
  /// We therefore search for actual failure messages first.
  String _extractUsefulError({
    String? output,
    required String logs,
    String? failStackTrace,
  }) {
    final combined = <String>[
      if (output != null && output.trim().isNotEmpty)
        output,
      if (logs.trim().isNotEmpty)
        logs,
      if (failStackTrace != null &&
          failStackTrace.trim().isNotEmpty)
        failStackTrace,
    ].join('\n');

    if (combined.trim().isEmpty) {
      return 'FFmpeg failed without providing an error message.';
    }

    final lines = combined
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Search for the actual FFmpeg failure.
    final errorLines = <String>[];

    for (final line in lines) {
      final lower = line.toLowerCase();

      final isUseful =
          lower.contains('error') ||
          lower.contains('failed') ||
          lower.contains('failure') ||
          lower.contains('invalid argument') ||
          lower.contains('unknown filter') ||
          lower.contains('unknown encoder') ||
          lower.contains('unknown decoder') ||
          lower.contains('not found') ||
          lower.contains('no such file') ||
          lower.contains('permission denied') ||
          lower.contains('cannot') ||
          lower.contains('unable') ||
          lower.contains('unsupported') ||
          lower.contains('does not support');

      if (isUseful) {
        errorLines.add(line);
      }
    }

    if (errorLines.isNotEmpty) {
      return errorLines
          .take(5)
          .join('\n');
    }

    if (failStackTrace != null &&
        failStackTrace.trim().isNotEmpty) {
      return failStackTrace.trim();
    }

    // Fallback: return a small portion of FFmpeg output,
    // rather than dumping the entire FFmpeg banner into the snackbar.
    return lines
        .take(5)
        .join('\n');
  }

  /// Prints clearly separated FFmpeg diagnostics to Logcat.
  ///
  /// This is intentionally kept inside the service so the UI
  /// remains unaware of FFmpeg internals.
  void _debugPrint(
    String title,
    String message,
  ) {
    print('');
    print('==================================================');
    print('DEVVAULT $title');
    print('==================================================');
    print(message);
    print('==================================================');
    print('');
  }

  Future<void> printAvailableAudioEncoders() async {
  final session = await FFmpegKit.execute(
    '-hide_banner -encoders',
  );

  final logs = await session.getLogs();

  print('');
  print('==================================================');
  print('DEVVAULT AVAILABLE AUDIO ENCODERS');
  print('==================================================');

  for (final log in logs) {
    final message = log.getMessage();
    final lower = message.toLowerCase();

    if (lower.contains('mp3') ||
        lower.contains('lame') ||
        lower.contains('aac') ||
        lower.contains('opus') ||
        lower.contains('vorbis') ||
        lower.contains('audio')) {
      print(message);
    }
  }

  print('==================================================');
}

  /// Returns the FFmpeg audio filter for an effect.
  String _filterFor(VoiceEffect effect) {
    switch (effect) {
      case VoiceEffect.normal:
        return 'anull';

      case VoiceEffect.deepVoice:
        // Lower pitch while preserving approximately the original
        // playback duration.
        return 'asetrate=44100*0.80,aresample=44100,atempo=1.25';

      case VoiceEffect.highPitch:
        // Raise pitch while preserving approximately the original
        // playback duration.
        return 'asetrate=44100*1.25,aresample=44100,atempo=0.8';

      case VoiceEffect.chipmunk:
        // Stronger pitch increase for the classic chipmunk effect.
        return 'asetrate=44100*1.50,aresample=44100,atempo=0.666667';

      case VoiceEffect.slow:
        // 75% playback speed.
        return 'atempo=0.75';

      case VoiceEffect.fast:
        // 125% playback speed.
        return 'atempo=1.25';

      case VoiceEffect.echo:
        return 'aecho=0.8:0.88:60:0.40';

      case VoiceEffect.reverb:
        // Multiple delayed reflections create a simple local reverb
        // effect without requiring a separate audio engine.
        return 'aecho=0.8:0.88:35|70|105:0.30|0.20|0.12';

      case VoiceEffect.robot:
        // Ring/modulation-style effect that gives the voice a
        // mechanical/robotic character.
        return 'tremolo=f=14:d=0.85';
    }
  }

  String _displayName(VoiceEffect effect) {
    switch (effect) {
      case VoiceEffect.normal:
        return 'Normal';

      case VoiceEffect.deepVoice:
        return 'Deep Voice';

      case VoiceEffect.highPitch:
        return 'High Pitch';

      case VoiceEffect.robot:
        return 'Robot';

      case VoiceEffect.echo:
        return 'Echo';

      case VoiceEffect.reverb:
        return 'Reverb';

      case VoiceEffect.chipmunk:
        return 'Chipmunk';

      case VoiceEffect.slow:
        return 'Slow';

      case VoiceEffect.fast:
        return 'Fast';
    }
  }

  /// Quotes the filesystem path for the FFmpeg command.
  String _quotePath(String path) {
    return '"${path.replaceAll('"', r'\"')}"';
  }

  /// Quotes an FFmpeg filter expression.
  ///
  /// This is primarily useful for filters containing characters such
  /// as "|" that should remain part of the filter expression.
  String _quoteFilter(String filter) {
    return '"${filter.replaceAll('"', r'\"')}"';
  }
}