import '../entities/tool_file_entity.dart';
import '../repositories/tool_file_repository.dart';

class GetToolFilesByCollection {
  GetToolFilesByCollection(this._repository);

  final ToolFileRepository _repository;

  Future<List<ToolFileEntity>> call(String collectionId) {
    return _repository.getFilesByCollection(collectionId);
  }
}