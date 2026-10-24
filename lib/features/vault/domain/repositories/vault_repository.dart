import '../entities/vault_item_entity.dart';

abstract interface class VaultRepository {
  Future<List<VaultItemEntity>> getItems();

  Future<List<VaultItemEntity>> getRecentItems({int limit = 10});

  Future<VaultItemEntity?> getItemById(String id);

  Future<void> createItem(VaultItemEntity item);

  Future<void> updateItem(VaultItemEntity item);

  Future<void> deleteItem(String id);

  Future<void> toggleFavorite(String id);

  Future<List<VaultItemEntity>> getVaultItemsByCollection(
   String collectionId,
  );

  Future<void> updateCollection(
    String itemId,
    String? collectionId,
  );
}
