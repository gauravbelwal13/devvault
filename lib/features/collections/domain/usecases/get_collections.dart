import '../entities/collection_entity.dart';
import '../repositories/collection_repository.dart';

class GetCollections {
  const GetCollections(this._repository);

  final CollectionRepository _repository;

  Future<List<CollectionEntity>> call() {
    return _repository.getCollections();
  }
}
