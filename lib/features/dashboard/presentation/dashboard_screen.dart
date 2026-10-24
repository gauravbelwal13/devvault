import 'package:devvault/features/vault/presentation/providers/vault_providers.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

import '../../collections/presentation/providers/collections_providers.dart';
import '../../vault/domain/entities/vault_item_entity.dart';
import '../../vault/presentation/providers/vault_items_provider.dart';

const int _totalDeveloperTools = 7;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultItemsProvider);
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(vaultItemsProvider);
            ref.invalidate(collectionsProvider);

            await Future.wait([
              ref.read(vaultItemsProvider.future),
              ref.read(collectionsProvider.future),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: _DashboardHeader(),
              ),

              const SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: _GreetingSection(),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _StatsGrid(
                    vaultAsync: vaultAsync,
                    collectionsAsync: collectionsAsync,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: _QuickActions(
                    onCreateItem: () {
                      context.push('/vault/create');
                    },
                    onCollections: () {
                      context.push('/collections');
                    },
                    onTools: () {
                      context.push('/tools');
                    },
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: _RecentHeader(
                    onViewAll: () {
                      context.push('/vault');
                    },
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                sliver: vaultAsync.when(
                  loading: () {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  },
                  error: (error, stackTrace) {
                    return SliverToBoxAdapter(
                      child: _DashboardErrorCard(
                        message: 'Unable to load recent items.',
                        onRetry: () {
                          ref.invalidate(vaultItemsProvider);
                        },
                      ),
                    );
                  },
                  data: (items) {
                    final recentItems = _recentItems(items);

                    if (recentItems.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: _EmptyRecentState(),
                      );
                    }

                    return SliverList.separated(
                      itemCount: recentItems.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          height: AppSpacing.sm,
                        );
                      },
                      itemBuilder: (context, index) {
                        return _RecentItemCard(
                          item: recentItems[index],
                        );
                      },
                    );
                  },
                ),
              ),

              const SliverPadding(
                padding: EdgeInsets.only(
                  bottom: 120,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/vault/create');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(
          Icons.add_rounded,
        ),
      ),
    );
  }

  List<VaultItemEntity> _recentItems(
    List<VaultItemEntity> items,
  ) {
    final sorted = List<VaultItemEntity>.from(items);

    sorted.sort(
      (a, b) => b.updatedAt.compareTo(a.updatedAt),
    );

    if (sorted.length <= 5) {
      return sorted;
    }

    return sorted.take(5).toList();
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(
              Icons.menu_rounded,
              size: 25,
            ),
          ),
          const SizedBox(
            width: AppSpacing.sm,
          ),
          const Text(
            'DevVault',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              context.push('/search');
            },
            icon: const Icon(
              Icons.search_rounded,
              size: 25,
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              context.push('/settings');
            },
            icon: const Icon(
              Icons.settings_outlined,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, Gaurav 👋',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Text(
          "Let's organize some code today.",
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.vaultAsync,
    required this.collectionsAsync,
  });

  final AsyncValue<List<VaultItemEntity>> vaultAsync;
  final AsyncValue<dynamic> collectionsAsync;

  @override
  Widget build(BuildContext context) {
    final vaultCount = vaultAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => null,
    );

    final collectionCount = collectionsAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => null,
    );

    final snippetCount = vaultAsync.maybeWhen(
      data: (items) => items
          .where(
            (item) => item.type == VaultItemType.snippet,
          )
          .length,
      orElse: () => null,
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.65,
      children: [
        _StatCard(
          value: _formatCount(vaultCount),
          label: 'Vault Items',
          icon: Icons.inventory_2_outlined,
        ),
        _StatCard(
          value: _formatCount(snippetCount),
          label: 'Snippets',
          icon: Icons.code_rounded,
        ),
        _StatCard(
          value: _formatCount(collectionCount),
          label: 'Collections',
          icon: Icons.folder_outlined,
        ),
         _StatCard(
          value: _totalDeveloperTools.toString(),
          label: 'Tools',
          icon: Icons.build_outlined,
        ),
      ],
    );
  }

  String _formatCount(int? value) {
    if (value == null) {
      return '...';
    }

    return value.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

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
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                AppRadius.sm,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryLight,
              size: 23,
            ),
          ),
          const SizedBox(
            width: AppSpacing.md,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCreateItem,
    required this.onCollections,
    required this.onTools,
  });

  final VoidCallback onCreateItem;
  final VoidCallback onCollections;
  final VoidCallback onTools;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(
          height: AppSpacing.md,
        ),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_rounded,
                title: 'New Item',
                subtitle: 'Add to Vault',
                onTap: onCreateItem,
              ),
            ),
            const SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.folder_outlined,
                title: 'Collections',
                subtitle: 'Organize items',
                onTap: onCollections,
              ),
            ),
            const SizedBox(
              width: AppSpacing.sm,
            ),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.build_outlined,
                title: 'Tools',
                subtitle: 'Developer tools',
                onTap: onTools,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    AppRadius.sm,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryLight,
                  size: 21,
                ),
              ),
              const SizedBox(
                height: AppSpacing.sm,
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({
    required this.onViewAll,
  });

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Recent Items',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewAll,
          child: const Text(
            'View all',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentItemCard extends ConsumerWidget {
  const _RecentItemCard({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = item.isFavorite;

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
            '/vault/${item.id}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          child: Row(
            children: [
              _VaultTypeIcon(
                type: item.type,
              ),
              const SizedBox(
                width: AppSpacing.md,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      '${_typeLabel(item.type)} • '
                      '${item.description.isEmpty ? 'No description' : item.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                onPressed: () async {
                  await ref
                      .read(toggleFavoriteProvider)
                      .call(item.id);

                  ref.invalidate(
                    vaultItemsProvider,
                  );
                },
                icon: Icon(
                  isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: isFavorite
                      ? AppColors.primaryLight
                      : AppColors.textMuted,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(VaultItemType type) {
    switch (type) {
      case VaultItemType.snippet:
        return 'Snippet';

      case VaultItemType.api:
        return 'API';

      case VaultItemType.mqtt:
        return 'MQTT';

      case VaultItemType.note:
        return 'Note';
    }
  }
}

class _VaultTypeIcon extends StatelessWidget {
  const _VaultTypeIcon({
    required this.type,
  });

  final VaultItemType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(
          AppRadius.sm,
        ),
      ),
      child: Icon(
        _iconForType(type),
        color: AppColors.primaryLight,
        size: 21,
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

class _EmptyRecentState extends StatelessWidget {
  const _EmptyRecentState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        AppSpacing.xl,
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
            Icons.inventory_2_outlined,
            size: 42,
            color: AppColors.textMuted,
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          const Text(
            'No recent items',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: AppSpacing.xs,
          ),
          const Text(
            'Create your first Vault item to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

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
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textMuted,
          ),
          const SizedBox(
            width: AppSpacing.md,
          ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}