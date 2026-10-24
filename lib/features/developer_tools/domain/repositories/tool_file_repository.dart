import '../entities/tool_file_entity.dart';

abstract interface class ToolFileRepository {
  Future<List<ToolFileEntity>> getFiles();

  Future<ToolFileEntity?> getFileById(String id);

  Future<List<ToolFileEntity>> getFilesByCollection(
    String collectionId,
  );

  Future<void> saveFile(ToolFileEntity file);

  Future<void> deleteFile(String id);
}