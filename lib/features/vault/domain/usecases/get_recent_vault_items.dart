import '../entities/vault_item_entity.dart';
import '../repositories/vault_repository.dart';

class GetRecentVaultItems {
  const GetRecentVaultItems(this._repository);

  final VaultRepository _repository;

  Future<List<VaultItemEntity>> call({int limit = 10}) {
    return _repository.getRecentItems(limit: limit);
  }
}
