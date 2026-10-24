import '../entities/vault_item_entity.dart';
import '../repositories/vault_repository.dart';

class GetVaultItemsByCollection {
  const GetVaultItemsByCollection(this.repository);

  final VaultRepository repository;

  Future<List<VaultItemEntity>> call(String collectionId) {
    return repository.getVaultItemsByCollection(collectionId);
  }
}