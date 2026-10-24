import 'package:devvault/app/router/app_router.dart';
import 'package:devvault/app/theme/app_radius.dart';
import 'package:devvault/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../domain/entities/vault_item_entity.dart';
import 'providers/vault_items_provider.dart';
import 'providers/vault_providers.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

enum _VaultSort {
  recentlyUpdated,
  nameAscending,
  nameDescending,
  createdNewest,
  createdOldest,
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  String? _expandedItemId;
  String _selectedFilter = 'All';

  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  _VaultSort _sort = _VaultSort.recentlyUpdated;

  DateTimeRange? _noteDateRange;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (_searchQuery == _searchController.text.trim()) {
        return;
      }

      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(vaultItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: AppSpacing.lg,
        title: _isSearching
            ? _SearchField(
                controller: _searchController,
                onClose: _closeSearch,
              )
            : const Text('Vault'),
        actions: [
          if (!_isSearching)
            IconButton(
              tooltip: 'Search',
              onPressed: _openSearch,
              icon: const Icon(Icons.search_rounded),
            ),
          IconButton(
            tooltip: 'Sort and filter',
            onPressed: _showSortAndFilter,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _ErrorState(
          onRetry: () {
            ref.read(vaultItemsProvider.notifier).refresh();
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyVaultState();
          }

          final filteredItems = _processItems(items);

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(vaultItemsProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                120,
              ),
              children: [
                _FilterChips(
                  selectedFilter: _selectedFilter,
                  onSelected: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                      _expandedItemId = null;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (_searchQuery.isNotEmpty)
                  _SearchStatus(
                    query: _searchQuery,
                    resultCount: filteredItems.length,
                    onClear: _clearSearch,
                  ),
                if (_noteDateRange != null)
                  _DateFilterStatus(
                    range: _noteDateRange!,
                    onClear: () {
                      setState(() {
                        _noteDateRange = null;
                      });
                    },
                  ),
                if (filteredItems.isEmpty)
                  const _NoFilteredItemsState()
                else
                  ...filteredItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.xs,
                      ),
                      child: _VaultItemCard(
                        item: item,
                        isExpanded: _expandedItemId == item.id,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedItemId =
                                expanded ? item.id : null;
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.createVaultItem);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _closeSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _expandedItemId = null;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _expandedItemId = null;
    });
  }

  List<VaultItemEntity> _processItems(
    List<VaultItemEntity> items,
  ) {
    var result = _filterItems(items);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();

      result = result.where((item) {
        return item.title.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.content.toLowerCase().contains(query) ||
            (item.url?.toLowerCase().contains(query) ?? false) ||
            (item.language?.toLowerCase().contains(query) ?? false) ||
            (item.method?.toLowerCase().contains(query) ?? false) ||
            item.type.name.toLowerCase().contains(query);
      }).toList();
    }

    if (_noteDateRange != null) {
      result = result.where((item) {
        if (item.type != VaultItemType.note) {
          return false;
        }

        final createdAt = item.createdAt;

        return !createdAt.isBefore(
              _startOfDay(_noteDateRange!.start),
            ) &&
            createdAt.isBefore(
              _startOfDay(
                _noteDateRange!.end.add(
                  const Duration(days: 1),
                ),
              ),
            );
      }).toList();
    }

    _sortItems(result);

    return result;
  }

  List<VaultItemEntity> _filterItems(
    List<VaultItemEntity> items,
  ) {
    switch (_selectedFilter) {
      case 'API':
        return items
            .where((item) => item.type == VaultItemType.api)
            .toList();

      case 'MQTT':
        return items
            .where((item) => item.type == VaultItemType.mqtt)
            .toList();

      case 'Code':
        return items
            .where((item) => item.type == VaultItemType.snippet)
            .toList();

      case 'Note':
        return items
            .where((item) => item.type == VaultItemType.note)
            .toList();

      case 'Favorites':
        return items
            .where((item) => item.isFavorite)
            .toList();

      case 'All':
      default:
        return List<VaultItemEntity>.from(items);
    }
  }

  void _sortItems(List<VaultItemEntity> items) {
    switch (_sort) {
      case _VaultSort.recentlyUpdated:
        items.sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt),
        );
        break;

      case _VaultSort.nameAscending:
        items.sort(
          (a, b) => a.title.toLowerCase().compareTo(
                b.title.toLowerCase(),
              ),
        );
        break;

      case _VaultSort.nameDescending:
        items.sort(
          (a, b) => b.title.toLowerCase().compareTo(
                a.title.toLowerCase(),
              ),
        );
        break;

      case _VaultSort.createdNewest:
        items.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
        break;

      case _VaultSort.createdOldest:
        items.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
        break;
    }
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  Future<void> _showSortAndFilter() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _SortFilterSheet(
          currentSort: _sort,
          currentDateRange: _noteDateRange,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _sort = result.sort;
      _noteDateRange = result.dateRange;
      _expandedItemId = null;
    });
  }
}

