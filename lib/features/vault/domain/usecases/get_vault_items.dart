import '../entities/vault_item_entity.dart';
import '../repositories/vault_repository.dart';

class GetVaultItems {
  const GetVaultItems(this._repository);

  final VaultRepository _repository;

  Future<List<VaultItemEntity>> call() {
    return _repository.getItems();
  }
}
