import '../repositories/collection_repository.dart';

class DeleteCollection {
  const DeleteCollection(this._repository);

  final CollectionRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteCollection(id);
  }
}
