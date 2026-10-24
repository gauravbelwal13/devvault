import 'package:devvault/features/vault/data/datasources/api_test_datasource.dart';
import 'package:devvault/features/vault/data/repositories/api_test_repository_impl.dart';
import 'package:devvault/features/vault/domain/entities/vault_item_entity.dart';
import 'package:devvault/features/vault/domain/repositories/api_test_repository.dart';
import 'package:devvault/features/vault/domain/usecases/get_vault_items_by_collection.dart';
import 'package:devvault/features/vault/domain/usecases/test_api_request.dart';
import 'package:devvault/features/vault/domain/usecases/update_vault_item.dart';
import 'package:devvault/features/vault/domain/usecases/update_vault_item_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/repositories/vault_repository_impl.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../domain/usecases/create_vault_item.dart';
import '../../domain/usecases/get_recent_vault_items.dart';
import '../../domain/usecases/get_vault_items.dart';

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  final database = ref.watch(databaseProvider);

  return VaultRepositoryImpl(database);
});

final vaultItemByIdProvider = FutureProvider.family<VaultItemEntity?, String>((
  ref,
  id,
) {
  return ref.read(vaultRepositoryProvider).getItemById(id);
});

final getVaultItemsProvider = Provider<GetVaultItems>((ref) {
  return GetVaultItems(ref.watch(vaultRepositoryProvider));
});

final getRecentVaultItemsProvider = Provider<GetRecentVaultItems>((ref) {
  return GetRecentVaultItems(ref.watch(vaultRepositoryProvider));
});

final createVaultItemProvider = Provider<CreateVaultItem>((ref) {
  return CreateVaultItem(ref.watch(vaultRepositoryProvider));
});

final toggleFavoriteProvider = Provider<Future<void> Function(String)>((ref) {
  return (String id) async {
    await ref.read(vaultRepositoryProvider).toggleFavorite(id);

    ref.invalidate(vaultItemByIdProvider(id));
    ref.invalidate(getVaultItemsProvider);
  };
});

final updateVaultItemProvider = Provider<UpdateVaultItem>((ref) {
  return UpdateVaultItem(ref.watch(vaultRepositoryProvider));
});

final getVaultItemsByCollectionProvider =
    Provider<GetVaultItemsByCollection>((ref) {
  return GetVaultItemsByCollection(
    ref.watch(vaultRepositoryProvider),
  );
});

final vaultItemsByCollectionProvider =
    FutureProvider.family<List<VaultItemEntity>, String>((ref, collectionId) {
  return ref
      .read(getVaultItemsByCollectionProvider)
      .call(collectionId);
});

final updateVaultItemCollectionProvider =
    Provider<UpdateVaultItemCollection>((ref) {
  return UpdateVaultItemCollection(
    ref.watch(vaultRepositoryProvider),
  );
});

final apiTestDatasourceProvider = Provider<ApiTestDatasource>((ref) {
  final datasource = ApiTestDatasource();

  ref.onDispose(datasource.dispose);

  return datasource;
});

final apiTestRepositoryProvider = Provider<ApiTestRepository>((ref) {
  return ApiTestRepositoryImpl(
    ref.watch(apiTestDatasourceProvider),
  );
});

final testApiRequestProvider = Provider<TestApiRequest>((ref) {
  return TestApiRequest(
    ref.watch(apiTestRepositoryProvider),
  );
});