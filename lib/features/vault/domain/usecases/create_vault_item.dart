import '../entities/vault_item_entity.dart';
import '../repositories/vault_repository.dart';

class CreateVaultItem {
  const CreateVaultItem(this._repository);

  final VaultRepository _repository;

  Future<void> call(VaultItemEntity item) {
    return _repository.createItem(item);
  }
}
