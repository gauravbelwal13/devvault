import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/collection_entity.dart';
import '../providers/collections_providers.dart';

class EditCollectionScreen extends ConsumerStatefulWidget {
  const EditCollectionScreen({
    required this.collectionId,
    super.key,
  });

  final String collectionId;

  @override
  ConsumerState<EditCollectionScreen> createState() =>
      _EditCollectionScreenState();
}

class _EditCollectionScreenState
    extends ConsumerState<EditCollectionScreen> {
  final _nameController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;
  int _selectedColor = AppColors.primary.toARGB32();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initialize(CollectionEntity collection) {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _nameController.text = collection.name;
    _selectedColor = collection.color;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();

    final collection = CollectionEntity(
      id: widget.collectionId,
      name: name,
      color: _selectedColor,
      createdAt: await _getCreatedAt(),
      updatedAt: now,
    );

    try {
      await ref.read(updateCollectionProvider).call(collection);

      ref.invalidate(
        collectionByIdProvider(widget.collectionId),
      );

      ref.invalidate(collectionsProvider);

      if (!mounted) {
        return;
      }

      context.pop();
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
            'Unable to update collection: $error',
          ),
        ),
      );
    }
  }

  Future<DateTime> _getCreatedAt() async {
    final collection = await ref.read(
      collectionByIdProvider(widget.collectionId).future,
    );

    return collection?.createdAt ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(
      collectionByIdProvider(widget.collectionId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Edit Collection'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: collectionAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Unable to load collection: $error',
            textAlign: TextAlign.center,
          ),
        ),
        data: (collection) {
          if (collection == null) {
            return const Center(
              child: Text('Collection not found'),
            );
          }

          _initialize(collection);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Collection name',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  hintText: 'Collection name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Collection color',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _ColorPicker(
                selectedColor: _selectedColor,
                enabled: !_isSaving,
                onChanged: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selectedColor,
    required this.enabled,
    required this.onChanged,
  });

  final int selectedColor;
  final bool enabled;
  final ValueChanged<int> onChanged;

  static const List<Color> _colors = [
    AppColors.primary,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: _colors.map((color) {
        final value = color.toARGB32();
        final selected = value == selectedColor;

        return GestureDetector(
          onTap: enabled
              ? () => onChanged(value)
              : null,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(
                      color: Colors.white,
                      width: 3,
                    )
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}