class _FilterResult {
  const _FilterResult({
    required this.sort,
    required this.dateRange,
  });

  final _VaultSort sort;
  final DateTimeRange? dateRange;
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onClose,
  });

  final TextEditingController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search vault...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
        ),
        suffixIcon: IconButton(
          tooltip: 'Close search',
          onPressed: onClose,
          icon: const Icon(
            Icons.close_rounded,
            size: 20,
          ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppRadius.sm,
          ),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SearchStatus extends StatelessWidget {
  const _SearchStatus({
    required this.query,
    required this.resultCount,
    required this.onClear,
  });

  final String query;
  final int resultCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$resultCount result${resultCount == 1 ? '' : 's'} for "$query"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _DateFilterStatus extends StatelessWidget {
  const _DateFilterStatus({
    required this.range,
    required this.onClear,
  });

  final DateTimeRange range;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final start = _formatDate(range.start);
    final end = _formatDate(range.end);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Notes: $start - $end',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedFilter,
    required this.onSelected,
  });

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  static const filters = [
    'All',
    'API',
    'MQTT',
    'Code',
    'Note',
    'Favorites',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, index) => const SizedBox(
          width: AppSpacing.xs,
        ),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter == selectedFilter;

          return Material(
            color: selected
                ? AppColors.primary
                : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelected(filter),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VaultItemCard extends ConsumerWidget {
  const _VaultItemCard({
    required this.item,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  final VaultItemEntity item;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              onExpansionChanged(!isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeIcon(type: item.type),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _VaultCardSummary(item: item),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (item.isFavorite)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.primaryLight,
                        size: 18,
                      ),
                    ),
                  IconButton(
                    tooltip: isExpanded ? 'Collapse' : 'Expand',
                    onPressed: () {
                      onExpansionChanged(!isExpanded);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    icon: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: isExpanded
                ? _ExpandedItemContent(
                    item: item,
                    ref: ref,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _VaultCardSummary extends StatelessWidget {
  const _VaultCardSummary({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case VaultItemType.note:
        return _NoteCardSummary(item: item);

      case VaultItemType.snippet:
        return _SnippetCardSummary(item: item);

      case VaultItemType.api:
        return _ApiCardSummary(item: item);

      case VaultItemType.mqtt:
        return _MqttCardSummary(item: item);
    }
  }
}

class _NoteCardSummary extends StatelessWidget {
  const _NoteCardSummary({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        _TypeLabel(
          label: 'NOTE',
          icon: Icons.notes_rounded,
        ),
        if (item.content.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            item.content.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}

class _SnippetCardSummary extends StatelessWidget {
  const _SnippetCardSummary({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    final language = item.language?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        _TypeLabel(
          label: language?.isNotEmpty == true
              ? language!.toUpperCase()
              : 'SNIPPET',
          icon: Icons.code_rounded,
        ),
        if (item.content.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Text(
              item.content.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ApiCardSummary extends StatelessWidget {
  const _ApiCardSummary({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    final method = item.method?.trim().isNotEmpty == true
        ? item.method!.trim().toUpperCase()
        : 'REQUEST';

    final url = item.url?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _MethodBadge(method: method),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                url?.isNotEmpty == true ? url! : 'URL not set',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _MetadataChip(
              icon: Icons.http_rounded,
              label: 'API',
            ),
            if (item.headers?.trim().isNotEmpty == true) ...[
              const SizedBox(width: 6),
              const _MetadataChip(
                icon: Icons.tune_rounded,
                label: 'Headers',
              ),
            ],
            if (item.queryParameters?.trim().isNotEmpty == true) ...[
              const SizedBox(width: 6),
              const _MetadataChip(
                icon: Icons.filter_alt_outlined,
                label: 'Query',
              ),
            ],
            if (item.body?.trim().isNotEmpty == true) ...[
              const SizedBox(width: 6),
              const _MetadataChip(
                icon: Icons.data_object_rounded,
                label: 'Body',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MqttCardSummary extends StatelessWidget {
  const _MqttCardSummary({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    final broker = item.broker?.trim();
    final port = item.port;

    final brokerText = broker?.isNotEmpty == true
        ? '$broker${port != null ? ':$port' : ''}'
        : 'Broker not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const _MetadataChip(
              icon: Icons.router_rounded,
              label: 'MQTT',
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                brokerText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _MqttTopicPreview(
          label: 'PUB',
          topic: item.publishTopic,
        ),
        const SizedBox(height: 4),
        _MqttTopicPreview(
          label: 'SUB',
          topic: item.subscribeTopic,
        ),
      ],
    );
  }
}

class _MqttTopicPreview extends StatelessWidget {
  const _MqttTopicPreview({
    required this.label,
    required this.topic,
  });

  final String label;
  final String? topic;

  @override
  Widget build(BuildContext context) {
    final value = topic?.trim();

    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value?.isNotEmpty == true ? value! : 'Not set',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
          ),
        ),
      ],
    );
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: AppColors.primaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
        ),
      ],
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({
    required this.method,
  });

  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        method,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
          ),
        ],
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
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        _iconForType(type),
        color: AppColors.primaryLight,
        size: 18,
      ),
    );
  }

  IconData _iconForType(VaultItemType type) {
    switch (type) {
      case VaultItemType.snippet:
        return Icons.code_rounded;

      case VaultItemType.api:
        return Icons.api_rounded;

      case VaultItemType.mqtt:
        return Icons.router_rounded;

      case VaultItemType.note:
        return Icons.notes_rounded;
    }
  }
}

class _ExpandedItemContent extends StatelessWidget {
  const _ExpandedItemContent({
    required this.item,
    required this.ref,
  });

  final VaultItemEntity item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          const SizedBox(height: AppSpacing.md),

          if (item.description.isNotEmpty) ...[
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          _ExpandedTypeContent(item: item),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      AppRoutes.vaultDetail.replaceFirst(
                        ':id',
                        item.id,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                  ),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      '${AppRoutes.vault}/edit/${item.id}',
                    );
                  },
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                  ),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref
                    .read(vaultRepositoryProvider)
                    .toggleFavorite(item.id);

                ref.invalidate(vaultItemsProvider);
              },
              icon: Icon(
                item.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 18,
              ),
              label: Text(
                item.isFavorite
                    ? 'Remove Favorite'
                    : 'Add to Favorites',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedTypeContent extends StatelessWidget {
  const _ExpandedTypeContent({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case VaultItemType.note:
        return _ExpandedNote(item: item);

      case VaultItemType.snippet:
        return _ExpandedSnippet(item: item);

      case VaultItemType.api:
        return _ExpandedApi(item: item);

      case VaultItemType.mqtt:
        return _ExpandedMqtt(item: item);
    }
  }
}

class _ExpandedNote extends StatelessWidget {
  const _ExpandedNote({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    return _ContentBox(
      child: SelectableText(
        item.content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
      ),
    );
  }
}

class _ExpandedSnippet extends StatelessWidget {
  const _ExpandedSnippet({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    return _ContentBox(
      child: SelectableText(
        item.content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
              height: 1.45,
            ),
      ),
    );
  }
}

class _ExpandedApi extends StatelessWidget {
  const _ExpandedApi({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.method?.trim().isNotEmpty == true) ...[
          _DetailRow(
            label: 'Method',
            value: item.method!.trim().toUpperCase(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (item.url?.trim().isNotEmpty == true) ...[
          _DetailRow(
            label: 'URL',
            value: item.url!.trim(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (item.headers?.trim().isNotEmpty == true) ...[
          _ExpandedField(
            label: 'Headers',
            value: item.headers!.trim(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (item.queryParameters?.trim().isNotEmpty == true) ...[
          _ExpandedField(
            label: 'Query Parameters',
            value: item.queryParameters!.trim(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (item.body?.trim().isNotEmpty == true)
          _ExpandedField(
            label: 'Body',
            value: item.body!.trim(),
          ),
      ],
    );
  }
}

class _ExpandedMqtt extends StatelessWidget {
  const _ExpandedMqtt({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.broker?.trim().isNotEmpty == true)
          _DetailRow(
            label: 'Broker',
            value:
                '${item.broker!.trim()}${item.port != null ? ':${item.port}' : ''}',
          ),
        if (item.clientId?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Client ID',
            value: item.clientId!.trim(),
          ),
        ],
        if (item.qos != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'QoS',
            value: item.qos.toString(),
          ),
        ],
        if (item.publishTopic?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.md),
          _ExpandedField(
            label: 'Publish Topic',
            value: item.publishTopic!.trim(),
          ),
        ],
        if (item.publishPayload?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.sm),
          _ExpandedField(
            label: 'Publish Payload',
            value: item.publishPayload!.trim(),
          ),
        ],
        if (item.subscribeTopic?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.md),
          _ExpandedField(
            label: 'Subscribe Topic',
            value: item.subscribeTopic!.trim(),
          ),
        ],
        if (item.subscribePayload?.trim().isNotEmpty == true) ...[
          const SizedBox(height: AppSpacing.sm),
          _ExpandedField(
            label: 'Subscribe Payload',
            value: item.subscribePayload!.trim(),
          ),
        ],
      ],
    );
  }
}

class _ContentBox extends StatelessWidget {
  const _ContentBox({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _ExpandedField extends StatelessWidget {
  const _ExpandedField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 5),
        _ContentBox(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

class _SortFilterSheet extends StatefulWidget {
  const _SortFilterSheet({
    required this.currentSort,
    required this.currentDateRange,
  });

  final _VaultSort currentSort;
  final DateTimeRange? currentDateRange;

  @override
  State<_SortFilterSheet> createState() =>
      _SortFilterSheetState();
}

class _SortFilterSheetState
    extends State<_SortFilterSheet> {
  late _VaultSort _sort;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();

    _sort = widget.currentSort;
    _dateRange = widget.currentDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Sort & Filter',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            Text(
              'Sort by',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    color:
                        AppColors.textSecondary,
                    fontWeight:
                        FontWeight.w600,
                  ),
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

            _SortOption(
              title: 'Recently updated',
              icon: Icons.update_rounded,
              selected:
                  _sort ==
                      _VaultSort.recentlyUpdated,
              onTap: () {
                setState(() {
                  _sort =
                      _VaultSort.recentlyUpdated;
                });
              },
            ),

            _SortOption(
              title: 'Name A → Z',
              icon: Icons.sort_by_alpha_rounded,
              selected:
                  _sort ==
                      _VaultSort.nameAscending,
              onTap: () {
                setState(() {
                  _sort =
                      _VaultSort.nameAscending;
                });
              },
            ),

            _SortOption(
              title: 'Name Z → A',
              icon: Icons.sort_by_alpha_rounded,
              selected:
                  _sort ==
                      _VaultSort.nameDescending,
              onTap: () {
                setState(() {
                  _sort =
                      _VaultSort.nameDescending;
                });
              },
            ),

            _SortOption(
              title: 'Created newest',
              icon: Icons.arrow_downward_rounded,
              selected:
                  _sort ==
                      _VaultSort.createdNewest,
              onTap: () {
                setState(() {
                  _sort =
                      _VaultSort.createdNewest;
                });
              },
            ),

            _SortOption(
              title: 'Created oldest',
              icon: Icons.arrow_upward_rounded,
              selected:
                  _sort ==
                      _VaultSort.createdOldest,
              onTap: () {
                setState(() {
                  _sort =
                      _VaultSort.createdOldest;
                });
              },
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            Text(
              'Notes date filter',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    color:
                        AppColors.textSecondary,
                    fontWeight:
                        FontWeight.w600,
                  ),
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(
                  Icons.date_range_rounded,
                ),
                label: Text(
                  _dateRange == null
                      ? 'Select date range'
                      : '${_formatDate(_dateRange!.start)}'
                          ' - '
                          '${_formatDate(_dateRange!.end)}',
                ),
              ),
            ),

            if (_dateRange != null) ...[
              const SizedBox(
                height: AppSpacing.xs,
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _dateRange = null;
                    });
                  },
                  child: const Text(
                    'Clear date filter',
                  ),
                ),
              ),
            ],

            const SizedBox(
              height: AppSpacing.md,
            ),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    _FilterResult(
                      sort: _sort,
                      dateRange: _dateRange,
                    ),
                  );
                },
                child: const Text(
                  'Apply',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();

    final initialRange =
        _dateRange ??
        DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(
            const Duration(days: 7),
          ),
          end: DateTime(
            now.year,
            now.month,
            now.day,
          ),
        );

    final selected =
        await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      initialDateRange: initialRange,
      helpText: 'Filter notes by date',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _dateRange = selected;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: selected
            ? AppColors.primaryLight
            : AppColors.textMuted,
      ),
      title: Text(title),
      trailing: selected
          ? const Icon(
              Icons.check_rounded,
              color: AppColors.primaryLight,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _EmptyVaultState extends StatelessWidget {
  const _EmptyVaultState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            SizedBox(
              height: AppSpacing.md,
            ),
            Text(
              'Your vault is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textPrimary,
              ),
            ),
            SizedBox(
              height: AppSpacing.xs,
            ),
            Text(
              'Add your first item to get started.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color:
                    AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFilteredItemsState
    extends StatelessWidget {
  const _NoFilteredItemsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        top: 80,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(
              height: AppSpacing.md,
            ),
            Text(
              'No matching items',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
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
            'Unable to load your vault',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w600,
            ),
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