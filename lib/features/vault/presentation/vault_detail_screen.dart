import 'package:devvault/app/router/app_router.dart';
import 'package:devvault/features/vault/presentation/providers/api_test_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../domain/entities/vault_item_entity.dart';
import 'providers/vault_providers.dart';

class VaultDetailScreen extends ConsumerWidget {
  const VaultDetailScreen({
    required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(vaultItemByIdProvider(itemId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Details'),
      ),
      body: itemAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Unable to load item.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        data: (item) {
          if (item == null) {
            return const Center(
              child: Text('Item not found.'),
            );
          }

          return _ItemDetails(
            item: item,
          );
        },
      ),
    );
  }
}

class _ItemDetails extends ConsumerWidget {
  const _ItemDetails({
    required this.item,
  });

  final VaultItemEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (item.type) {
      case VaultItemType.snippet:
        return _SnippetDetails(
          item: item,
          ref: ref,
        );

      case VaultItemType.note:
        return _NoteDetails(
          item: item,
          ref: ref,
        );

      case VaultItemType.api:
        return _ApiDetails(
          item: item,
          ref: ref,
        );

      case VaultItemType.mqtt:
        return _MqttDetails(
          item: item,
          ref: ref,
        );
    }
  }
}

// ============================================================
// SHARED LAYOUT
// ============================================================

class _DetailPage extends StatelessWidget {
  const _DetailPage({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.item,
    required this.icon,
    required this.label,
  });

