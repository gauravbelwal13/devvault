import 'dart:io';
import 'dart:typed_data';

import 'package:devvault/core/services/file_storage_service.dart';
import 'package:devvault/features/developer_tools/data/services/image_compression_service.dart';
import 'package:devvault/features/developer_tools/domain/entities/tool_file_entity.dart';
import 'package:devvault/features/developer_tools/domain/usecases/save_tool_file.dart';
import 'package:devvault/features/developer_tools/presentation/providers/file_storage_provider.dart';
import 'package:devvault/features/developer_tools/presentation/providers/tool_file_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

final imageCompressionServiceProvider =
    Provider<ImageCompressionService>((ref) {
  return const ImageCompressionService();
});

class ImageCompressionState {
  const ImageCompressionState({
    this.isLoading = false,
    this.result,
    this.savedFile,
    this.error,
  });

  final bool isLoading;
  final Uint8List? result;
  final ToolFileEntity? savedFile;
  final String? error;

  ImageCompressionState copyWith({
    bool? isLoading,
    Uint8List? result,
    ToolFileEntity? savedFile,
    String? error,
    bool clearResult = false,
    bool clearSavedFile = false,
    bool clearError = false,
  }) {
    return ImageCompressionState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : result ?? this.result,
      savedFile: clearSavedFile ? null : savedFile ?? this.savedFile,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ImageCompressionNotifier
    extends StateNotifier<ImageCompressionState> {
  ImageCompressionNotifier(
    this._service,
    this._storage,
    this._saveToolFile,
  ) : super(const ImageCompressionState());

  final ImageCompressionService _service;
  final FileStorageService _storage;
  final SaveToolFile _saveToolFile;

  Future<void> compress({
    required File file,
    required int quality,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearResult: true,
      clearSavedFile: true,
      clearError: true,
    );

    try {
      final result = await _service.compress(
        file: file,
        quality: quality,
      );

      final id = const Uuid().v4();

      final outputFile = await _storage.saveBytes(
        bytes: result,
        fileName: 'compress_$id.jpg',
      );

      final now = DateTime.now();

      final savedFile = ToolFileEntity(
        id: id,
        name: outputFile.uri.pathSegments.last,
        path: outputFile.path,
        extension: 'jpg',
        mimeType: 'image/jpeg',
        sizeBytes: result.length,
        toolType: 'image_compression',
        collectionId: null,
        createdAt: now,
        updatedAt: now,
      );

      await _saveToolFile.call(savedFile);

      state = state.copyWith(
        isLoading: false,
        result: result,
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
    state = const ImageCompressionState();
  }
}

final imageCompressionProvider =
    StateNotifierProvider<
        ImageCompressionNotifier,
        ImageCompressionState>((ref) {
  return ImageCompressionNotifier(
    ref.read(imageCompressionServiceProvider),
    ref.read(fileStorageServiceProvider),
    ref.read(saveToolFileProvider),
  );
});