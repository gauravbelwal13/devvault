import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../vault/domain/entities/vault_item_entity.dart';
import '../../../vault/presentation/providers/vault_items_provider.dart';
import '../../../vault/presentation/providers/vault_providers.dart';

class AddVaultItemsScreen extends ConsumerStatefulWidget {
  const AddVaultItemsScreen({
    required this.collectionId,
    super.key,
  });

  final String collectionId;

  @override
  ConsumerState<AddVaultItemsScreen> createState() =>
      _AddVaultItemsScreenState();
}

class _AddVaultItemsScreenState
    extends ConsumerState<AddVaultItemsScreen> {
  final Set<String> _selectedItemIds = <String>{};

  bool _isSaving = false;

  Future<void> _addSelectedItems() async {
    if (_selectedItemIds.isEmpty || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updateCollection =
          ref.read(updateVaultItemCollectionProvider);

      for (final itemId in _selectedItemIds) {
        await updateCollection.call(
          itemId,
          widget.collectionId,
        );
      }

      // Refresh the main vault list.
      await ref
          .read(vaultItemsProvider.notifier)
          .refresh();

      // Refresh this collection's items.
      ref.invalidate(
        vaultItemsByCollectionProvider(widget.collectionId),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to add items: $error',
          ),
        ),
      );
    }
  }

  void _toggleItem(String itemId, bool selected) {
    setState(() {
      if (selected) {
        _selectedItemIds.add(itemId);
      } else {
        _selectedItemIds.remove(itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(vaultItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vault Items'),
      ),
      body: itemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _ErrorState(
          error: error,
          onRetry: () {
            ref
                .read(vaultItemsProvider.notifier)
                .refresh();
          },
        ),
        data: (items) {
          final availableItems = items
              .where(
                (item) =>
                    item.collectionId != widget.collectionId,
              )
              .toList();

          if (availableItems.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            itemCount: availableItems.length,
            separatorBuilder: (_, index) =>
                const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = availableItems[index];

              final isSelected =
                  _selectedItemIds.contains(item.id);

              return _VaultItemTile(
                item: item,
                selected: isSelected,
                enabled: !_isSaving,
                onChanged: (value) {
                  _toggleItem(
                    item.id,
                    value ?? false,
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _selectedItemIds.isEmpty || _isSaving
                  ? null
                  : _addSelectedItems,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _selectedItemIds.isEmpty
                          ? 'Select Items'
                          : 'Add ${_selectedItemIds.length} '
                              'Item${_selectedItemIds.length == 1 ? '' : 's'}',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VaultItemTile extends StatelessWidget {
  const _VaultItemTile({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final VaultItemEntity item;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: selected,
        onChanged: enabled ? onChanged : null,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.description.isEmpty
              ? item.type.name.toUpperCase()
              : item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        secondary: _TypeIcon(
          type: item.type,
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({
    required this.type,
  });

  final VaultItemType type;

  @override
  Widget build(BuildContext context) {
    final IconData icon;

    switch (type) {
      case VaultItemType.snippet:
        icon = Icons.code_rounded;
        break;

      case VaultItemType.api:
        icon = Icons.api_rounded;
        break;

      case VaultItemType.mqtt:
        icon = Icons.wifi_rounded;
        break;

      case VaultItemType.note:
        icon = Icons.note_rounded;
        break;
    }

    return Icon(icon);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
            ),
            SizedBox(height: 16),
            Text(
              'No vault items available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create a vault item first, then add it '
              'to this collection.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load vault items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}