  final VaultItemEntity item;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryLight,
                      letterSpacing: 0.8,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: item.isFavorite
              ? 'Remove from favorites'
              : 'Add to favorites',
          onPressed: () async {
            await ref.read(toggleFavoriteProvider).call(item.id);
          },
          icon: Icon(
            item.isFavorite
                ? Icons.star_rounded
                : Icons.star_border_rounded,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// NOTE
// ============================================================

class _NoteDetails extends StatelessWidget {
  const _NoteDetails({
    required this.item,
    required this.ref,
  });

  final VaultItemEntity item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            item: item,
            icon: Icons.sticky_note_2_outlined,
            label: 'NOTE',
          ),

          if (item.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          _ContentCard(
            child: SelectableText(
              item.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _EditButton(
            itemId: item.id,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SNIPPET
// ============================================================

class _SnippetDetails extends StatelessWidget {
  const _SnippetDetails({
    required this.item,
    required this.ref,
  });

  final VaultItemEntity item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            item: item,
            icon: Icons.code_rounded,
            label: 'SNIPPET',
          ),

          const SizedBox(height: AppSpacing.md),

          if (item.language?.isNotEmpty ?? false)
            _MetadataChip(
              icon: Icons.code,
              label: item.language!,
            ),

          if (item.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          _CodeCard(
            code: item.content,
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Clipboard integration will be added here.
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _EditButton(
                  itemId: item.id,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// API
// ============================================================

class _ApiDetails extends StatelessWidget {
  const _ApiDetails({
    required this.item,
    required this.ref,
  });

  final VaultItemEntity item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            item: item,
            icon: Icons.http_rounded,
            label: 'API REQUEST',
          ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              _MethodBadge(
                method: item.method ?? 'GET',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.url ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (item.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Description',
              child: Text(
                item.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],

          if (item.headers?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Headers',
              child: _CodeCard(
                code: item.headers!,
              ),
            ),
          ],

          if (item.queryParameters?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Query Parameters',
              child: _CodeCard(
                code: item.queryParameters!,
              ),
            ),
          ],

          if (item.body?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Request Body',
              child: _CodeCard(
                code: item.body!,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          Consumer(
              builder: (context, ref, _) {
                final apiState = ref.watch(apiTestProvider(item.id));

                return FilledButton.icon(
                  onPressed: apiState.isLoading
                      ? null
                      : () {
                          ref.read(apiTestProvider(item.id).notifier).send(
                                method: item.method ?? 'GET',
                                url: item.url ?? '',
                                headers: item.headers,
                                queryParameters: item.queryParameters,
                                body: item.body,
                              );
                        },
                  icon: apiState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    apiState.isLoading ? 'Sending...' : 'Send Request',
                  ),
                );
              },
            ),
          const SizedBox(height: AppSpacing.md),

Consumer(
  builder: (context, ref, _) {
    final apiState = ref.watch(apiTestProvider(item.id));

    if (apiState.isLoading) {
      return const _ResponsePlaceholder(
        title: 'Response',
        message: 'Sending request...',
      );
    }

    if (apiState.error != null) {
      return _ResponsePlaceholder(
        title: 'Error',
        message: apiState.error!,
      );
    }

    final result = apiState.result;

    if (result == null) {
      return const _ResponsePlaceholder(
        title: 'Response',
        message: 'Send the request to see the response here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: result.isSuccess
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${result.statusCode} ${result.statusMessage}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${result.responseTime.inMilliseconds} ms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CodeCard(
          code: result.body,
        ),
      ],
    );
  },
),

const SizedBox(height: AppSpacing.xl),

          _EditButton(
            itemId: item.id,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MQTT
// ============================================================

class _MqttDetails extends StatelessWidget {
  const _MqttDetails({
    required this.item,
    required this.ref,
  });

  final VaultItemEntity item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            item: item,
            icon: Icons.memory_rounded,
            label: 'MQTT',
          ),

          const SizedBox(height: AppSpacing.lg),

          _BrokerCard(
            broker: item.broker,
            port: item.port,
            username: item.username,
            clientId: item.clientId,
            qos: item.qos,
          ),

          const SizedBox(height: AppSpacing.lg),

          if (item.description.isNotEmpty)
            _Section(
              title: 'Description',
              child: Text(
                item.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          if (item.publishTopic?.isNotEmpty ?? false)
            _MqttTopicCard(
              direction: 'PUBLISH',
              topic: item.publishTopic!,
              payload: item.publishPayload,
              icon: Icons.upload_rounded,
            ),

          if (item.subscribeTopic?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            _MqttTopicCard(
              direction: 'SUBSCRIBE',
              topic: item.subscribeTopic!,
              payload: item.subscribePayload,
              icon: Icons.download_rounded,
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Test MQTT'),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          _ResponsePlaceholder(
            title: 'Messages / Response',
            message: 'MQTT test messages will appear here.',
          ),

          const SizedBox(height: AppSpacing.xl),

          _EditButton(
            itemId: item.id,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPONENTS
// ============================================================

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.code,
  });

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
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
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.primaryLight,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
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
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        method.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _BrokerCard extends StatelessWidget {
  const _BrokerCard({
    required this.broker,
    required this.port,
    required this.username,
    required this.clientId,
    required this.qos,
  });

  final String? broker;
  final int? port;
  final String? username;
  final String? clientId;
  final int? qos;

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Column(
        children: [
          _DetailRow(
            label: 'Broker',
            value: broker ?? '-',
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Port',
            value: port?.toString() ?? '-',
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'QoS',
            value: qos?.toString() ?? '-',
          ),
          if (username?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              label: 'Username',
              value: username!,
            ),
          ],
          if (clientId?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              label: 'Client ID',
              value: clientId!,
            ),
          ],
        ],
      ),
    );
  }
}

class _MqttTopicCard extends StatelessWidget {
  const _MqttTopicCard({
    required this.direction,
    required this.topic,
    required this.payload,
    required this.icon,
  });

  final String direction;
  final String topic;
  final String? payload;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                direction,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            topic,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          if (payload?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Payload',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            SelectableText(
              payload!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResponsePlaceholder extends StatelessWidget {
  const _ResponsePlaceholder({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({
    required this.itemId,
  });

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          context.push(
            AppRoutes.editVaultItem.replaceFirst(':id', itemId),
          );
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
      ),
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
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}