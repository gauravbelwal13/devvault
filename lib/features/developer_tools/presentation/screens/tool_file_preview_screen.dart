import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../providers/tool_file_providers.dart';

class ToolFilePreviewScreen extends ConsumerStatefulWidget {
  const ToolFilePreviewScreen({
    required this.file,
    super.key,
  });

  final ToolFileEntity file;

  @override
  ConsumerState<ToolFilePreviewScreen> createState() =>
      _ToolFilePreviewScreenState();
}

class _ToolFilePreviewScreenState
    extends ConsumerState<ToolFilePreviewScreen> {
  // ============================================================
  // MEDIA CONTROLLERS
  // ============================================================

  late final AudioPlayer _audioPlayer;

  PdfController? _pdfController;

  VideoPlayerController? _videoController;

  // ============================================================
  // AUDIO STATE
  // ============================================================

  Duration _audioPosition = Duration.zero;

  Duration _audioDuration = Duration.zero;

  PlayerState _audioState = PlayerState.stopped;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    if (_isPdf) {
      _pdfController = PdfController(
        document: PdfDocument.openFile(
          widget.file.path,
        ),
      );
    }

    if (_isVideo) {
      _initializeVideo();
    }

    // ------------------------------------------------------------
    // AUDIO POSITION
    // ------------------------------------------------------------

    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) {
        return;
      }

      setState(() {
        _audioPosition = position;
      });
    });

    // ------------------------------------------------------------
    // AUDIO DURATION
    // ------------------------------------------------------------

    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) {
        return;
      }

      setState(() {
        _audioDuration = duration;
      });
    });

    // ------------------------------------------------------------
    // AUDIO PLAYER STATE
    // ------------------------------------------------------------

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _audioState = state;
      });
    });

    // ------------------------------------------------------------
    // AUDIO COMPLETE
    // ------------------------------------------------------------

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _audioPosition = _audioDuration;
        _audioState = PlayerState.completed;
      });
    });
  }

  Future<void> _initializeVideo() async {
    final storedFile = File(widget.file.path);

    if (!await storedFile.exists()) {
      if (!mounted) {
        return;
      }

      setState(() {});
      return;
    }

    final controller = VideoPlayerController.file(
      storedFile,
    );

    _videoController = controller;

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(false);

      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {});

      _showMessage(
        'Unable to load video: $error',
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pdfController?.dispose();
    _videoController?.dispose();

    super.dispose();
  }

  // ============================================================
  // FILE TYPE
  // ============================================================

  String get _extension {
    return widget.file.extension.toLowerCase();
  }

  bool get _isImage {
    return _extension == 'jpg' ||
        _extension == 'jpeg' ||
        _extension == 'png' ||
        _extension == 'webp' ||
        _extension == 'gif' ||
        _extension == 'bmp';
  }

  bool get _isAudio {
    return _extension == 'mp3' ||
        _extension == 'wav' ||
        _extension == 'm4a' ||
        _extension == 'aac' ||
        _extension == 'ogg' ||
        _extension == 'flac' ||
        _extension == 'opus' ||
        _extension == 'wma';
  }

  bool get _isPdf => _extension == 'pdf';

  bool get _isVideo {
    return _extension == 'mp4' ||
        _extension == 'mov' ||
        _extension == 'mkv' ||
        _extension == 'webm' ||
        _extension == 'avi' ||
        _extension == '3gp' ||
        _extension == 'm4v';
  }

  // ============================================================
  // FILE SIZE
  // ============================================================

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteFile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete file?'),
          content: Text(
            'This will permanently delete '
            '"${widget.file.name}".',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref
          .read(deleteToolFileProvider)
          .call(widget.file.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete file: $error',
      );
    }
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _buildImagePreview() {
    final storedFile = File(widget.file.path);

    if (!storedFile.existsSync()) {
      return const _MissingFileState();
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5,
      child: Image.file(
        storedFile,
        fit: BoxFit.contain,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const _PreviewErrorState(
            message: 'Unable to preview image',
          );
        },
      ),
    );
  }

  // ============================================================
  // AUDIO PREVIEW
  // ============================================================

  Future<void> _toggleAudio() async {
    final storedFile = File(widget.file.path);

    if (!await storedFile.exists()) {
      _showMessage(
        'The audio file is no longer available.',
      );
      return;
    }

    try {
      if (_audioState == PlayerState.playing) {
        await _audioPlayer.pause();
        return;
      }

      if (_audioState == PlayerState.paused) {
        await _audioPlayer.resume();
        return;
      }

      await _audioPlayer.setSourceDeviceFile(
        widget.file.path,
      );

      await _audioPlayer.resume();
    } catch (error) {
      _showMessage(
        'Unable to play audio: $error',
      );
    }
  }

  Future<void> _restartAudio() async {
    final storedFile = File(widget.file.path);

    if (!await storedFile.exists()) {
      _showMessage(
        'The audio file is no longer available.',
      );
      return;
    }

    try {
      await _audioPlayer.setSourceDeviceFile(
        widget.file.path,
      );

      await _audioPlayer.seek(
        Duration.zero,
      );

      await _audioPlayer.resume();
    } catch (error) {
      _showMessage(
        'Unable to play audio: $error',
      );
    }
  }

  Future<void> _seekAudio(
    double milliseconds,
  ) async {
    await _audioPlayer.seek(
      Duration(
        milliseconds: milliseconds.round(),
      ),
    );
  }

  Widget _buildAudioPreview() {
    final maxMilliseconds =
        _audioDuration.inMilliseconds <= 0
            ? 1
            : _audioDuration.inMilliseconds;

    final safePosition =
        _audioPosition > _audioDuration
            ? _audioDuration
            : _audioPosition;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.card,
                  ),
                ),
                child: const Icon(
                  Icons.audio_file_rounded,
                  size: 48,
                  color: AppColors.primaryLight,
                ),
              ),

              const SizedBox(
                height: AppSpacing.lg,
              ),

              Text(
                widget.file.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),

              const SizedBox(
                height: AppSpacing.lg,
              ),

              Slider(
                min: 0,
                max: maxMilliseconds.toDouble(),
                value: safePosition.inMilliseconds
                    .clamp(
                      0,
                      maxMilliseconds,
                    )
                    .toDouble(),
                onChanged:
                    _audioDuration <=
                            Duration.zero
                        ? null
                        : _seekAudio,
              ),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(
                      safePosition,
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color:
                              AppColors.textMuted,
                        ),
                  ),
                  Text(
                    _formatDuration(
                      _audioDuration,
                    ),
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
                height: AppSpacing.md,
              ),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: _toggleAudio,
                    icon: Icon(
                      _audioState ==
                              PlayerState.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  const SizedBox(
                    width: AppSpacing.sm,
                  ),
                  OutlinedButton.icon(
                    onPressed: _restartAudio,
                    icon: const Icon(
                      Icons.replay_rounded,
                    ),
                    label: const Text('Restart'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO PREVIEW
  // ============================================================

  Widget _buildVideoPreview() {
    final controller = _videoController;

    if (controller == null) {
      final file = File(widget.file.path);

      if (!file.existsSync()) {
        return const _MissingFileState();
      }

      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (
        context,
        value,
        child,
      ) {
        if (value.hasError) {
          return _PreviewErrorState(
            message:
                value.errorDescription ??
                'Unable to preview video.',
          );
        }

        if (!value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final duration = value.duration;

        final position = value.position;

        final safePosition =
            position > duration
                ? duration
                : position;

        final maxMilliseconds =
            duration.inMilliseconds <= 0
                ? 1
                : duration.inMilliseconds;

        final aspectRatio =
            value.aspectRatio > 0
                ? value.aspectRatio
                : 16 / 9;

        return Padding(
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          child: Column(
            children: [
              // --------------------------------------------------
              // VIDEO
              // --------------------------------------------------

              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        AppRadius.card,
                      ),
                      child: Container(
                        color: Colors.black,
                        child: VideoPlayer(
                          controller,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: AppSpacing.md,
              ),

              // --------------------------------------------------
              // SEEK BAR
              // --------------------------------------------------

              Slider(
                min: 0,
                max: maxMilliseconds.toDouble(),
                value: safePosition
                    .inMilliseconds
                    .clamp(
                      0,
                      maxMilliseconds,
                    )
                    .toDouble(),
                onChanged: (newValue) {
                  controller.seekTo(
                    Duration(
                      milliseconds:
                          newValue.round(),
                    ),
                  );
                },
              ),

              // --------------------------------------------------
              // TIME
              // --------------------------------------------------

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(
                        safePosition,
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                AppColors.textMuted,
                          ),
                    ),
                    Text(
                      _formatDuration(
                        duration,
                      ),
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
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              // --------------------------------------------------
              // PLAY / PAUSE
              // --------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    tooltip: value.isPlaying
                        ? 'Pause'
                        : 'Play',
                    onPressed: () async {
                      if (value.isPlaying) {
                        await controller.pause();
                      } else {
                        if (value.position >=
                            value.duration) {
                          await controller.seekTo(
                            Duration.zero,
                          );
                        }

                        await controller.play();
                      }
                    },
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),

                  const SizedBox(
                    width: AppSpacing.sm,
                  ),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await controller.seekTo(
                        Duration.zero,
                      );

                      if (!value.isPlaying) {
                        await controller.play();
                      }
                    },
                    icon: const Icon(
                      Icons.replay_rounded,
                    ),
                    label: const Text('Restart'),
                  ),
                ],
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PDF PREVIEW
  // ============================================================

  Widget _buildPdfPreview() {
    final controller = _pdfController;

    if (controller == null) {
      return const _PreviewErrorState(
        message: 'Unable to open PDF.',
      );
    }

    return PdfView(
      controller: controller,
      scrollDirection: Axis.vertical,
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        pageLoaderBuilder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (
          context,
          error,
        ) {
          return _PreviewErrorState(
            message:
                'Unable to render PDF: $error',
          );
        },
        pageBuilder: (
          context,
          pageImage,
          index,
          document,
        ) {
          return PhotoViewGalleryPageOptions(
            imageProvider: PdfPageImageProvider(
              pageImage,
              index,
              document.id,
            ),
            minScale:
                PhotoViewComputedScale.contained,
            maxScale:
                PhotoViewComputedScale.contained *
                    3,
            initialScale:
                PhotoViewComputedScale.contained,
          );
        },
      ),
    );
  }

  // ============================================================
  // UNSUPPORTED
  // ============================================================

  Widget _buildUnsupportedPreview() {
    return const _UnsupportedPreviewState();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDuration(
    Duration duration,
  ) {
    final hours = duration.inHours;

    final minutes =
        duration.inMinutes.remainder(60);

    final seconds =
        duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // PREVIEW ROUTER
  // ============================================================

  Widget _buildPreview() {
    if (_isImage) {
      return _buildImagePreview();
    }

    if (_isAudio) {
      return _buildAudioPreview();
    }

    if (_isPdf) {
      return _buildPdfPreview();
    }

    if (_isVideo) {
      return _buildVideoPreview();
    }

    return _buildUnsupportedPreview();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleteFile,
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(
                AppSpacing.lg,
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
              clipBehavior: Clip.antiAlias,
              child: _buildPreview(),
            ),
          ),

          _FileInformation(
            file: widget.file,
            formattedSize:
                _formatSize(
              widget.file.sizeBytes,
            ),
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FILE INFORMATION
// ============================================================================

class _FileInformation extends StatelessWidget {
  const _FileInformation({
    required this.file,
    required this.formattedSize,
  });

  final ToolFileEntity file;

  final String formattedSize;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          AppSpacing.md,
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
              height: AppSpacing.sm,
            ),

            Text(
              '${file.extension.toUpperCase()} • '
              '$formattedSize',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),

            if (file.mimeType != null) ...[
              const SizedBox(
                height: AppSpacing.xs,
              ),
              Text(
                file.mimeType!,
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
    );
  }
}

// ============================================================================
// MISSING FILE STATE
// ============================================================================

class _MissingFileState
    extends StatelessWidget {
  const _MissingFileState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),

            SizedBox(
              height: AppSpacing.md,
            ),

            Text(
              'File not found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(
              height: AppSpacing.xs,
            ),

            Text(
              'The stored file is no longer available.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PREVIEW ERROR STATE
// ============================================================================

class _PreviewErrorState
    extends StatelessWidget {
  const _PreviewErrorState({
    this.message = 'Unable to preview file',
  });

  final String message;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),

            const SizedBox(
              height: AppSpacing.md,
            ),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// UNSUPPORTED PREVIEW STATE
// ============================================================================

class _UnsupportedPreviewState
    extends StatelessWidget {
  const _UnsupportedPreviewState();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),

            SizedBox(
              height: AppSpacing.md,
            ),

            Text(
              'Preview not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(
              height: AppSpacing.xs,
            ),

            Text(
              'Preview support for this file type '
              'will be added later.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}