import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/file_storage_service.dart';
import '../../data/services/media_pdf_service.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../../domain/usecases/create_media_pdf.dart';
import '../../domain/usecases/save_tool_file.dart';
import 'file_storage_provider.dart';
import 'tool_file_providers.dart';

final mediaPdfServiceProvider = Provider<MediaPdfService>((ref) {
  return const MediaPdfService();
});

final createMediaPdfProvider = Provider<CreateMediaPdf>((ref) {
  return CreateMediaPdf(
    ref.read(mediaPdfServiceProvider),
  );
});

class MediaPdfState {
  const MediaPdfState({
    this.isLoading = false,
    this.result,
    this.savedFile,
    this.error,
  });

  final bool isLoading;
  final Uint8List? result;
  final ToolFileEntity? savedFile;
  final String? error;

  MediaPdfState copyWith({
    bool? isLoading,
    Uint8List? result,
    ToolFileEntity? savedFile,
    String? error,
    bool clearResult = false,
    bool clearSavedFile = false,
    bool clearError = false,
  }) {
    return MediaPdfState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : result ?? this.result,
      savedFile: clearSavedFile
          ? null
          : savedFile ?? this.savedFile,
      error: clearError
          ? null
          : error ?? this.error,
    );
  }
}

class MediaPdfNotifier extends StateNotifier<MediaPdfState> {
  MediaPdfNotifier(
    this._createMediaPdf,
    this._storage,
    this._saveToolFile,
  ) : super(const MediaPdfState());

  final CreateMediaPdf _createMediaPdf;
  final FileStorageService _storage;
  final SaveToolFile _saveToolFile;

  Future<void> createPdf({
    required List<File> images,
    required String pageSize,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearResult: true,
      clearSavedFile: true,
      clearError: true,
    );

    try {
      final result = await _createMediaPdf.call(
        images: images,
        pageSize: pageSize,
      );

      final id = const Uuid().v4();

      final outputFile = await _storage.saveBytes(
        bytes: result,
        fileName: 'media_pdf_$id.pdf',
      );

      final now = DateTime.now();

      final savedFile = ToolFileEntity(
        id: id,
        name: outputFile.uri.pathSegments.last,
        path: outputFile.path,
        extension: 'pdf',
        mimeType: 'application/pdf',
        sizeBytes: result.length,
        toolType: 'media_pdf',
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
    state = const MediaPdfState();
  }
}

final mediaPdfProvider =
    StateNotifierProvider<MediaPdfNotifier, MediaPdfState>((ref) {
  return MediaPdfNotifier(
    ref.read(createMediaPdfProvider),
    ref.read(fileStorageServiceProvider),
    ref.read(saveToolFileProvider),
  );
});