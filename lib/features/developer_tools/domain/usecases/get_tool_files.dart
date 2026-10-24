import '../entities/tool_file_entity.dart';
import '../repositories/tool_file_repository.dart';

class GetToolFiles {
  GetToolFiles(this._repository);

  final ToolFileRepository _repository;

  Future<List<ToolFileEntity>> call() {
    return _repository.getFiles();
  }
}