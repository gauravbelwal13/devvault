import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/vault_item_entity.dart';
import '../../domain/repositories/vault_repository.dart';
import '../models/vault_item_model.dart';

class VaultRepositoryImpl implements VaultRepository {
  VaultRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<VaultItemEntity>> getItems() async {
    final rows = await _database.select(_database.vaultItems).get();

    return rows
        .map(VaultItemModel.fromDatabase)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<VaultItemEntity>> getRecentItems({int limit = 10}) async {
    final query = _database.select(_database.vaultItems)
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.updatedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    final rows = await query.get();

    return rows
        .map(VaultItemModel.fromDatabase)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<VaultItemEntity?> getItemById(String id) async {
    final query = _database.select(_database.vaultItems)
      ..where((table) => table.id.equals(id));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return VaultItemModel.fromDatabase(row).toEntity();
  }

  @override
  Future<void> createItem(VaultItemEntity item) async {
    final model = VaultItemModel.fromEntity(item);

    await _database.into(_database.vaultItems).insert(model.toCompanion());
  }

  @override
  Future<void> updateItem(VaultItemEntity item) async {
    final model = VaultItemModel.fromEntity(item);

    await _database.update(_database.vaultItems).replace(model.toCompanion());
  }

  @override
  Future<void> deleteItem(String id) async {
    await (_database.delete(
      _database.vaultItems,
    )..where((table) => table.id.equals(id))).go();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final item = await getItemById(id);

    if (item == null) {
      return;
    }

    await (_database.update(
      _database.vaultItems,
    )..where((table) => table.id.equals(id))).write(
      VaultItemsCompanion(
        isFavorite: Value(!item.isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

    @override
      Future<List<VaultItemEntity>> getVaultItemsByCollection(
        String collectionId,
       ) async {
        final query = _database.select(_database.vaultItems)
          ..where(
            (table) => table.collectionId.equals(collectionId),
          )
          ..orderBy([
            (table) => OrderingTerm(
              expression: table.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]);

        final rows = await query.get();

        return rows
            .map(VaultItemModel.fromDatabase)
            .map((model) => model.toEntity())
            .toList();
      }
      @override
      Future<void> updateCollection(
        String itemId,
        String? collectionId,
      ) async {
        await (_database.update(
          _database.vaultItems,
        )..where((table) => table.id.equals(itemId)))
            .write(
          VaultItemsCompanion(
            collectionId: Value(collectionId),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
}
