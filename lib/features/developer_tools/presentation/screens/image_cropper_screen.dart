import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../collections/presentation/providers/collections_providers.dart';
import '../providers/image_cropper_provider.dart';
import '../providers/tool_file_providers.dart';

class ImageCropperScreen extends ConsumerStatefulWidget {
  const ImageCropperScreen({
    super.key,
  });

  @override
  ConsumerState<ImageCropperScreen> createState() =>
      _ImageCropperScreenState();
}

class _ImageCropperScreenState
    extends ConsumerState<ImageCropperScreen> {
  final CropController _cropController = CropController();

  File? _selectedFile;
  Uint8List? _imageBytes;

  String _selectedRatio = 'Free';

  bool _isExporting = false;

  double? get _aspectRatio {
    switch (_selectedRatio) {
      case '1:1':
        return 1.0;

      case '4:3':
        return 4 / 3;

      case '3:4':
        return 3 / 4;

      case '16:9':
        return 16 / 9;

      case '9:16':
        return 9 / 16;

      case 'Original':
        return null;

      case 'Free':
      default:
        return null;
    }
  }

  Future<void> _pickImage() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (files.isEmpty || files.first.path == null) {
      return;
    }

    final file = File(files.first.path!);
    final bytes = await file.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedFile = file;
      _imageBytes = bytes;
      _selectedRatio = 'Free';
    });

    ref
        .read(imageCropperProvider.notifier)
        .clear();

    _cropController.image = bytes;
    _cropController.aspectRatio = null;
  }

  void _changeAspectRatio(String ratio) {
    setState(() {
      _selectedRatio = ratio;
    });

    _cropController.aspectRatio = _aspectRatio;
  }

  void _crop() {
    if (_imageBytes == null) {
      _showMessage(
        'Select an image first.',
      );
      return;
    }

    _cropController.crop();
  }

  void _resetCrop() {
    final bytes = _imageBytes;

    if (bytes == null) {
      return;
    }

    _cropController.image = bytes;
    _cropController.aspectRatio = _aspectRatio;
  }

  Future<void> _rotateLeft() async {
    final bytes = _imageBytes;

    if (bytes == null) {
      _showMessage(
        'Select an image first.',
      );
      return;
    }

    try {
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        _showMessage(
          'Unable to rotate this image.',
        );
        return;
      }

      final rotatedImage = img.copyRotate(
        decodedImage,
        angle: -90,
      );

      final rotatedBytes = Uint8List.fromList(
        img.encodeJpg(
          rotatedImage,
          quality: 95,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytes = rotatedBytes;
      });

      _cropController.image = rotatedBytes;
      _cropController.aspectRatio = _aspectRatio;
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to rotate image: $error',
        );
      }
    }
  }

  Future<void> _onCropped(
    CropResult result,
  ) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        await ref
            .read(imageCropperProvider.notifier)
            .saveCroppedImage(
              croppedImage,
            );

      case CropFailure(:final cause):
        if (mounted) {
          _showMessage(
            'Unable to crop image: $cause',
          );
        }
    }
  }

  Future<void> _exportResult() async {
    final savedFile =
        ref.read(imageCropperProvider).savedFile;

    if (savedFile == null) {
      _showMessage(
        'Crop an image first.',
      );
      return;
    }

    final source = File(savedFile.path);

    if (!await source.exists()) {
      _showMessage(
        'The generated file no longer exists.',
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final bytes = await source.readAsBytes();

      final destination = await FilePicker.saveFile(
        dialogTitle: 'Save cropped image',
        fileName: savedFile.name,
        bytes: bytes,
      );

      if (destination != null && mounted) {
        _showMessage(
          'Image saved successfully.',
        );
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
        ref.read(imageCropperProvider).savedFile;

    if (savedFile == null) {
      _showMessage(
        'Crop an image first.',
      );
      return;
    }

    final collections = await ref.read(
      collectionsProvider.future,
    );

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
                          backgroundColor: Color(
                            collection.color,
                          ),
                        ),
                        title: Text(
                          collection.name,
                        ),
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pop(
                            collection.id,
                          );
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
                    Navigator.of(
                      context,
                    ).pop('');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        selectedCollectionId == null) {
      return;
    }

    await ref
        .read(
          imageCropperProvider.notifier,
        )
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(imageCropperProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Image Cropper',
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

          if (_imageBytes != null) ...[
            const SizedBox(
              height: AppSpacing.lg,
            ),

            Text(
              'Aspect Ratio',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection:
                    Axis.horizontal,
                children: [
                  _RatioChip(
                    label: 'Free',
                    selected:
                        _selectedRatio ==
                            'Free',
                    onTap: () =>
                        _changeAspectRatio(
                      'Free',
                    ),
                  ),
                  _RatioChip(
                    label: 'Original',
                    selected:
                        _selectedRatio ==
                            'Original',
                    onTap: () =>
                        _changeAspectRatio(
                      'Original',
                    ),
                  ),
                  _RatioChip(
                    label: '1:1',
                    selected:
                        _selectedRatio ==
                            '1:1',
                    onTap: () =>
                        _changeAspectRatio(
                      '1:1',
                    ),
                  ),
                  _RatioChip(
                    label: '4:3',
                    selected:
                        _selectedRatio ==
                            '4:3',
                    onTap: () =>
                        _changeAspectRatio(
                      '4:3',
                    ),
                  ),
                  _RatioChip(
                    label: '3:4',
                    selected:
                        _selectedRatio ==
                            '3:4',
                    onTap: () =>
                        _changeAspectRatio(
                      '3:4',
                    ),
                  ),
                  _RatioChip(
                    label: '16:9',
                    selected:
                        _selectedRatio ==
                            '16:9',
                    onTap: () =>
                        _changeAspectRatio(
                      '16:9',
                    ),
                  ),
                  _RatioChip(
                    label: '9:16',
                    selected:
                        _selectedRatio ==
                            '9:16',
                    onTap: () =>
                        _changeAspectRatio(
                      '9:16',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            Container(
              height: 420,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.card,
                ),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              clipBehavior:
                  Clip.antiAlias,
              child: Crop(
                image: _imageBytes!,
                controller:
                    _cropController,
                aspectRatio:
                    _aspectRatio,
                onCropped: _onCropped,
                baseColor: Colors.black,
                maskColor: Colors.black
                    .withValues(
                  alpha: 0.55,
                ),
                radius: 8,
                interactive: true,
              ),
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetCrop,
                    icon: const Icon(
                      Icons.restart_alt_rounded,
                    ),
                    label: const Text(
                      'Reset',
                    ),
                  ),
                ),

                const SizedBox(
                  width: AppSpacing.sm,
                ),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rotateLeft,
                    icon: const Icon(
                      Icons.rotate_left_rounded,
                    ),
                    label: const Text(
                      'Rotate',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: AppSpacing.sm,
            ),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isLoading
                    ? null
                    : _crop,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.crop_rounded,
                      ),
                label: Text(
                  state.isLoading
                      ? 'Cropping...'
                      : 'Crop Image',
                ),
              ),
            ),
          ],

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
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.card,
                ),
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

            if (state.savedFile != null) ...[
              const SizedBox(
                height: AppSpacing.md,
              ),

              _FileInfoCard(
                name: state.savedFile!.name,
                sizeBytes:
                    state.savedFile!.sizeBytes,
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
                              Icons
                                  .download_outlined,
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
        decoration:
            BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
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
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    'Select an image',
                  ),
                  SizedBox(
                    height: 4,
                  ),
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

class _RatioChip
    extends StatelessWidget {
  const _RatioChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        right: AppSpacing.sm,
      ),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
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

    if (sizeBytes <
        1024 * 1024) {
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
      decoration:
          BoxDecoration(
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
                const SizedBox(
                  height: 2,
                ),
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
      decoration:
          BoxDecoration(
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