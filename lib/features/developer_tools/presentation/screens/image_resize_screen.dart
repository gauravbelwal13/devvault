import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../collections/presentation/providers/collections_providers.dart';
import '../providers/image_resize_provider.dart';
import '../providers/tool_file_providers.dart';

class ImageResizeScreen extends ConsumerStatefulWidget {
  const ImageResizeScreen({super.key});

  @override
  ConsumerState<ImageResizeScreen> createState() =>
      _ImageResizeScreenState();
}

class _ImageResizeScreenState
    extends ConsumerState<ImageResizeScreen> {
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  File? _selectedFile;
  bool _isExporting = false;

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (files.isEmpty || files.first.path == null) {
      return;
    }

    setState(() {
      _selectedFile = File(files.first.path!);
    });
  }

  Future<void> _resize() async {
    final file = _selectedFile;

    if (file == null) {
      _showMessage('Select an image first.');
      return;
    }

    final width = int.tryParse(
      _widthController.text.trim(),
    );

    final height = int.tryParse(
      _heightController.text.trim(),
    );

    if (width == null ||
        height == null ||
        width <= 0 ||
        height <= 0) {
      _showMessage('Enter valid width and height.');
      return;
    }

    await ref.read(imageResizeProvider.notifier).resize(
          file: file,
          width: width,
          height: height,
        );
  }

  Future<void> _exportResult() async {
  final savedFile =
      ref.read(imageResizeProvider).savedFile;

  if (savedFile == null) {
    _showMessage('No resized image available.');
    return;
  }

  final source = File(savedFile.path);

  if (!await source.exists()) {
    _showMessage('The generated file no longer exists.');
    return;
  }

  setState(() {
    _isExporting = true;
  });

  try {
    final bytes = await source.readAsBytes();

    final destination = await FilePicker.saveFile(
      dialogTitle: 'Save resized image',
      fileName: savedFile.name,
      bytes: bytes,
    );

    if (destination == null) {
      return;
    }

    // `destination` is a String path in your installed
    // file_picker version.
    if (mounted) {
      _showMessage('Image saved successfully.');
    }
  } catch (error) {
    if (mounted) {
      _showMessage(
        'Unable to save image: $error',
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
        ref.read(imageResizeProvider).savedFile;

    if (savedFile == null) {
      _showMessage('Resize an image first.');
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
                        contentPadding:
                            EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              Color(collection.color),
                        ),
                        title:
                            Text(collection.name),
                        onTap: () {
                          Navigator.of(context)
                              .pop(collection.id);
                        },
                      );
                    },
                  ),
                const Divider(),
                ListTile(
                  contentPadding:
                      EdgeInsets.zero,
                  leading: const Icon(
                    Icons.remove_circle_outline,
                  ),
                  title: const Text(
                    'Remove from collection',
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .pop('');
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

    await ref
        .read(imageResizeProvider.notifier)
        .assignToCollection(
          fileId: savedFile.id,
          collectionId:
              selectedCollectionId.isEmpty
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

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(imageResizeProvider);

    final savedFile = state.savedFile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Image Resize'),
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

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Text(
            'Dimensions',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _widthController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: 'Width',
                    hintText: '1920',
                  ),
                ),
              ),
              const SizedBox(
                width: AppSpacing.md,
              ),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText: 'Height',
                    hintText: '1080',
                  ),
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
                  state.isLoading ? null : _resize,
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
                      Icons
                          .photo_size_select_large_outlined,
                    ),
              label: Text(
                state.isLoading
                    ? 'Resizing...'
                    : 'Resize Image',
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

          if (state.result != null) ...[
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
              decoration:
                  BoxDecoration(
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

            if (savedFile != null) ...[
              const SizedBox(
                height: AppSpacing.md,
              ),

              _FileInfoCard(
                name: savedFile.name,
                sizeBytes:
                    savedFile.sizeBytes,
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
        ],
      ),
    );
  }
}

class _ImagePickerCard
    extends StatelessWidget {
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
                  Text('Select an image'),
                  SizedBox(height: 4),
                  Text(
                    'Tap to choose an image from your device',
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

class _FileInfoCard
    extends StatelessWidget {
  const _FileInfoCard({
    required this.name,
    required this.sizeBytes,
  });

  final String name;
  final int sizeBytes;

  String _formatSize() {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }

    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

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
        children: [
          const Icon(
            Icons.image_outlined,
          ),
          const SizedBox(
            width: AppSpacing.sm,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatSize(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard
    extends StatelessWidget {
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