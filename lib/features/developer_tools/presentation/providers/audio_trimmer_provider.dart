import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../data/services/audio_trimmer_service.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../../domain/usecases/save_tool_file.dart';
import 'file_storage_provider.dart';
import 'tool_file_providers.dart';

final audioTrimmerServiceProvider =
    Provider<AudioTrimmerService>((ref) {
  return const AudioTrimmerService();
});

class AudioTrimmerState {
  const AudioTrimmerState({
    this.isLoading = false,
    this.savedFile,
    this.error,
  });

  final bool isLoading;
  final ToolFileEntity? savedFile;
  final String? error;

  AudioTrimmerState copyWith({
    bool? isLoading,
    ToolFileEntity? savedFile,
    String? error,
    bool clearSavedFile = false,
    bool clearError = false,
  }) {
    return AudioTrimmerState(
      isLoading: isLoading ?? this.isLoading,
      savedFile: clearSavedFile
          ? null
          : savedFile ?? this.savedFile,
      error: clearError
          ? null
          : error ?? this.error,
    );
  }
}

class AudioTrimmerNotifier
    extends StateNotifier<AudioTrimmerState> {
  AudioTrimmerNotifier(
    this._service,
    this._storage,
    this._saveToolFile,
  ) : super(const AudioTrimmerState());

  final AudioTrimmerService _service;
  final FileStorageService _storage;
  final SaveToolFile _saveToolFile;

  Future<void> trim({
    required File file,
    required Duration start,
    required Duration end,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearSavedFile: true,
      clearError: true,
    );

    try {
      final id = const Uuid().v4();

      final outputFile = await _storage.createFile(
        fileName: 'trim_$id.mp3',
      );

      final result = await _service.trim(
        inputFile: file,
        outputFile: outputFile,
        start: start,
        end: end,
      );

      final now = DateTime.now();

      final savedFile = ToolFileEntity(
        id: id,
        name: result.uri.pathSegments.last,
        path: result.path,
        extension: 'mp3',
        mimeType: 'audio/mpeg',
        sizeBytes: await result.length(),
        toolType: 'audio_trimmer',
        collectionId: null,
        createdAt: now,
        updatedAt: now,
      );

      await _saveToolFile.call(savedFile);

      state = state.copyWith(
        isLoading: false,
        savedFile: savedFile,
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
    final file = state.savedFile;

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

    state = state.copyWith(
      savedFile: updatedFile,
    );
  }

  void clear() {
    state = const AudioTrimmerState();
  }
}

final audioTrimmerProvider =
    StateNotifierProvider<
        AudioTrimmerNotifier,
        AudioTrimmerState>(
  (ref) {
    return AudioTrimmerNotifier(
      ref.read(audioTrimmerServiceProvider),
      ref.read(fileStorageServiceProvider),
      ref.read(saveToolFileProvider),
    );
  },
);