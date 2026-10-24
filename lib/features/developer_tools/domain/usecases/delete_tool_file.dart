import '../repositories/tool_file_repository.dart';

class DeleteToolFile {
  DeleteToolFile(this._repository);

  final ToolFileRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteFile(id);
  }
}