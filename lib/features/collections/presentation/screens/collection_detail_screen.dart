import 'package:devvault/features/developer_tools/domain/entities/tool_file_entity.dart';
import 'package:devvault/features/developer_tools/presentation/providers/tool_file_providers.dart';
import 'package:devvault/features/vault/presentation/providers/vault_items_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../vault/presentation/providers/vault_providers.dart';
import '../providers/collections_providers.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  const CollectionDetailScreen({
    required this.collectionId,
    super.key,
  });

  final String collectionId;

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  bool _isRemoveMode = false;
  bool _isRemoving = false;

  final Set<String> _selectedItemIds = <String>{};

  void _enterRemoveMode() {
    setState(() {
      _isRemoveMode = true;
      _selectedItemIds.clear();
    });
  }

  void _cancelRemoveMode() {
    if (_isRemoving) {
      return;
    }

    setState(() {
      _isRemoveMode = false;
      _selectedItemIds.clear();
    });
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

  Future<void> _removeSelectedItems() async {
    if (_selectedItemIds.isEmpty || _isRemoving) {
      return;
    }

    setState(() {
      _isRemoving = true;
    });

    try {
      final updateCollection =
          ref.read(updateVaultItemCollectionProvider);

      final selectedIds = List<String>.from(_selectedItemIds);

      for (final itemId in selectedIds) {
        await updateCollection.call(
          itemId,
          null,
        );
      }

      ref.invalidate(
        vaultItemsByCollectionProvider(widget.collectionId),
      );

      ref.invalidate(vaultItemsProvider);

      if (!mounted) {
        return;
      }

      setState(() {
        _isRemoveMode = false;
        _isRemoving = false;
        _selectedItemIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selectedIds.length} '
            'item${selectedIds.length == 1 ? '' : 's'} '
            'removed from collection',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRemoving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to remove items: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(
      collectionByIdProvider(widget.collectionId),
    );

    final itemsAsync = ref.watch(
      vaultItemsByCollectionProvider(widget.collectionId),
    );

    final toolFilesAsync = ref.watch(
      toolFilesByCollectionProvider(widget.collectionId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: collectionAsync.when(
          loading: () => Text(
            _isRemoveMode ? 'Remove Vault Items' : 'Collection',
          ),
          error: (_, _) => const Text('Collection'),
          data: (collection) => Text(
            _isRemoveMode
                ? 'Remove Vault Items'
                : collection?.name ?? 'Collection',
          ),
        ),
        leading: _isRemoveMode
            ? IconButton(
                tooltip: 'Cancel',
                onPressed: _isRemoving
                    ? null
                    : _cancelRemoveMode,
                icon: const Icon(
                  Icons.close_rounded,
                ),
              )
            : null,
        actions: [
          if (_isRemoveMode)
            IconButton(
              tooltip: 'Remove selected items',
              onPressed: _selectedItemIds.isEmpty || _isRemoving
                  ? null
                  : _removeSelectedItems,
              icon: _isRemoving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                    ),
            )
          else
            IconButton(
              tooltip: 'Edit collection',
              onPressed: () {
                context.push(
                  '/collections/edit/${widget.collectionId}',
                );
              },
              icon: const Icon(
                Icons.edit_rounded,
              ),
            ),
        ],
      ),
      body: collectionAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, _) => _ErrorState(
          onRetry: () {
            ref.invalidate(
              collectionByIdProvider(widget.collectionId),
            );
          },
        ),
        data: (collection) {
          if (collection == null) {
            return const _NotFoundState();
          }

          return itemsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, _) => _ErrorState(
              onRetry: () {
                ref.invalidate(
                  vaultItemsByCollectionProvider(
                    widget.collectionId,
                  ),
                );
              },
            ),
            data: (items) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(
                    collectionByIdProvider(
                      widget.collectionId,
                    ),
                  );

                  ref.invalidate(
                    vaultItemsByCollectionProvider(
                      widget.collectionId,
                    ),
                  );

                  ref.invalidate(
                    toolFilesByCollectionProvider(
                      widget.collectionId,
                    ),
                  );

                  await Future.wait([
                    ref.read(
                      vaultItemsByCollectionProvider(
                        widget.collectionId,
                      ).future,
                    ),
                    ref.read(
                      toolFilesByCollectionProvider(
                        widget.collectionId,
                      ).future,
                    ),
                  ]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(
                    AppSpacing.lg,
                  ),
                  children: [
                    _CollectionHeader(
                      name: collection.name,
                      itemCount: items.length,
                      color: Color(collection.color),
                    ),

                    const SizedBox(
                      height: AppSpacing.md,
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRemoveMode
                            ? null
                            : () {
                                context.push(
                                  '/collections/'
                                  '${widget.collectionId}/'
                                  'add-items',
                                );
                              },
                        icon: const Icon(
                          Icons.add_rounded,
                        ),
                        label: const Text(
                          'Add Vault Items',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: AppSpacing.sm,
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRemoveMode
                            ? null
                            : _enterRemoveMode,
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                        ),
                        label: const Text(
                          'Remove Vault Items',
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: AppSpacing.lg,
                    ),

                    if (_isRemoveMode)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: Text(
                          _selectedItemIds.isEmpty
                              ? 'Select items to remove'
                              : '${_selectedItemIds.length} selected',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ),

                    if (items.isEmpty)
                      _EmptyCollectionState(
                        collectionName: collection.name,
                        onAddItems: () {
                          context.push(
                            '/collections/'
                            '${widget.collectionId}/add-items',
                          );
                        },
                      )
                    else
                      for (final item in items) ...[
                        _VaultItemCard(
                          title: item.title,
                          description: item.description,
                          isRemoveMode: _isRemoveMode,
                          selected: _selectedItemIds.contains(
                            item.id,
                          ),
                          onSelected: (selected) {
                            _toggleItem(
                              item.id,
                              selected,
                            );
                          },
                          onTap: () {
                            if (_isRemoveMode) {
                              _toggleItem(
                                item.id,
                                !_selectedItemIds.contains(
                                  item.id,
                                ),
                              );
                              return;
                            }

                            context.push(
                              '/vault/${item.id}',
                            );
                          },
                        ),
                        const SizedBox(
                          height: AppSpacing.sm,
                        ),
                      ],

                    const SizedBox(
                      height: AppSpacing.xl,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: AppSpacing.xl,
                    ),

                    _ToolFilesSection(
                      toolFilesAsync: toolFilesAsync,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.name,
    required this.itemCount,
    required this.color,
  });

  final String name;
  final int itemCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                AppRadius.sm,
              ),
            ),
            child: Icon(
              Icons.folder_rounded,
              color: color,
              size: 30,
            ),
          ),

          const SizedBox(
            width: AppSpacing.md,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(
                  height: AppSpacing.xs,
                ),

                Text(
                  '$itemCount '
                  '${itemCount == 1 ? 'item' : 'items'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultItemCard extends StatelessWidget {
  const _VaultItemCard({
    required this.title,
    required this.description,
    required this.isRemoveMode,
    required this.selected,
    required this.onSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isRemoveMode;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(
        AppRadius.card,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          child: Row(
            children: [
              if (isRemoveMode) ...[
                Checkbox(
                  value: selected,
                  onChanged: (value) {
                    onSelected(
                      value ?? false,
                    );
                  },
                ),
                const SizedBox(
                  width: AppSpacing.sm,
                ),
              ] else
                const Icon(
                  Icons.code_rounded,
                  color: AppColors.primaryLight,
                ),

              const SizedBox(
                width: AppSpacing.md,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(
                        height: AppSpacing.xs,
                      ),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              if (!isRemoveMode)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolFilesSection extends StatelessWidget {
  const _ToolFilesSection({
    required this.toolFilesAsync,
  });

  final AsyncValue<List<ToolFileEntity>> toolFilesAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Tool Files',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),

        const SizedBox(
          height: AppSpacing.xs,
        ),

        Text(
          'Files created using Developer Tools',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: AppColors.textMuted,
              ),
        ),

        const SizedBox(
          height: AppSpacing.md,
        ),

        toolFilesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
            ),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) =>
              const _ToolFilesErrorState(),
          data: (files) {
            if (files.isEmpty) {
              return const _ToolFilesEmptyState();
            }

            return Column(
              children: [
                for (final file in files) ...[
                  _ToolFileCard(
                    file: file,
                  ),
                  const SizedBox(
                    height: AppSpacing.sm,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ToolFileCard extends StatelessWidget {
  const _ToolFileCard({
    required this.file,
  });

  final ToolFileEntity file;

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconForToolType() {
    switch (file.toolType) {
      case 'image_resize':
        return Icons.photo_size_select_large_outlined;

      case 'image_compression':
        return Icons.compress_outlined;

      case 'image_converter':
        return Icons.transform_outlined;

      case 'image_cropper':
        return Icons.crop_outlined;

      case 'video_trimmer':
        return Icons.video_file_outlined;

      case 'audio_trimmer':
        return Icons.audio_file_outlined;

      case 'media_pdf':
        return Icons.picture_as_pdf_outlined;

      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(
        AppRadius.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        onTap: () {
          context.push(
            '/tool-file-preview',
            extra: file,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppRadius.sm,
                  ),
                ),
                child: Icon(
                  _iconForToolType(),
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(
                width: AppSpacing.md,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(
                      height: AppSpacing.xs,
                    ),
                    Text(
                      '${file.extension.toUpperCase()} • '
                      '${_formatSize(file.sizeBytes)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolFilesEmptyState extends StatelessWidget {
  const _ToolFilesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 42,
            color: AppColors.textMuted,
          ),

          const SizedBox(
            height: AppSpacing.sm,
          ),

          Text(
            'No tool files yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),

          const SizedBox(
            height: AppSpacing.xs,
          ),

          Text(
            'Files created with Developer Tools '
            'will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _ToolFilesErrorState extends StatelessWidget {
  const _ToolFilesErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.error_outline,
          ),
          SizedBox(
            width: AppSpacing.sm,
          ),
          Expanded(
            child: Text(
              'Unable to load tool files.',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCollectionState extends StatelessWidget {
  const _EmptyCollectionState({
    required this.collectionName,
    required this.onAddItems,
  });

  final String collectionName;
  final VoidCallback onAddItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 80,
        ),

        const Icon(
          Icons.folder_open_rounded,
          size: 64,
          color: AppColors.textMuted,
        ),

        const SizedBox(
          height: AppSpacing.lg,
        ),

        Text(
          'No items in this collection',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall,
        ),

        const SizedBox(
          height: AppSpacing.sm,
        ),

        Text(
          'Add vault items to "$collectionName" '
          'to organize them here.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: AppColors.textMuted,
              ),
        ),

        const SizedBox(
          height: AppSpacing.lg,
        ),

        FilledButton.icon(
          onPressed: onAddItems,
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: const Text(
            'Add Vault Items',
          ),
        ),
      ],
    );
  }
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Collection not found',
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          const Text(
            'Unable to load collection',
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          ElevatedButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
            ),
          ),
        ],
      ),
    );
  }
}