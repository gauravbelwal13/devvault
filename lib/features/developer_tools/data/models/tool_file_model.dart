import 'package:devvault/core/database/app_database.dart';
import 'package:devvault/features/developer_tools/domain/entities/tool_file_entity.dart';
import 'package:drift/drift.dart';

class ToolFileModel {
  const ToolFileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    required this.toolType,
    required this.collectionId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String path;
  final String extension;
  final String? mimeType;
  final int sizeBytes;
  final String toolType;
  final String? collectionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ToolFileModel.fromEntity(ToolFileEntity file) {
    return ToolFileModel(
      id: file.id,
      name: file.name,
      path: file.path,
      extension: file.extension,
      mimeType: file.mimeType,
      sizeBytes: file.sizeBytes,
      toolType: file.toolType,
      collectionId: file.collectionId,
      createdAt: file.createdAt,
      updatedAt: file.updatedAt,
    );
  }

  factory ToolFileModel.fromDatabase(ToolFile data) {
    return ToolFileModel(
      id: data.id,
      name: data.name,
      path: data.path,
      extension: data.extension,
      mimeType: data.mimeType,
      sizeBytes: data.sizeBytes,
      toolType: data.toolType,
      collectionId: data.collectionId,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  ToolFileEntity toEntity() {
    return ToolFileEntity(
      id: id,
      name: name,
      path: path,
      extension: extension,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      toolType: toolType,
      collectionId: collectionId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ToolFilesCompanion toCompanion() {
    return ToolFilesCompanion.insert(
      id: id,
      name: name,
      path: path,
      extension: extension,
      mimeType: Value(mimeType),
      sizeBytes: sizeBytes,
      toolType: toolType,
      collectionId: Value(collectionId),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}