import '../entities/tool_file_entity.dart';
import '../repositories/tool_file_repository.dart';

class SaveToolFile {
  SaveToolFile(this._repository);

  final ToolFileRepository _repository;

  Future<void> call(ToolFileEntity file) {
    return _repository.saveFile(file);
  }
}