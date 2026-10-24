import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../data/services/video_trimmer_service.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../../domain/usecases/save_tool_file.dart';
import 'file_storage_provider.dart';
import 'tool_file_providers.dart';

final videoTrimmerServiceProvider = Provider<VideoTrimmerService>((ref) {
  return const VideoTrimmerService();
});

class VideoTrimmerState {
  const VideoTrimmerState({
    this.isLoading = false,
    this.sourceFile,
    this.resultFile,
    this.start = Duration.zero,
    this.end,
    this.duration = Duration.zero,
    this.error,
  });

  final bool isLoading;

  /// Original video selected by the user.
  final File? sourceFile;

  /// Metadata for the trimmed video saved in DevVault.
  final ToolFileEntity? resultFile;

  /// Trim start position.
  final Duration start;

  /// Trim end position.
  final Duration? end;

  /// Original video duration.
  final Duration duration;

  final String? error;

  VideoTrimmerState copyWith({
    bool? isLoading,
    File? sourceFile,
    ToolFileEntity? resultFile,
    Duration? start,
    Duration? end,
    Duration? duration,
    String? error,
    bool clearSourceFile = false,
    bool clearResultFile = false,
    bool clearEnd = false,
    bool clearError = false,
  }) {
    return VideoTrimmerState(
      isLoading: isLoading ?? this.isLoading,
      sourceFile: clearSourceFile ? null : sourceFile ?? this.sourceFile,
      resultFile: clearResultFile ? null : resultFile ?? this.resultFile,
      start: start ?? this.start,
      end: clearEnd ? null : end ?? this.end,
      duration: duration ?? this.duration,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class VideoTrimmerNotifier extends StateNotifier<VideoTrimmerState> {
  VideoTrimmerNotifier(
    this._service,
    this._storage,
    this._saveToolFile,
    this._ref,
  ) : super(const VideoTrimmerState());

  final VideoTrimmerService _service;
  final FileStorageService _storage;
  final SaveToolFile _saveToolFile;
  final Ref _ref;

  void setSourceFile({
    required File file,
    required Duration duration,
  }) {
    if (duration <= Duration.zero) {
      state = state.copyWith(
        sourceFile: file,
        duration: Duration.zero,
        start: Duration.zero,
        clearEnd: true,
        clearResultFile: true,
        error: 'Unable to determine video duration.',
      );
      return;
    }

    state = state.copyWith(
      sourceFile: file,
      duration: duration,
      start: Duration.zero,
      end: duration,
      clearResultFile: true,
      clearError: true,
    );
  }

  void setStart(Duration value) {
    final duration = state.duration;
    if (duration <= Duration.zero) {
      return;
    }

    var start = value;
    if (start < Duration.zero) {
      start = Duration.zero;
    }

    const minimumGap = Duration(milliseconds: 100);

    if (start >= duration) {
      start = duration > minimumGap
          ? duration - minimumGap
          : Duration.zero;
    }

    final currentEnd = state.end ?? duration;
    if (start >= currentEnd) {
      return;
    }

    state = state.copyWith(
      start: start,
      clearResultFile: true,
      clearError: true,
    );
  }

  void setEnd(Duration value) {
    final duration = state.duration;
    if (duration <= Duration.zero) {
      return;
    }

    var end = value;
    if (end > duration) {
      end = duration;
    }

    if (end <= state.start) {
      return;
    }

    state = state.copyWith(
      end: end,
      clearResultFile: true,
      clearError: true,
    );
  }

  void resetTrimRange() {
    if (state.duration <= Duration.zero) {
      return;
    }

    state = state.copyWith(
      start: Duration.zero,
      end: state.duration,
      clearResultFile: true,
      clearError: true,
    );
  }

  Future<void> trim() async {
    final sourceFile = state.sourceFile;

    if (sourceFile == null) {
      state = state.copyWith(
        error: 'Please select a video first.',
      );
      return;
    }

    if (state.duration <= Duration.zero) {
      state = state.copyWith(
        error: 'Unable to determine video duration.',
      );
      return;
    }

    final end = state.end ?? state.duration;

    if (state.start < Duration.zero) {
      state = state.copyWith(
        error: 'Start time cannot be negative.',
      );
      return;
    }

    if (end <= state.start) {
      state = state.copyWith(
        error: 'End time must be greater than start time.',
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

      final outputFile = await _storage.getToolsFile(
        fileName: 'video_trim_$id.mp4',
      );

      final trimmedFile = await _service.trim(
        inputFile: sourceFile,
        outputFile: outputFile,
        start: state.start,
        end: end,
      );

      final sizeBytes = await trimmedFile.length();
      if (sizeBytes <= 1024) {
        throw Exception('Trimmed video is empty or invalid.');
      }

      final now = DateTime.now();

      final savedFile = ToolFileEntity(
        id: id,
        name: trimmedFile.uri.pathSegments.last,
        path: trimmedFile.path,
        extension: 'mp4',
        mimeType: 'video/mp4',
        sizeBytes: sizeBytes,
        toolType: 'video_trimmer',
        collectionId: null,
        createdAt: now,
        updatedAt: now,
      );

      await _saveToolFile.call(savedFile);

      // Refresh the global tool-file list immediately. The file is already
      // persisted in Drift, so other screens can see it without requiring
      // an app restart.
      _ref.invalidate(toolFilesProvider);

      state = state.copyWith(
        isLoading: false,
        resultFile: savedFile,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> assignToCollection({
    required String fileId,
    required String? collectionId,
  }) async {
    final file = state.resultFile;

    if (file == null || file.id != fileId) {
      return;
    }

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

    _ref.invalidate(toolFilesProvider);

    if (collectionId != null && collectionId.isNotEmpty) {
      _ref.invalidate(
        toolFilesByCollectionProvider(collectionId),
      );
    }

    if (file.collectionId != null && file.collectionId!.isNotEmpty) {
      _ref.invalidate(
        toolFilesByCollectionProvider(file.collectionId!),
      );
    }

    state = state.copyWith(
      resultFile: updatedFile,
      clearError: true,
    );
  }

  void clear() {
    state = const VideoTrimmerState();
  }
}

final videoTrimmerProvider =
    StateNotifierProvider<VideoTrimmerNotifier, VideoTrimmerState>((ref) {
  return VideoTrimmerNotifier(
    ref.read(videoTrimmerServiceProvider),
    ref.read(fileStorageServiceProvider),
    ref.read(saveToolFileProvider),
    ref,
  );
});
