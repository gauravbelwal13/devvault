import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../collections/presentation/providers/collections_providers.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../providers/media_pdf_provider.dart';
import '../providers/tool_file_providers.dart';

class MediaPdfScreen extends ConsumerStatefulWidget {
  const MediaPdfScreen({super.key});

  @override
  ConsumerState<MediaPdfScreen> createState() =>
      _MediaPdfScreenState();
}

class _MediaPdfScreenState
    extends ConsumerState<MediaPdfScreen> {
  final List<File> _images = [];

  String _pageSize = 'A4';
  bool _isExporting = false;

  Future<void> _pickImages() async {
  final result = await FilePicker.pickFiles(
    type: FileType.image,
  );

  if (result.isEmpty) {
    return;
  }

  final selected = result
      .where((file) => file.path != null)
      .map((file) => File(file.path!))
      .toList();

  if (selected.isEmpty) {
    _showMessage('No valid images were selected.');
    return;
  }

  setState(() {
    _images
      ..clear()
      ..addAll(selected);
  });

  ref.read(mediaPdfProvider.notifier).clear();
}

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });

    ref.read(mediaPdfProvider.notifier).clear();
  }

  void _moveImage(int oldIndex, int newIndex) {
  setState(() {
    final image = _images.removeAt(oldIndex);
    _images.insert(newIndex, image);
  });

  ref.read(mediaPdfProvider.notifier).clear();
}

  Future<void> _createPdf() async {
    if (_images.isEmpty) {
      _showMessage('Select at least one image.');
      return;
    }

    await ref.read(mediaPdfProvider.notifier).createPdf(
          images: List<File>.from(_images),
          pageSize: _pageSize,
        );
  }

  Future<void> _exportResult() async {
    final savedFile =
        ref.read(mediaPdfProvider).savedFile;

    if (savedFile == null) {
      _showMessage('Create a PDF first.');
      return;
    }

    final source = File(savedFile.path);

    if (!await source.exists()) {
      _showMessage(
        'The generated PDF no longer exists.',
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final bytes = await source.readAsBytes();

      final destination = await FilePicker.saveFile(
        dialogTitle: 'Save PDF',
        fileName: savedFile.name,
        bytes: bytes,
      );

      if (destination != null && mounted) {
        _showMessage('PDF saved successfully.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to save PDF: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _showCollectionPicker() async {
    final savedFile =
        ref.read(mediaPdfProvider).savedFile;

    if (savedFile == null) {
      _showMessage('Create a PDF first.');
      return;
    }

    final collections =
        await ref.read(collectionsProvider.future);

    if (!mounted) {
      return;
    }

    final selectedCollectionId =
        await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to Collection',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),
                const SizedBox(
                  height: AppSpacing.md,
                ),
                if (collections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Center(
                      child: Text(
                        'No collections available.',
                      ),
                    ),
                  )
                else
                  ...collections.map(
                    (collection) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              Color(collection.color),
                        ),
                        title: Text(collection.name),
                        onTap: () {
                          Navigator.of(context).pop(
                            collection.id,
                          );
                        },
                      );
                    },
                  ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.remove_circle_outline,
                  ),
                  title: const Text(
                    'Remove from collection',
                  ),
                  onTap: () {
                    Navigator.of(context).pop('');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedCollectionId == null) {
      return;
    }

    await ref.read(mediaPdfProvider.notifier).assignToCollection(
          fileId: savedFile.id,
          collectionId: selectedCollectionId.isEmpty
              ? null
              : selectedCollectionId,
        );

    ref.invalidate(toolFilesProvider);

    if (mounted) {
      _showMessage(
        selectedCollectionId.isEmpty
            ? 'Removed from collection.'
            : 'Added to collection.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaPdfProvider);
    final savedFile = state.savedFile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Media → PDF'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),
        children: [
          _SelectionCard(
            imageCount: _images.length,
            onPick: _pickImages,
          ),

          if (_images.isNotEmpty) ...[
            const SizedBox(
              height: AppSpacing.lg,
            ),
            Text(
              'Selected Images',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(
              height: AppSpacing.sm,
            ),
            _ImageList(
              images: _images,
              onRemove: _removeImage,
              onReorder: _moveImage,
            ),
          ],

          const SizedBox(
            height: AppSpacing.xl,
          ),

          Text(
            'Page Size',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),

          const SizedBox(
            height: AppSpacing.sm,
          ),

          DropdownButtonFormField<String>(
            initialValue: _pageSize,
            decoration: const InputDecoration(
              labelText: 'PDF Page Size',
            ),
            items: const [
              DropdownMenuItem(
                value: 'A4',
                child: Text('A4'),
              ),
              DropdownMenuItem(
                value: 'Letter',
                child: Text('Letter'),
              ),
            ],
            onChanged: state.isLoading
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _pageSize = value;
                    });

                    ref
                        .read(mediaPdfProvider.notifier)
                        .clear();
                  },
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  state.isLoading ? null : _createPdf,
              icon: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.picture_as_pdf_outlined,
                    ),
              label: Text(
                state.isLoading
                    ? 'Creating PDF...'
                    : 'Create PDF',
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
              savedFile != null) ...[
            const SizedBox(
              height: AppSpacing.xl,
            ),
            Text(
              'PDF Created',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(
              height: AppSpacing.md,
            ),
            _ResultCard(
              file: savedFile,
              formatSize: _formatSize,
            ),
            const SizedBox(
              height: AppSpacing.md,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting
                        ? null
                        : _exportResult,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.download_outlined,
                          ),
                    label: Text(
                      _isExporting
                          ? 'Saving...'
                          : 'Download',
                    ),
                  ),
                ),
                const SizedBox(
                  width: AppSpacing.sm,
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _showCollectionPicker,
                    icon: const Icon(
                      Icons.folder_outlined,
                    ),
                    label: const Text(
                      'Collection',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.imageCount,
    required this.onPick,
  });

  final int imageCount;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(
        AppRadius.card,
      ),
      child: Container(
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
              Icons.add_photo_alternate_outlined,
              size: 48,
            ),
            const SizedBox(
              height: AppSpacing.md,
            ),
            Text(
              imageCount == 0
                  ? 'Select Images'
                  : '$imageCount image${imageCount == 1 ? '' : 's'} selected',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(
              height: AppSpacing.xs,
            ),
            Text(
              'Choose one or more images',
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
    );
  }
}

class _ImageList extends StatelessWidget {
  const _ImageList({
    required this.images,
    required this.onRemove,
    required this.onReorder,
  });

  final List<File> images;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex)
      onReorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: true,
        itemCount: images.length,
        onReorderItem: onReorder,
        itemBuilder: (context, index) {
          final file = images[index];

          return ListTile(
            key: ValueKey(file.path),
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              file.uri.pathSegments.last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Page ${index + 1}',
            ),
            trailing: IconButton(
              tooltip: 'Remove',
              onPressed: () => onRemove(index),
              icon: const Icon(
                Icons.close_rounded,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.file,
    required this.formatSize,
  });

  final ToolFileEntity file;
  final String Function(int bytes) formatSize;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            size: 40,
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
                  '${formatSize(file.sizeBytes)} • PDF',
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
        ],
      ),
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