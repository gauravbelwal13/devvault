import '../repositories/vault_repository.dart';

class UpdateVaultItemCollection {
  const UpdateVaultItemCollection(this.repository);

  final VaultRepository repository;

  Future<void> call(
    String itemId,
    String? collectionId,
  ) {
    return repository.updateCollection(
      itemId,
      collectionId,
    );
  }
}