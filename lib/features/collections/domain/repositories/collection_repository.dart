import '../entities/collection_entity.dart';

abstract interface class CollectionRepository {
  Future<List<CollectionEntity>> getCollections();

  Future<CollectionEntity?> getCollectionById(String id);

  Future<void> createCollection(CollectionEntity collection);

  Future<void> updateCollection(CollectionEntity collection);

  Future<void> deleteCollection(String id);
}
