import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../data/services/image_converter_service.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../../domain/usecases/save_tool_file.dart';
import 'file_storage_provider.dart';
import 'tool_file_providers.dart';

final imageConverterServiceProvider =
    Provider<ImageConverterService>((ref) {
  return const ImageConverterService();
});

class ImageConverterState {
  const ImageConverterState({
    this.isLoading = false,
    this.result,
    this.savedFile,
    this.error,
    this.outputFormat = 'png',
  });

  final bool isLoading;
  final Uint8List? result;
  final ToolFileEntity? savedFile;
  final String? error;
  final String outputFormat;

  ImageConverterState copyWith({
    bool? isLoading,
    Uint8List? result,
    ToolFileEntity? savedFile,
    String? error,
    String? outputFormat,
    bool clearResult = false,
    bool clearSavedFile = false,
    bool clearError = false,
  }) {
    return ImageConverterState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : result ?? this.result,
      savedFile: clearSavedFile
          ? null
          : savedFile ?? this.savedFile,
      error: clearError ? null : error ?? this.error,
      outputFormat: outputFormat ?? this.outputFormat,
    );
  }
}

class ImageConverterNotifier
    extends StateNotifier<ImageConverterState> {
  ImageConverterNotifier(
    this._service,
    this._storage,
    this._saveToolFile,
  ) : super(const ImageConverterState());

  final ImageConverterService _service;
  final FileStorageService _storage;
  final SaveToolFile _saveToolFile;

  void setOutputFormat(String format) {
    state = state.copyWith(
      outputFormat: format,
      clearResult: true,
      clearSavedFile: true,
      clearError: true,
    );
  }

  Future<void> convert({
    required File file,
    required String outputFormat,
  }) async {
    state = state.copyWith(
      isLoading: true,
      outputFormat: outputFormat,
      clearResult: true,
      clearSavedFile: true,
      clearError: true,
    );

    try {
      final result = await _service.convert(
        file: file,
        outputFormat: outputFormat,
      );

      final id = const Uuid().v4();

      final extension = outputFormat.toLowerCase() == 'jpeg'
          ? 'jpg'
          : outputFormat.toLowerCase();

      final mimeType = switch (extension) {
        'jpg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'application/octet-stream',
      };

      final outputFile = await _storage.saveBytes(
        bytes: result,
        fileName: 'convert_$id.$extension',
      );

      final now = DateTime.now();

      final savedFile = ToolFileEntity(
        id: id,
        name: outputFile.uri.pathSegments.last,
        path: outputFile.path,
        extension: extension,
        mimeType: mimeType,
        sizeBytes: result.length,
        toolType: 'image_converter',
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
    state = const ImageConverterState();
  }
}

final imageConverterProvider =
    StateNotifierProvider<
        ImageConverterNotifier,
        ImageConverterState>(
  (ref) {
    return ImageConverterNotifier(
      ref.read(imageConverterServiceProvider),
      ref.read(fileStorageServiceProvider),
      ref.read(saveToolFileProvider),
    );
  },
);