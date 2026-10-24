import 'dart:io';

import 'package:devvault/features/developer_tools/presentation/providers/tool_file_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../collections/presentation/providers/collections_providers.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../providers/image_compression_provider.dart';
import 'tool_file_preview_screen.dart';

class ImageCompressionScreen extends ConsumerStatefulWidget {
  const ImageCompressionScreen({super.key});

  @override
  ConsumerState<ImageCompressionScreen> createState() =>
      _ImageCompressionScreenState();
}

class _ImageCompressionScreenState
    extends ConsumerState<ImageCompressionScreen> {
  File? _selectedFile;
  int _quality = 80;
  int? _originalSize;

  Future<void> _pickImage() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (files.isEmpty || files.first.path == null) {
      return;
    }

    final file = File(files.first.path!);
    final size = await file.length();

    setState(() {
      _selectedFile = file;
      _originalSize = size;
    });

    ref.read(imageCompressionProvider.notifier).clear();
  }

  Future<void> _compress() async {
    final file = _selectedFile;

    if (file == null) {
      _showMessage('Select an image first.');
      return;
    }

    await ref.read(imageCompressionProvider.notifier).compress(
          file: file,
          quality: _quality,
        );
  }

  Future<void> _addToCollection(
    ToolFileEntity file,
  ) async {
    final collectionsAsync = ref.read(collectionsProvider);

    final collections = collectionsAsync.when(
      data: (items) => items,
      loading: () => null,
      error: (_, _) => null,
    );

    if (collections == null) {
      _showMessage(
        'Collections are still loading or could not be loaded.',
      );
      return;
    }


    final collectionId = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(
              AppSpacing.md,
            ),
            children: [
              const Padding(
                padding: EdgeInsets.all(
                  AppSpacing.md,
                ),
                child: Text(
                  'Add to Collection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final collection in collections)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Color(collection.color),
                  ),
                  title: Text(collection.name),
                  onTap: () {
                    Navigator.of(context).pop(
                      collection.id,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );

    if (collectionId == null) {
      return;
    }

    await ref
        .read(imageCompressionProvider.notifier)
        .assignToCollection(
          fileId: file.id,
          collectionId: collectionId,
        );

    ref.invalidate(
      toolFilesByCollectionProvider(collectionId),
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      'Added to collection.',
    );
  }

  void _openPreview(ToolFileEntity file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ToolFilePreviewScreen(
          file: file,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _compressionPercentage(
    int original,
    int compressed,
  ) {
    if (original <= 0) {
      return '0%';
    }

    final reduction =
        ((original - compressed) / original) * 100;

    return '${reduction.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageCompressionProvider);

    final compressedSize = state.result?.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Image Compression',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),
        children: [
          _ImagePickerCard(
            file: _selectedFile,
            onPick: _pickImage,
          ),

          if (_selectedFile != null &&
              _originalSize != null) ...[
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _FileInfoCard(
              originalSize:
                  _formatBytes(_originalSize!),
              compressedSize: compressedSize == null
                  ? null
                  : _formatBytes(compressedSize),
              reduction: compressedSize == null
                  ? null
                  : _compressionPercentage(
                      _originalSize!,
                      compressedSize,
                    ),
            ),
          ],

          const SizedBox(
            height: AppSpacing.xl,
          ),

          Text(
            'Compression Quality',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),

          const SizedBox(
            height: AppSpacing.sm,
          ),

          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _quality.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 18,
                  label: '$_quality%',
                  onChanged: state.isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _quality =
                                value.round();
                          });
                        },
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '$_quality%',
                  textAlign: TextAlign.end,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Smaller file',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color:
                          AppColors.textMuted,
                    ),
              ),
              Text(
                'Better quality',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color:
                          AppColors.textMuted,
                    ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  state.isLoading ? null : _compress,
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.compress_rounded,
                    ),
              label: Text(
                state.isLoading
                    ? 'Compressing...'
                    : 'Compress Image',
              ),
            ),
          ),

          if (state.error != null) ...[
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _ErrorCard(
              message: state.error!,
            ),
          ],

          if (state.result != null &&
              state.savedFile != null) ...[
            const SizedBox(
              height: AppSpacing.xl,
            ),

            Text(
              'Result',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            Container(
              width: double.infinity,
              constraints:
                  const BoxConstraints(
                minHeight: 200,
                maxHeight: 420,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: Image.memory(
                state.result!,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            _ResultInfoCard(
              originalSize:
                  _formatBytes(_originalSize!),
              compressedSize:
                  _formatBytes(
                state.result!.length,
              ),
              reduction:
                  _compressionPercentage(
                _originalSize!,
                state.result!.length,
              ),
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  _openPreview(
                    state.savedFile!,
                  );
                },
                icon: const Icon(
                  Icons.preview_outlined,
                ),
                label: const Text(
                  'Preview File',
                ),
              ),
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  _addToCollection(
                    state.savedFile!,
                  );
                },
                icon: const Icon(
                  Icons.collections_bookmark_outlined,
                ),
                label: const Text(
                  'Add to Collection',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.file,
    required this.onPick,
  });

  final File? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints:
            const BoxConstraints(
          minHeight: 220,
        ),
        padding:
            const EdgeInsets.all(
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: file == null
            ? const Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons
                        .add_photo_alternate_outlined,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Select an image',
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to choose an image '
                    'from your device',
                  ),
                ],
              )
            : Image.file(
                file!,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}

class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard({
    required this.originalSize,
    required this.compressedSize,
    required this.reduction,
  });

  final String originalSize;
  final String? compressedSize;
  final String? reduction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              label: 'Original',
              value: originalSize,
            ),
          ),
          Expanded(
            child: _InfoItem(
              label: 'Compressed',
              value:
                  compressedSize ?? '--',
            ),
          ),
          Expanded(
            child: _InfoItem(
              label: 'Reduced',
              value: reduction ?? '--',
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultInfoCard extends StatelessWidget {
  const _ResultInfoCard({
    required this.originalSize,
    required this.compressedSize,
    required this.reduction,
  });

  final String originalSize;
  final String compressedSize;
  final String reduction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Original size',
            value: originalSize,
          ),
          const SizedBox(
            height: AppSpacing.sm,
          ),
          _InfoRow(
            label: 'Compressed size',
            value: compressedSize,
          ),
          const SizedBox(
            height: AppSpacing.sm,
          ),
          _InfoRow(
            label: 'Size reduction',
            value: reduction,
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                color: AppColors.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleSmall,
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
          ),
          const SizedBox(
            width: AppSpacing.sm,
          ),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
    );
  }
}