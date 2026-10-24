import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vault_item_entity.dart';
import 'vault_providers.dart';

final vaultItemsProvider =
    AsyncNotifierProvider<VaultItemsNotifier, List<VaultItemEntity>>(
  VaultItemsNotifier.new,
);

class VaultItemsNotifier extends AsyncNotifier<List<VaultItemEntity>> {
  @override
  Future<List<VaultItemEntity>> build() {
    return ref.read(getVaultItemsProvider).call();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => ref.read(getVaultItemsProvider).call(),
    );
  }
}