import '../entities/collection_entity.dart';
import '../repositories/collection_repository.dart';

class CreateCollection {
  const CreateCollection(this._repository);

  final CollectionRepository _repository;

  Future<void> call(CollectionEntity collection) {
    return _repository.createCollection(collection);
  }
}
