import 'dart:async';

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/legacy.dart';

import 'package:record/record.dart';

import 'package:uuid/uuid.dart';

import '../../../../core/services/file_storage_service.dart';

import '../../data/services/voice_effect_service.dart';

import '../../domain/entities/tool_file_entity.dart';

import '../../domain/usecases/save_tool_file.dart';

import 'file_storage_provider.dart';

import 'tool_file_providers.dart';

final voiceEffectServiceProvider =

    Provider<VoiceEffectService>((ref) {

  return const VoiceEffectService();

});

final voiceRecorderProvider =

    Provider<AudioRecorder>((ref) {

  final recorder = AudioRecorder();

  ref.onDispose(() {

    recorder.dispose();

  });

  return recorder;

});

class VoiceStudioState {

  const VoiceStudioState({

    this.isRecording = false,

    this.isPaused = false,

    this.isLoading = false,

    this.recordingFile,

    this.resultFile,

    this.selectedEffect = VoiceEffect.normal,

    this.recordingDuration = Duration.zero,

    this.amplitude = 0,

    this.error,

  });

  /// Whether microphone recording is currently active.

  final bool isRecording;

  /// Whether an active recording session is paused.

  final bool isPaused;

  /// Whether FFmpeg is currently processing an effect.

  final bool isLoading;

  /// Raw recording created by the microphone.

  final File? recordingFile;

  /// Processed audio saved in DevVault.

  final ToolFileEntity? resultFile;

  /// Currently selected voice effect.

  final VoiceEffect selectedEffect;

  /// Duration of the current recording.

  final Duration recordingDuration;

  /// Current microphone amplitude in dBFS.

  ///

  /// dBFS values are normally negative. Values closer to zero

  /// represent a louder signal.

  final double amplitude;

  final String? error;

  VoiceStudioState copyWith({

    bool? isRecording,

    bool? isPaused,

    bool? isLoading,

    File? recordingFile,

    ToolFileEntity? resultFile,

    VoiceEffect? selectedEffect,

    Duration? recordingDuration,

    double? amplitude,

    String? error,

    bool clearRecordingFile = false,

    bool clearResultFile = false,

    bool clearError = false,

  }) {

    return VoiceStudioState(

      isRecording: isRecording ?? this.isRecording,

      isPaused: isPaused ?? this.isPaused,

      isLoading: isLoading ?? this.isLoading,

      recordingFile: clearRecordingFile

          ? null

          : recordingFile ?? this.recordingFile,

      resultFile: clearResultFile

          ? null

          : resultFile ?? this.resultFile,

      selectedEffect:

          selectedEffect ?? this.selectedEffect,

      recordingDuration:

          recordingDuration ?? this.recordingDuration,

      amplitude: amplitude ?? this.amplitude,

      error: clearError

          ? null

          : error ?? this.error,

    );

  }

}

