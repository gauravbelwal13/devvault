import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../app/theme/app_radius.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/database/database_provider.dart';

import '../providers/video_trimmer_provider.dart';

class VideoTrimmerScreen extends ConsumerStatefulWidget {

  const VideoTrimmerScreen({super.key});

  @override

  ConsumerState<VideoTrimmerScreen> createState() =>

      _VideoTrimmerScreenState();

}

class _VideoTrimmerScreenState

    extends ConsumerState<VideoTrimmerScreen> {

  VideoPlayerController? _sourceController;

  VideoPlayerController? _resultController;

  bool _isSourcePlaying = false;

  bool _isResultPlaying = false;

  @override

  void dispose() {

    _sourceController?.dispose();

    _resultController?.dispose();

    super.dispose();

  }

  Future<void> _pickVideo() async {

    try {

      // file_picker version used by this project exposes pickFiles()

      // as a static method and returns List<PlatformFile>.

      final files = await FilePicker.pickFiles(

        type: FileType.video,

      );

      if (files.isEmpty) {

        return;

      }

      final path = files.single.path;

      if (path == null || path.isEmpty) {

        _showMessage(

          'Unable to access the selected video.',

        );

        return;

      }

      final file = File(path);

      if (!await file.exists()) {

        _showMessage(

          'Selected video no longer exists.',

        );

        return;

      }

      await _sourceController?.dispose();

      await _resultController?.dispose();

      _sourceController = null;

      _resultController = null;

      _isSourcePlaying = false;

      _isResultPlaying = false;

      final controller =

          VideoPlayerController.file(file);

      await controller.initialize();

      if (!mounted) {

        await controller.dispose();

        return;

      }

      final duration = controller.value.duration;

      if (duration <= Duration.zero) {

        await controller.dispose();

        _showMessage(

          'Unable to determine the video duration.',

        );

        return;

      }

      _sourceController = controller;

      ref.read(videoTrimmerProvider.notifier).setSourceFile(

            file: file,

            duration: duration,

          );

      setState(() {});

    } catch (error) {

      _showMessage(

        'Unable to open video: $error',

      );

    }

  }

  Future<void> _toggleSourcePlayback() async {

    final controller = _sourceController;

    if (controller == null ||

        !controller.value.isInitialized) {

      return;

    }

    if (controller.value.isPlaying) {

      await controller.pause();

      if (!mounted) {

        return;

      }

      setState(() {

        _isSourcePlaying = false;

      });

      return;

    }

    final state = ref.read(videoTrimmerProvider);

    await controller.seekTo(state.start);

    await controller.play();

    if (!mounted) {

      return;

    }

    setState(() {

      _isSourcePlaying = true;

    });

  }

  Future<void> _toggleResultPlayback() async {

    final controller = _resultController;

    if (controller == null ||

        !controller.value.isInitialized) {

      return;

    }

    if (controller.value.isPlaying) {

      await controller.pause();

      if (!mounted) {

        return;

      }

      setState(() {

        _isResultPlaying = false;

      });

      return;

    }

    await controller.seekTo(Duration.zero);

    await controller.play();

    if (!mounted) {

      return;

    }

    setState(() {

      _isResultPlaying = true;

    });

  }

  Future<void> _trimVideo() async {

    final notifier =

        ref.read(videoTrimmerProvider.notifier);

    await notifier.trim();

    if (!mounted) {

      return;

    }

    final state = ref.read(videoTrimmerProvider);

    final resultFile = state.resultFile;

    if (resultFile == null) {

      if (state.error != null) {

        _showMessage(state.error!);

      }

      return;

    }

    final loaded = await _loadResultVideo(resultFile.path);

    if (!mounted || !loaded) {
      return;
    }

    _showMessage(
      'Video trimmed successfully.',
    );

  }

  Future<bool> _loadResultVideo(String path) async {

    await _resultController?.dispose();

    _resultController = null;

    _isResultPlaying = false;

    final file = File(path);

    if (!await file.exists()) {

      if (mounted) {

        _showMessage(

          'Trimmed video file could not be found.',

        );

      }

      return false;

    }

    final controller =

        VideoPlayerController.file(file);

    try {

      await controller.initialize();

      if (!mounted) {

        await controller.dispose();

        return false;

      }

      _resultController = controller;

      setState(() {});
      return true;

    } catch (error) {

      await controller.dispose();

      if (mounted) {

        _showMessage(

          'Unable to preview trimmed video: $error',

        );

      }

      return false;
    }

  }

  void _showMessage(String message) {

    if (!mounted) {

      return;

    }

    ScaffoldMessenger.of(context)

      ..hideCurrentSnackBar()

      ..showSnackBar(

        SnackBar(

          content: Text(message),

        ),

      );

  }

  String _formatDuration(Duration duration) {

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

  double _durationToSliderValue(

    Duration value,

    Duration duration,

  ) {

    if (duration <= Duration.zero) {

      return 0;

    }

    return value.inMilliseconds /

        duration.inMilliseconds;

  }

  Duration _sliderValueToDuration(

    double value,

    Duration duration,

  ) {

    return Duration(

      milliseconds:

          (value * duration.inMilliseconds).round(),

    );

  }

  Future<void> _changeStart(double value) async {

    final state =

        ref.read(videoTrimmerProvider);

    final duration =

        _sliderValueToDuration(

      value,

      state.duration,

    );

    ref

        .read(videoTrimmerProvider.notifier)

        .setStart(duration);

    final controller = _sourceController;

    if (controller != null &&

        controller.value.isInitialized) {

      await controller.seekTo(duration);

    }

  }

  Future<void> _changeEnd(double value) async {

    final state =

        ref.read(videoTrimmerProvider);

    final duration =

        _sliderValueToDuration(

      value,

      state.duration,

    );

    ref

        .read(videoTrimmerProvider.notifier)

        .setEnd(duration);

    final controller = _sourceController;

    if (controller != null &&

        controller.value.isInitialized) {

      await controller.seekTo(duration);

    }

  }

  void _resetRange() {

    ref

        .read(videoTrimmerProvider.notifier)

        .resetTrimRange();

  }

  Future<void> _assignToCollection() async {

    final state =

        ref.read(videoTrimmerProvider);

    final file = state.resultFile;

    if (file == null) {

      return;

    }

    final collectionId =

        await _showCollectionSelector();

    if (!mounted || collectionId == null) {

      return;

    }

    try {

      await ref

          .read(videoTrimmerProvider.notifier)

          .assignToCollection(

            fileId: file.id,

            collectionId: collectionId,

          );

      if (!mounted) {

        return;

      }

      _showMessage(

        collectionId.isEmpty

            ? 'Removed from collection.'

            : 'Saved to collection.',

      );

    } catch (error) {

      _showMessage(

        'Unable to update collection: $error',

      );

    }

  }

  Future<String?> _showCollectionSelector() async {
    try {
      final database = ref.read(databaseProvider);
      final collections =
          await database.select(database.collections).get();

      if (!mounted) {
        return null;
      }

      if (collections.isEmpty) {
        _showMessage('No collections available. Create a collection first.');
        return null;
      }

      return showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Save to Collection'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: collections.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final collection = collections[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Color(collection.color)
                          .withValues(alpha: 0.16),
                      child: Icon(
                        Icons.folder_rounded,
                        color: Color(collection.color),
                      ),
                    ),
                    title: Text(collection.name),
                    subtitle: Text(
                      'Collection',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop(collection.id);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showMessage('Unable to load collections: $error');
      return null;
    }
  }

  Future<void> _openResultFile() async {

    final state =

        ref.read(videoTrimmerProvider);

    final file = state.resultFile;

    if (file == null) {

      return;

    }

    await _loadResultVideo(file.path);

  }

  @override

  Widget build(BuildContext context) {

    final state =

        ref.watch(videoTrimmerProvider);

    ref.listen<VideoTrimmerState>(

      videoTrimmerProvider,

      (previous, next) {

        if (next.error != null &&

            next.error != previous?.error) {

          _showMessage(next.error!);

        }

      },

    );

    return Scaffold(

      backgroundColor: AppColors.background,

      appBar: AppBar(

        backgroundColor: AppColors.background,

        elevation: 0,

        title: const Text('Video Trimmer'),

        actions: [

          if (state.sourceFile != null)

            IconButton(

              tooltip: 'Choose another video',

              onPressed:

                  state.isLoading ? null : _pickVideo,

              icon: const Icon(

                Icons.video_library_outlined,

              ),

            ),

        ],

      ),

      body: SafeArea(

        child: state.sourceFile == null

            ? _buildEmptyState()

            : _buildEditor(state),

      ),

    );

  }

  Widget _buildEmptyState() {

    return Center(

      child: Padding(

        padding: const EdgeInsets.all(

          AppSpacing.xl,

        ),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Container(

              width: 88,

              height: 88,

              decoration: BoxDecoration(

                color:

                    AppColors.primary.withValues(

                  alpha: 0.12,

                ),

                borderRadius:

                    BorderRadius.circular(

                  AppRadius.card,

                ),

              ),

              child: const Icon(

                Icons.video_library_outlined,

                size: 42,

                color: AppColors.primaryLight,

              ),

            ),

            const SizedBox(

              height: AppSpacing.lg,

            ),

            Text(

              'Trim a video',

              style: Theme.of(context)

                  .textTheme

                  .headlineSmall,

            ),

            const SizedBox(

              height: AppSpacing.xs,

            ),

            Text(

              'Select a video and choose the '

              'section you want to keep.',

              textAlign: TextAlign.center,

              style: Theme.of(context)

                  .textTheme

                  .bodyMedium

                  ?.copyWith(

                    color:

                        AppColors.textSecondary,

                  ),

            ),

            const SizedBox(

              height: AppSpacing.lg,

            ),

            FilledButton.icon(

              onPressed: _pickVideo,

              icon: const Icon(

                Icons.video_file_outlined,

              ),

              label: const Text(

                'Choose Video',

              ),

            ),

          ],

        ),

      ),

    );

  }

  Widget _buildEditor(

    VideoTrimmerState state,

  ) {

    return ListView(

      padding: const EdgeInsets.all(

        AppSpacing.lg,

      ),

      children: [

        _buildSectionTitle(

          title: 'Original Video',

          subtitle: state.sourceFile!.uri

              .pathSegments

              .last,

        ),

        const SizedBox(

          height: AppSpacing.md,

        ),

        _buildVideoCard(

          controller: _sourceController,

          isPlaying: _isSourcePlaying,

          onPlayPause:

              _toggleSourcePlayback,

        ),

        const SizedBox(

          height: AppSpacing.lg,

        ),

        _buildTrimControls(state),

        const SizedBox(

          height: AppSpacing.lg,

        ),

        _buildTrimButton(state),

        if (state.resultFile != null) ...[

          const SizedBox(

            height: AppSpacing.xl,

          ),

          _buildSectionTitle(

            title: 'Trimmed Video',

            subtitle: state.resultFile!.name,

          ),

          const SizedBox(

            height: AppSpacing.md,

          ),

          _buildVideoCard(

            controller: _resultController,

            isPlaying: _isResultPlaying,

            onPlayPause:

                _toggleResultPlayback,

          ),

          const SizedBox(

            height: AppSpacing.md,

          ),

          _buildResultInformation(state),

        ],

      ],

    );

  }

  Widget _buildSectionTitle({

    required String title,

    required String subtitle,

  }) {

    return Column(

      crossAxisAlignment:

          CrossAxisAlignment.start,

      children: [

        Text(

          title,

          style: Theme.of(context)

              .textTheme

              .titleLarge,

        ),

        const SizedBox(

          height: AppSpacing.xs,

        ),

        Text(

          subtitle,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: Theme.of(context)

              .textTheme

              .bodySmall

              ?.copyWith(

                color:

                    AppColors.textMuted,

              ),

        ),

      ],

    );

  }

  Widget _buildVideoCard({

    required VideoPlayerController? controller,

    required bool isPlaying,

    required VoidCallback onPlayPause,

  }) {

    if (controller == null ||

        !controller.value.isInitialized) {

      return Container(

        height: 220,

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

        child: const Center(

          child: CircularProgressIndicator(),

        ),

      );

    }

    final aspectRatio =

        controller.value.aspectRatio > 0

            ? controller.value.aspectRatio

            : 16 / 9;

    return Container(

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

      clipBehavior: Clip.antiAlias,

      child: AspectRatio(

        aspectRatio: aspectRatio,

        child: Stack(

          alignment: Alignment.center,

          children: [

            VideoPlayer(controller),

            Material(

              color:

                  Colors.black.withValues(

                alpha: 0.35,

              ),

              shape:

                  const CircleBorder(),

              child: InkWell(

                customBorder:

                    const CircleBorder(),

                onTap: onPlayPause,

                child: Padding(

                  padding:

                      const EdgeInsets.all(14),

                  child: Icon(

                    isPlaying

                        ? Icons.pause_rounded

                        : Icons.play_arrow_rounded,

                    size: 34,

                    color: Colors.white,

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

  Widget _buildTrimControls(

    VideoTrimmerState state,

  ) {

    final duration = state.duration;

    final start = state.start;

    final end = state.end ?? duration;

    final startValue =

        _durationToSliderValue(

      start,

      duration,

    );

    final endValue =

        _durationToSliderValue(

      end,

      duration,

    );

    return Container(

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

          Row(

            children: [

              const Icon(

                Icons.content_cut_rounded,

                size: 20,

                color:

                    AppColors.primaryLight,

              ),

              const SizedBox(

                width: AppSpacing.sm,

              ),

              Text(

                'Trim Range',

                style: Theme.of(context)

                    .textTheme

                    .titleMedium,

              ),

              const Spacer(),

              TextButton(

                onPressed:

                    state.isLoading

                        ? null

                        : _resetRange,

                child:

                    const Text('Reset'),

              ),

            ],

          ),

          const SizedBox(

            height: AppSpacing.md,

          ),

          Row(

            mainAxisAlignment:

                MainAxisAlignment.spaceBetween,

            children: [

              _TimeValue(

                label: 'START',

                value:

                    _formatDuration(start),

              ),

              _TimeValue(

                label: 'END',

                value:

                    _formatDuration(end),

                alignment:

                    CrossAxisAlignment.end,

              ),

            ],

          ),

          const SizedBox(

            height: AppSpacing.sm,

          ),

          if (duration > Duration.zero)

            _RangeSlider(

              start: startValue,

              end: endValue,

              onStartChanged:

                  state.isLoading

                      ? null

                      : _changeStart,

              onEndChanged:

                  state.isLoading

                      ? null

                      : _changeEnd,

            ),

          const SizedBox(

            height: AppSpacing.xs,

          ),

          Row(

            mainAxisAlignment:

                MainAxisAlignment.spaceBetween,

            children: [

              Text(

                '0:00',

                style: Theme.of(context)

                    .textTheme

                    .bodySmall

                    ?.copyWith(

                      color:

                          AppColors.textMuted,

                    ),

              ),

              Text(

                _formatDuration(duration),

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

          Container(

            padding:

                const EdgeInsets.all(

              AppSpacing.sm,

            ),

            decoration: BoxDecoration(

              color:

                  AppColors.background,

              borderRadius:

                  BorderRadius.circular(

                AppRadius.sm,

              ),

            ),

            child: Row(

              children: [

                const Icon(

                  Icons.timelapse_rounded,

                  size: 18,

                  color:

                      AppColors.textMuted,

                ),

                const SizedBox(

                  width: AppSpacing.sm,

                ),

                Text(

                  'Selected: ',

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

                    end - start,

                  ),

                  style: Theme.of(context)

                      .textTheme

                      .bodySmall

                      ?.copyWith(

                        fontWeight:

                            FontWeight.w600,

                      ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

  Widget _buildTrimButton(

    VideoTrimmerState state,

  ) {

    return SizedBox(

      width: double.infinity,

      child: FilledButton.icon(

        onPressed:

            state.isLoading ||

                    state.sourceFile == null

                ? null

                : _trimVideo,

        icon: state.isLoading

            ? const SizedBox(

                width: 18,

                height: 18,

                child:

                    CircularProgressIndicator(

                  strokeWidth: 2,

                  color: Colors.white,

                ),

              )

            : const Icon(

                Icons.content_cut_rounded,

              ),

        label: Text(

          state.isLoading

              ? 'Trimming Video...'

              : 'Trim Video',

        ),

      ),

    );

  }

  Widget _buildResultInformation(

    VideoTrimmerState state,

  ) {

    final file = state.resultFile!;

    return Container(

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

          Row(

            children: [

              Container(

                width: 42,

                height: 42,

                decoration: BoxDecoration(

                  color:

                      AppColors.primary.withValues(

                    alpha: 0.12,

                  ),

                  borderRadius:

                      BorderRadius.circular(

                    AppRadius.sm,

                  ),

                ),

                child: const Icon(

                  Icons.movie_outlined,

                  color:

                      AppColors.primaryLight,

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

                      overflow:

                          TextOverflow.ellipsis,

                      style: Theme.of(context)

                          .textTheme

                          .titleMedium,

                    ),

                    const SizedBox(

                      height: AppSpacing.xs,

                    ),

                    Text(

                      '${file.extension.toUpperCase()} • '

                      '${_formatFileSize(file.sizeBytes)}',

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

            ],

          ),

          const SizedBox(

            height: AppSpacing.md,

          ),

          Row(

            children: [

              Expanded(

                child:

                    OutlinedButton.icon(

                  onPressed:

                      _openResultFile,

                  icon: const Icon(

                    Icons.play_arrow_rounded,

                  ),

                  label: const Text(

                    'Preview',

                  ),

                ),

              ),

              const SizedBox(

                width: AppSpacing.sm,

              ),

              Expanded(

                child:

                    OutlinedButton.icon(

                  onPressed:

                      _assignToCollection,

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

      ),

    );

  }

  String _formatFileSize(int bytes) {

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

}

class _TimeValue extends StatelessWidget {

  const _TimeValue({

    required this.label,

    required this.value,

    this.alignment =

        CrossAxisAlignment.start,

  });

  final String label;

  final String value;

  final CrossAxisAlignment alignment;

  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: alignment,

      children: [

        Text(

          label,

          style: Theme.of(context)

              .textTheme

              .labelSmall

              ?.copyWith(

                color:

                    AppColors.textMuted,

                letterSpacing: 0.8,

              ),

        ),

        const SizedBox(

          height: AppSpacing.xs,

        ),

        Text(

          value,

          style: Theme.of(context)

              .textTheme

              .titleMedium

              ?.copyWith(

                fontWeight:

                    FontWeight.w600,

              ),

        ),

      ],

    );

  }

}

class _RangeSlider extends StatelessWidget {

  const _RangeSlider({

    required this.start,

    required this.end,

    required this.onStartChanged,

    required this.onEndChanged,

  });

  final double start;

  final double end;

  final ValueChanged<double>?

      onStartChanged;

  final ValueChanged<double>?

      onEndChanged;

  @override

  Widget build(BuildContext context) {

    return RangeSlider(

      values: RangeValues(

        start.clamp(0.0, 1.0),

        end.clamp(0.0, 1.0),

      ),

      min: 0,

      max: 1,

      divisions: 1000,

      labels: RangeLabels(

        '${(start * 100).round()}%',

        '${(end * 100).round()}%',

      ),

      onChanged:

          onStartChanged == null ||

                  onEndChanged == null

              ? null

              : (values) {

                  final currentStart =

                      values.start;

                  final currentEnd =

                      values.end;

                  if (currentStart != start) {

                    onStartChanged!(

                      currentStart,

                    );

                  }

                  if (currentEnd != end) {

                    onEndChanged!(

                      currentEnd,

                    );

                  }

                },

    );

  }

}
