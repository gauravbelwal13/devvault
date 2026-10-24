import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/collection_repository_impl.dart';
import '../../domain/entities/collection_entity.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/usecases/create_collection.dart';
import '../../domain/usecases/delete_collection.dart';
import '../../domain/usecases/get_collections.dart';
import '../../domain/usecases/update_collection.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return CollectionRepositoryImpl(database);
});

final getCollectionsProvider = Provider<GetCollections>((ref) {
  return GetCollections(ref.watch(collectionRepositoryProvider));
});

final createCollectionProvider = Provider<CreateCollection>((ref) {
  return CreateCollection(ref.watch(collectionRepositoryProvider));
});

final updateCollectionProvider = Provider<UpdateCollection>((ref) {
  return UpdateCollection(ref.watch(collectionRepositoryProvider));
});

final deleteCollectionProvider = Provider<DeleteCollection>((ref) {
  return DeleteCollection(ref.watch(collectionRepositoryProvider));
});

final collectionsProvider = FutureProvider<List<CollectionEntity>>((ref) {
  return ref.read(getCollectionsProvider).call();
});
final collectionByIdProvider =
    FutureProvider.family<CollectionEntity?, String>((ref, id) {
  return ref.read(collectionRepositoryProvider).getCollectionById(id);
});