class VoiceStudioNotifier

    extends StateNotifier<VoiceStudioState> {

  VoiceStudioNotifier(

    this._recorder,

    this._effectService,

    this._storage,

    this._saveToolFile,

  ) : super(const VoiceStudioState());

  final AudioRecorder _recorder;

  final VoiceEffectService _effectService;

  final FileStorageService _storage;

  final SaveToolFile _saveToolFile;

  Timer? _recordingTimer;

  Timer? _amplitudeTimer;

  DateTime? _recordingStartedAt;

  Duration _pausedDuration = Duration.zero;

  DateTime? _pauseStartedAt;

  /// Selects the effect that will be applied when processing

  /// the recording.

  void selectEffect(VoiceEffect effect) {

    state = state.copyWith(

      selectedEffect: effect,

      clearResultFile: true,

      clearError: true,

    );

  }

  /// Requests microphone permission.

  Future<bool> requestPermission() async {

    try {

      return await _recorder.hasPermission();

    } catch (error) {

      state = state.copyWith(

        error: 'Unable to access microphone: $error',

      );

      return false;

    }

  }

  /// Starts a new microphone recording.

  Future<void> startRecording() async {

    if (state.isRecording) {

      return;

    }

    state = state.copyWith(

      isLoading: true,

      clearError: true,

      clearResultFile: true,

      clearRecordingFile: true,

      recordingDuration: Duration.zero,

      amplitude: 0,

    );

    try {

      final hasPermission =

          await _recorder.hasPermission();

      if (!hasPermission) {

        state = state.copyWith(

          isLoading: false,

          error:

              'Microphone permission is required to record audio.',

        );

        return;

      }

      final id = const Uuid().v4();

      final outputFile =

          await _storage.createFile(

        fileName: 'voice_recording_$id.m4a',

      );

      if (await outputFile.exists()) {

        await outputFile.delete();

      }

      const config = RecordConfig(

        encoder: AudioEncoder.aacLc,

        sampleRate: 44100,

        numChannels: 1,

        bitRate: 128000,

      );

      await _recorder.start(

        config,

        path: outputFile.path,

      );

      _recordingStartedAt = DateTime.now();

      _pausedDuration = Duration.zero;

      _pauseStartedAt = null;

      _startRecordingTimers();

      state = state.copyWith(

        isLoading: false,

        isRecording: true,

        isPaused: false,

        recordingDuration: Duration.zero,

        amplitude: 0,

        clearError: true,

      );

    } catch (error) {

      _stopRecordingTimers();

      state = state.copyWith(

        isLoading: false,

        isRecording: false,

        isPaused: false,

        error: 'Unable to start recording: $error',

      );

    }

  }

  /// Pauses the active recording.

  Future<void> pauseRecording() async {

    if (!state.isRecording || state.isPaused) {

      return;

    }

    try {

      await _recorder.pause();

      _pauseStartedAt = DateTime.now();

      state = state.copyWith(

        isPaused: true,

        amplitude: 0,

        clearError: true,

      );

    } catch (error) {

      state = state.copyWith(

        error: 'Unable to pause recording: $error',

      );

    }

  }

  /// Resumes a paused recording.

  Future<void> resumeRecording() async {

    if (!state.isRecording || !state.isPaused) {

      return;

    }

    try {

      await _recorder.resume();

      final pauseStartedAt = _pauseStartedAt;

      if (pauseStartedAt != null) {

        _pausedDuration +=

            DateTime.now().difference(

          pauseStartedAt,

        );

      }

      _pauseStartedAt = null;

      state = state.copyWith(

        isPaused: false,

        clearError: true,

      );

    } catch (error) {

      state = state.copyWith(

        error: 'Unable to resume recording: $error',

      );

    }

  }

  /// Stops the active recording and keeps the generated

  /// audio file available for preview/effects.

  Future<void> stopRecording() async {

    if (!state.isRecording) {

      return;

    }

    try {

      final path = await _recorder.stop();

      _stopRecordingTimers();

      final pauseStartedAt = _pauseStartedAt;

      if (pauseStartedAt != null) {

        _pausedDuration +=

            DateTime.now().difference(

          pauseStartedAt,

        );

      }

      _pauseStartedAt = null;

      if (path == null || path.isEmpty) {

        state = state.copyWith(

          isRecording: false,

          isPaused: false,

          error:

              'Recording stopped but no audio file was created.',

        );

        return;

      }

      final recordingFile = File(path);

      if (!await recordingFile.exists()) {

        state = state.copyWith(

          isRecording: false,

          isPaused: false,

          error:

              'Recording file was not created.',

        );

        return;

      }

      final fileSize = await recordingFile.length();

      if (fileSize <= 1024) {

        state = state.copyWith(

          isRecording: false,

          isPaused: false,

          error:

              'Recording is too short or the audio file is invalid.',

        );

        return;

      }

      state = state.copyWith(

        isRecording: false,

        isPaused: false,

        recordingFile: recordingFile,

        clearError: true,

      );

    } catch (error) {

      _stopRecordingTimers();

      state = state.copyWith(

        isRecording: false,

        isPaused: false,

        error: 'Unable to stop recording: $error',

      );

    }

  }

  /// Imports an existing MP3 into the current Voice Studio session.
  ///
  /// The selected file is copied into DevVault's managed storage so the
  /// recording remains available to the effect pipeline even after the
  /// system file picker session ends.
  Future<void> importRecording(File sourceFile) async {
    if (state.isRecording || state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearResultFile: true,
      recordingDuration: Duration.zero,
      amplitude: 0,
    );

    try {
      if (!await sourceFile.exists()) {
        throw Exception('Selected MP3 file could not be found.');
      }

      final extension =
          sourceFile.path.split('.').last.toLowerCase();
      if (extension != 'mp3') {
        throw Exception('Please select an MP3 file.');
      }

      final sizeBytes = await sourceFile.length();
      if (sizeBytes <= 1024) {
        throw Exception('The selected MP3 file is empty or invalid.');
      }

      final id = const Uuid().v4();
      final importedFile = await _storage.createFile(
        fileName: 'voice_import_$id.mp3',
      );

      if (await importedFile.exists()) {
        await importedFile.delete();
      }

      await sourceFile.copy(importedFile.path);

      state = state.copyWith(
        isLoading: false,
        isRecording: false,
        isPaused: false,
        recordingFile: importedFile,
        recordingDuration: Duration.zero,
        amplitude: 0,
        clearResultFile: true,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRecording: false,
        isPaused: false,
        error: 'Unable to import MP3: $error',
      );
    }
  }

  /// Applies the selected effect to the current recording.

  ///

  /// The processed result is immediately stored in the existing

  /// ToolFile database so it can later be assigned to a collection.

  Future<void> applyEffect() async {

    final sourceFile = state.recordingFile;

    if (sourceFile == null) {

      state = state.copyWith(

        error: 'Record some audio first.',

      );

      return;

    }

    if (!await sourceFile.exists()) {

      state = state.copyWith(

        error:

            'The recording file is no longer available.',

      );

      return;

    }

    state = state.copyWith(

      isLoading: true,

      clearResultFile: true,

      clearError: true,

    );

    try {

      final id = const Uuid().v4();

      final outputFile =

          await _storage.createFile(

fileName: 'voice_${_effectName(state.selectedEffect)}_$id.m4a',
      );

      final processedFile =

          await _effectService.applyEffect(

        inputFile: sourceFile,

        outputFile: outputFile,

        effect: state.selectedEffect,

      );

      final sizeBytes =

          await processedFile.length();

      final now = DateTime.now();

      final savedFile = ToolFileEntity(

        id: id,

        name:

            processedFile.uri.pathSegments.last,

        path: processedFile.path,

        extension: 'm4a',
        mimeType: 'audio/mp4',

        sizeBytes: sizeBytes,

        toolType: 'voice_studio',

        collectionId: null,

        createdAt: now,

        updatedAt: now,

      );

      await _saveToolFile.call(savedFile);

      state = state.copyWith(

        isLoading: false,

        resultFile: savedFile,

        clearError: true,

      );

    } catch (error) {

      state = state.copyWith(

        isLoading: false,

        error:

            'Unable to process voice: $error',

      );

    }

  }

  /// Assigns the processed voice file to a collection.

  ///

  /// This follows the same persistence pattern as the existing

  /// audio trimmer.

  Future<void> assignToCollection({

    required String fileId,

    required String? collectionId,

  }) async {

    final file = state.resultFile;

    if (file == null || file.id != fileId) {

      return;

    }

    try {

      final updatedFile = ToolFileEntity(

        id: file.id,

        name: file.name,

        path: file.path,

        extension: file.extension,

        mimeType: file.mimeType,

        sizeBytes: file.sizeBytes,

        toolType: file.toolType,

        collectionId: collectionId,

        createdAt: file.createdAt,

        updatedAt: DateTime.now(),

      );

      await _saveToolFile.call(updatedFile);

      state = state.copyWith(

        resultFile: updatedFile,

        clearError: true,

      );

    } catch (error) {

      state = state.copyWith(

        error:

            'Unable to update collection: $error',

      );

    }

  }

  /// Clears the current Voice Studio session.

  Future<void> clear() async {

    _stopRecordingTimers();

    if (state.isRecording) {

      try {

        await _recorder.stop();

      } catch (_) {

        // Recorder may already be stopped.

      }

    }

    state = const VoiceStudioState();

  }

  void _startRecordingTimers() {

    _stopRecordingTimers();

    _recordingTimer = Timer.periodic(

      const Duration(milliseconds: 100),

      (_) {

        _updateRecordingDuration();

      },

    );

    _amplitudeTimer = Timer.periodic(

      const Duration(milliseconds: 100),

      (_) {

        _updateAmplitude();

      },

    );

  }

  void _stopRecordingTimers() {

    _recordingTimer?.cancel();

    _recordingTimer = null;

    _amplitudeTimer?.cancel();

    _amplitudeTimer = null;

  }

  void _updateRecordingDuration() {

    if (!state.isRecording ||

        state.isPaused ||

        _recordingStartedAt == null) {

      return;

    }

    final elapsed =

        DateTime.now().difference(

      _recordingStartedAt!,

    );

    final duration =

        elapsed - _pausedDuration;

    state = state.copyWith(

      recordingDuration:

          duration.isNegative

              ? Duration.zero

              : duration,

    );

  }

  Future<void> _updateAmplitude() async {

    if (!state.isRecording ||

        state.isPaused) {

      return;

    }

    try {

      final amplitude =

          await _recorder.getAmplitude();

      state = state.copyWith(

        amplitude: amplitude.current,

      );

    } catch (_) {

      // Amplitude is only a visual aid.

      // A failure here must never interrupt recording.

    }

  }

  String _effectName(VoiceEffect effect) {

    switch (effect) {

      case VoiceEffect.normal:

        return 'normal';

      case VoiceEffect.deepVoice:

        return 'deep';

      case VoiceEffect.highPitch:

        return 'high';

      case VoiceEffect.robot:

        return 'robot';

      case VoiceEffect.echo:

        return 'echo';

      case VoiceEffect.reverb:

        return 'reverb';

      case VoiceEffect.chipmunk:

        return 'chipmunk';

      case VoiceEffect.slow:

        return 'slow';

      case VoiceEffect.fast:

        return 'fast';

    }

  }

  @override

  void dispose() {

    _stopRecordingTimers();

    super.dispose();

  }

}

final voiceStudioProvider = StateNotifierProvider<

    VoiceStudioNotifier,

    VoiceStudioState>((ref) {

  return VoiceStudioNotifier(

    ref.read(voiceRecorderProvider),

    ref.read(voiceEffectServiceProvider),

    ref.read(fileStorageServiceProvider),

    ref.read(saveToolFileProvider),

  );

});