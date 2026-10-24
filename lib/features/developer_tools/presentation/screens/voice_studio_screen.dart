import 'dart:async';

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import 'package:devvault/features/developer_tools/data/services/voice_effect_service.dart';

import 'package:devvault/features/developer_tools/presentation/widgets/voice/voice_effect_card.dart';

import 'package:devvault/features/developer_tools/presentation/widgets/voice/voice_player_controls.dart';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';

import '../../../../app/theme/app_radius.dart';

import '../../../../app/theme/app_spacing.dart';

import '../../../collections/presentation/providers/collections_providers.dart';

import '../../domain/entities/tool_file_entity.dart';

import '../providers/tool_file_providers.dart';

import '../providers/voice_studio_provider.dart';

import '../widgets/voice/voice_record_button.dart';

import '../widgets/voice/voice_waveform.dart';

class VoiceStudioScreen extends ConsumerStatefulWidget {

  const VoiceStudioScreen({super.key});

  @override

  ConsumerState<VoiceStudioScreen> createState() =>

      _VoiceStudioScreenState();

}

class _VoiceStudioScreenState

    extends ConsumerState<VoiceStudioScreen> {

  final AudioPlayer _recordingPlayer = AudioPlayer();

  final AudioPlayer _resultPlayer = AudioPlayer();

  StreamSubscription<PlayerState>? _recordingPlayerStateSubscription;

  StreamSubscription<Duration>? _recordingPositionSubscription;

  StreamSubscription<Duration>? _recordingDurationSubscription;

  StreamSubscription<PlayerState>? _resultPlayerStateSubscription;

  StreamSubscription<Duration>? _resultPositionSubscription;

  StreamSubscription<Duration>? _resultDurationSubscription;

  PlayerState _recordingPlayerState =

      PlayerState.stopped;

  PlayerState _resultPlayerState =

      PlayerState.stopped;

  Duration _recordingPosition = Duration.zero;

  Duration _recordingDuration = Duration.zero;

  Duration _resultPosition = Duration.zero;

  Duration _resultDuration = Duration.zero;

  String? _loadedRecordingPath;

  String? _loadedResultPath;

  @override

  void initState() {

    super.initState();

    _recordingPlayerStateSubscription =

        _recordingPlayer.onPlayerStateChanged.listen(

      (state) {

        if (!mounted) {

          return;

        }

        setState(() {

          _recordingPlayerState = state;

        });

      },

    );

    _recordingPositionSubscription =

        _recordingPlayer.onPositionChanged.listen(

      (position) {

        if (!mounted) {

          return;

        }

        setState(() {

          _recordingPosition = position;

        });

      },

    );

    _recordingDurationSubscription =

        _recordingPlayer.onDurationChanged.listen(

      (duration) {

        if (!mounted) {

          return;

        }

        setState(() {

          _recordingDuration = duration;

        });

      },

    );

    _resultPlayerStateSubscription =

        _resultPlayer.onPlayerStateChanged.listen(

      (state) {

        if (!mounted) {

          return;

        }

        setState(() {

          _resultPlayerState = state;

        });

      },

    );

    _resultPositionSubscription =

        _resultPlayer.onPositionChanged.listen(

      (position) {

        if (!mounted) {

          return;

        }

        setState(() {

          _resultPosition = position;

        });

      },

    );

    _resultDurationSubscription =

        _resultPlayer.onDurationChanged.listen(

      (duration) {

        if (!mounted) {

          return;

        }

        setState(() {

          _resultDuration = duration;

        });

      },

    );

  }

  @override

  void dispose() {

    _recordingPlayerStateSubscription?.cancel();

    _recordingPositionSubscription?.cancel();

    _recordingDurationSubscription?.cancel();

    _resultPlayerStateSubscription?.cancel();

    _resultPositionSubscription?.cancel();

    _resultDurationSubscription?.cancel();

    _recordingPlayer.dispose();

    _resultPlayer.dispose();

    super.dispose();

  }

  Future<void> _importMp3() async {
    if (!mounted) {
      return;
    }

    try {
      final files = await FilePicker.pickFiles(
  type: FileType.audio,
);

if (files.isEmpty || files.first.path == null) {
  return;
}

final selectedPath = files.first.path!;
      final extension = selectedPath.split('.').last.toLowerCase();

      if (extension != 'mp3') {
        _showMessage('Please select an MP3 file.');
        return;
      }

      final file = File(selectedPath);
      if (!await file.exists()) {
        _showMessage('Selected MP3 file could not be found.');
        return;
      }

      await _recordingPlayer.stop();
      await _resultPlayer.stop();

      _loadedRecordingPath = null;
      _loadedResultPath = null;

      await ref
          .read(voiceStudioProvider.notifier)
          .importRecording(file);

      if (!mounted) {
        return;
      }

      setState(() {
        _recordingPlayerState = PlayerState.stopped;
        _resultPlayerState = PlayerState.stopped;
        _recordingPosition = Duration.zero;
        _recordingDuration = Duration.zero;
        _resultPosition = Duration.zero;
        _resultDuration = Duration.zero;
      });
    } catch (error) {
      _showMessage('Unable to import MP3: $error');
    }
  }

  Future<void> _toggleRecording() async {

    final notifier =

        ref.read(voiceStudioProvider.notifier);

    final state = ref.read(voiceStudioProvider);

    if (state.isRecording) {

      await notifier.stopRecording();

    } else {

      await notifier.startRecording();

    }

  }



  Future<void> _toggleRecordingPlayback(

  File file,

) async {

  try {

    await _resultPlayer.stop();

    final sourceChanged =

        _loadedRecordingPath != file.path;

    if (sourceChanged) {

      await _recordingPlayer.stop();

      await _recordingPlayer.setSourceDeviceFile(

        file.path,

      );

      _loadedRecordingPath = file.path;

      final duration =

          await _recordingPlayer.getDuration();

      if (mounted) {

        setState(() {

          _recordingDuration =

              duration ?? Duration.zero;

          _recordingPosition = Duration.zero;

          _recordingPlayerState =

              PlayerState.stopped;

        });

      }

    }

    if (_recordingPlayerState == PlayerState.playing) {

      await _recordingPlayer.pause();

    } else {

      try {

        await _recordingPlayer.resume();

      } catch (_) {

        // The native player may have lost its source.

        // Reload it and start from the current position.

        final position = _recordingPosition;

        await _recordingPlayer.setSourceDeviceFile(

          file.path,

        );

        _loadedRecordingPath = file.path;

        await _recordingPlayer.seek(position);

        await _recordingPlayer.resume();

      }

    }

  } catch (error) {

    _showMessage(

      'Unable to play recording: $error',

    );

  }

}

  Future<void> _restartRecordingPlayback(

  File file,

) async {

  try {

    // Stop anything else currently playing.

    await _resultPlayer.stop();

    await _recordingPlayer.stop();

    // Always reload the source.

    //

    // This is important because stop() can leave the native

    // AudioPlayer without a usable source for seek/resume.

    await _recordingPlayer.setSourceDeviceFile(

      file.path,

    );

    _loadedRecordingPath = file.path;

    final duration =

        await _recordingPlayer.getDuration();

    if (mounted) {

      setState(() {

        _recordingDuration =

            duration ?? Duration.zero;

        _recordingPosition = Duration.zero;

        _recordingPlayerState =

            PlayerState.stopped;

      });

    }

    // play() starts from the beginning of the newly

    // loaded source. No seek() is required.

    await _recordingPlayer.play(

      DeviceFileSource(file.path),

    );

  } catch (error) {

    _showMessage(

      'Unable to restart recording: $error',

    );

  }

}

  Future<void> _seekRecording(

  Duration position,

) async {

  try {

    if (_loadedRecordingPath == null) {

      return;

    }

    final file = File(_loadedRecordingPath!);

    if (!await file.exists()) {

      return;

    }

    final duration = _recordingDuration;

    if (duration <= Duration.zero) {

      return;

    }

    final safePosition =

        position < Duration.zero

            ? Duration.zero

            : position > duration

                ? duration

                : position;

    await _recordingPlayer.seek(

      safePosition,

    );

  } catch (error) {

    // Seeking should never crash the studio.

    // If the native player lost its source, reload it.

    try {

      final path = _loadedRecordingPath;

      if (path == null) {

        return;

      }

      final file = File(path);

      if (!await file.exists()) {

        return;

      }

      await _recordingPlayer.setSourceDeviceFile(

        path,

      );

      _loadedRecordingPath = path;

      await _recordingPlayer.seek(

        position < Duration.zero

            ? Duration.zero

            : position,

      );

    } catch (_) {

      // Ignore a failed seek rather than crashing the screen.

    }

  }

}

  Future<void> _toggleResultPlayback(

    ToolFileEntity file,

  ) async {

    try {

      await _recordingPlayer.stop();

      if (_loadedResultPath != file.path) {

        await _resultPlayer.stop();

        await _resultPlayer.setSourceDeviceFile(

          file.path,

        );

        _loadedResultPath = file.path;

        final duration =

            await _resultPlayer.getDuration();

        if (mounted) {

          setState(() {

            _resultDuration =

                duration ?? Duration.zero;

            _resultPosition = Duration.zero;

          });

        }

      }

      if (_resultPlayerState ==

          PlayerState.playing) {

        await _resultPlayer.pause();

      } else {

        await _resultPlayer.resume();

      }

    } catch (error) {

      _showMessage(

        'Unable to play processed audio: $error',

      );

    }

  }

  Future<void> _restartResultPlayback(

  ToolFileEntity file,

) async {

  try {

    await _recordingPlayer.stop();

    await _resultPlayer.stop();

    final sourceFile = File(file.path);

    if (!await sourceFile.exists()) {

      _showMessage(

        'The processed audio file is no longer available.',

      );

      return;

    }

    // Always reload the processed audio source.

    await _resultPlayer.setSourceDeviceFile(

      file.path,

    );

    _loadedResultPath = file.path;

    final duration =

        await _resultPlayer.getDuration();

    if (mounted) {

      setState(() {

        _resultDuration =

            duration ?? Duration.zero;

        _resultPosition = Duration.zero;

        _resultPlayerState =

            PlayerState.stopped;

      });

    }

    await _resultPlayer.play(

      DeviceFileSource(file.path),

    );

  } catch (error) {

    _showMessage(

      'Unable to restart processed audio: $error',

    );

  }

}

  Future<void> _seekResult(

    Duration position,

  ) async {

    await _resultPlayer.seek(position);

  }

  Future<void> _applyEffect() async {

  final state = ref.read(voiceStudioProvider);

  if (state.recordingFile == null) {

    _showMessage(

      'Record some audio first.',

    );

    return;

  }

  try {

    await _recordingPlayer.stop();

    await _resultPlayer.stop();

    // The native player source may no longer be usable

    // after processing. Force the playback methods to

    // reload it when needed.

    _loadedRecordingPath = null;

    _loadedResultPath = null;

    if (mounted) {

      setState(() {

        _recordingPlayerState =

            PlayerState.stopped;

        _resultPlayerState =

            PlayerState.stopped;

        _recordingPosition =

            Duration.zero;

        _resultPosition =

            Duration.zero;

      });

    }

    await ref

        .read(voiceStudioProvider.notifier)

        .applyEffect();

  } catch (error) {

    _showMessage(

      'Unable to apply effect: $error',

    );

  }

}

  Future<void> _saveToDevice(

    ToolFileEntity file,

  ) async {

    try {

      final sourceFile = File(file.path);

      if (!await sourceFile.exists()) {

        _showMessage(

          'The processed audio file is no longer available.',

        );

        return;

      }

      final bytes =

          await sourceFile.readAsBytes();

      final output = await FilePicker.saveFile(

        dialogTitle: 'Save processed audio',

        fileName: file.name,

        bytes: bytes,

        mimeType:

            file.mimeType ?? 'audio/mpeg',

        type: FileType.audio,

      );

      if (!mounted || output == null) {

        return;

      }

      _showMessage(

        'Audio exported successfully.',

      );

    } catch (error) {

      _showMessage(

        'Unable to export audio: $error',

      );

    }

  }

  Future<void> _addToCollection(

    ToolFileEntity file,

  ) async {

    final collectionsAsync =

        ref.read(collectionsProvider);

    final collections =

        collectionsAsync.when(

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

    if (collections.isEmpty) {

      _showMessage(

        'Create a collection first.',

      );

      return;

    }

    final collectionId =

        await showModalBottomSheet<String?>(

      context: context,

      showDragHandle: true,

      backgroundColor: AppColors.surface,

      builder: (sheetContext) {

        return SafeArea(

          child: ListView(

            shrinkWrap: true,

            padding: const EdgeInsets.all(

              AppSpacing.md,

            ),

            children: [

              Padding(

                padding: const EdgeInsets.all(

                  AppSpacing.md,

                ),

                child: Text(

                  'Add to Collection',

                  style: Theme.of(context)

                      .textTheme

                      .titleLarge,

                ),

              ),

              for (final collection

                  in collections)

                ListTile(

                  leading: CircleAvatar(

                    backgroundColor:

                        Color(collection.color),

                    child: const Icon(

                      Icons.folder_rounded,

                      color: Colors.white,

                    ),

                  ),

                  title: Text(

                    collection.name,

                  ),

                  trailing: const Icon(

                    Icons.chevron_right_rounded,

                  ),

                  onTap: () {

                    Navigator.of(

                      sheetContext,

                    ).pop(collection.id);

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

    try {

      final updatedFile =

          ToolFileEntity(

        id: file.id,

        name: file.name,

        path: file.path,

        extension: file.extension,

        mimeType: file.mimeType,

        sizeBytes: file.sizeBytes,

        toolType: file.toolType,

        collectionId: collectionId,

        createdAt: file.createdAt,

        updatedAt: DateTime.now(),

      );

      await ref

          .read(saveToolFileProvider)

          .call(updatedFile);

      ref.invalidate(

        toolFilesProvider,

      );

      ref.invalidate(

        toolFilesByCollectionProvider(

          collectionId,

        ),

      );

      if (!mounted) {

        return;

      }

      _showMessage(

        'Added to collection.',

      );

    } catch (error) {

      _showMessage(

        'Unable to add audio to collection: $error',

      );

    }

  }

  Future<void> _clearStudio() async {

    await _recordingPlayer.stop();

    await _resultPlayer.stop();

    _loadedRecordingPath = null;

    _loadedResultPath = null;

    if (mounted) {

      setState(() {

        _recordingPosition =

            Duration.zero;

        _recordingDuration =

            Duration.zero;

        _resultPosition =

            Duration.zero;

        _resultDuration =

            Duration.zero;

      });

    }

    await ref

        .read(voiceStudioProvider.notifier)

        .clear();

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

  String _formatDuration(

    Duration duration,

  ) {

    final minutes =

        duration.inMinutes.remainder(60);

    final seconds =

        duration.inSeconds.remainder(60);

    final milliseconds =

        duration.inMilliseconds

            .remainder(1000);

    return '${minutes.toString().padLeft(2, '0')}:'

        '${seconds.toString().padLeft(2, '0')}.'

        '${(milliseconds ~/ 10).toString().padLeft(2, '0')}';
  }

  String _effectTitle(

    VoiceEffect effect,

  ) {

    switch (effect.name) {

      case 'normal':

        return 'Normal';

      case 'deepVoice':

        return 'Deep Voice';

      case 'highPitch':

        return 'High Pitch';

      case 'robot':

        return 'Robot';

      case 'echo':

        return 'Echo';

      case 'reverb':

        return 'Reverb';

      case 'chipmunk':

        return 'Chipmunk';

      case 'slow':

        return 'Slow';

      case 'fast':

        return 'Fast';

      default:

        final name = effect.name

            .replaceAll('_', ' ');

        return name

            .split(' ')

            .map(

              (word) => word.isEmpty

                  ? word

                  : '${word[0].toUpperCase()}'

                      '${word.substring(1)}',

            )

            .join(' ');

    }

  }

  IconData _effectIcon(

    VoiceEffect effect,

  ) {

    switch (effect.name) {

      case 'normal':

        return Icons.graphic_eq_rounded;

      case 'deepVoice':

        return Icons.mic_rounded;

      case 'highPitch':

        return Icons.arrow_upward_rounded;

      case 'robot':

        return Icons.smart_toy_rounded;

      case 'echo':

        return Icons.waves_rounded;

      case 'reverb':

        return Icons.blur_on_rounded;

      case 'chipmunk':

        return Icons.pets_rounded;

      case 'slow':

        return Icons.slow_motion_video_rounded;

      case 'fast':

        return Icons.speed_rounded;

      default:

        return Icons.auto_fix_high_rounded;

    }

  }

  Color _effectColor(

    VoiceEffect effect,

  ) {

    switch (effect.name) {

      case 'deepVoice':

        return Colors.greenAccent;

      case 'highPitch':

        return Colors.amber;

      case 'robot':

        return Colors.cyanAccent;

      case 'echo':

        return Colors.deepPurpleAccent;

      case 'reverb':

        return Colors.indigoAccent;

      case 'chipmunk':

        return Colors.orangeAccent;

      case 'slow':

        return Colors.amberAccent;

      case 'fast':

        return Colors.cyanAccent;

      default:

        return AppColors.primaryLight;

    }

  }

  @override

  Widget build(BuildContext context) {

    final state =

        ref.watch(voiceStudioProvider);

    ref.listen<VoiceStudioState>(

      voiceStudioProvider,

      (previous, next) {

        if (next.error != null &&

            next.error != previous?.error) {

          _showMessage(next.error!);

        }

        if (next.resultFile != null &&

            next.resultFile !=

                previous?.resultFile) {

          _loadedResultPath = null;

          if (mounted) {

            setState(() {

              _resultPlayerState =

                  PlayerState.stopped;

              _resultPosition =

                  Duration.zero;

              _resultDuration =

                  Duration.zero;

            });

          }

          _showMessage(

            'Voice effect applied successfully.',

          );

        }

      },

    );

    final recordingFile =

        state.recordingFile;

    final resultFile =

        state.resultFile;

    return Scaffold(

      backgroundColor:

          AppColors.background,

      appBar: AppBar(

        backgroundColor:

            AppColors.background,

        elevation: 0,

        leading: IconButton(

          tooltip: 'Back',

          onPressed: () {

            Navigator.of(context).maybePop();

          },

          icon: const Icon(

            Icons.arrow_back_rounded,

          ),

        ),

        title: const Column(

          crossAxisAlignment:

              CrossAxisAlignment.start,

          children: [

            Text(

              'Voice Studio',

            ),

            Text(

              'Record and transform your voice',

              style: TextStyle(

                fontSize: 11,

                fontWeight: FontWeight.w400,

                color:

                    AppColors.textMuted,

              ),

            ),

          ],

        ),

        actions: [

          if (recordingFile != null ||

              resultFile != null)

            IconButton(

              tooltip: 'Clear',

              onPressed: state.isLoading ||

                      state.isRecording

                  ? null

                  : _clearStudio,

              icon: const Icon(

                Icons.refresh_rounded,

              ),

            ),

        ],

      ),

      body: SafeArea(

        child: ListView(

          padding: const EdgeInsets.fromLTRB(

            AppSpacing.lg,

            AppSpacing.md,

            AppSpacing.lg,

            120,

          ),

          children: [

            _StudioHeader(

              isRecording:

                  state.isRecording,

              isPaused:

                  state.isPaused,

              duration:

                  state.recordingDuration,

              formatDuration:

                  _formatDuration,

            ),

            const SizedBox(

              height: AppSpacing.lg,

            ),

            VoiceWaveform(

              amplitude: state.amplitude,

              isRecording:

                  state.isRecording &&

                      !state.isPaused,

              height: 110,

              barCount: 42,

            ),

            const SizedBox(

              height: AppSpacing.lg,

            ),

            // Recording controls.

            _RecordingControls(

              isRecording:

                  state.isRecording,

              isPaused:

                  state.isPaused,

              isLoading:

                  state.isLoading,

              onRecord:

                  _toggleRecording,

              onPause: () async {

                await ref

                    .read(

                      voiceStudioProvider

                          .notifier,

                    )

                    .pauseRecording();

              },

              onResume: () async {

                await ref

                    .read(

                      voiceStudioProvider

                          .notifier,

                    )

                    .resumeRecording();

              },

              onStop: () async {

                await ref

                    .read(

                      voiceStudioProvider

                          .notifier,

                    )

                    .stopRecording();

              },

            ),

            if (recordingFile != null) ...[

              const SizedBox(

                height: AppSpacing.lg,

              ),

              _SectionTitle(

                title: 'Your Recording',

                subtitle:

                    'Preview the original audio',

              ),

              const SizedBox(

                height: AppSpacing.sm,

              ),

              _AudioPreviewCard(

                fileName:

                    recordingFile.path

                        .split(

                          Platform.pathSeparator,

                        )

                        .last,

                isPlaying:

                    _recordingPlayerState ==

                        PlayerState.playing,

                position:

                    _recordingPosition,

                duration:

                    _recordingDuration,

                onToggle: () {

                  _toggleRecordingPlayback(

                    recordingFile,

                  );

                },

                onRestart: () {

                  _restartRecordingPlayback(

                    recordingFile,

                  );

                },

                onSeek:

                    _seekRecording,

                formatDuration:

                    _formatDuration,

              ),

            ],

            if (recordingFile != null) ...[

              const SizedBox(

                height: AppSpacing.xl,

              ),

              _SectionTitle(

                title: 'Voice Effects',

                subtitle:

                    'Choose an effect to transform your recording',

              ),

              const SizedBox(

                height: AppSpacing.md,

              ),

              _EffectsGrid(

                selectedEffect:

                    state.selectedEffect,

                enabled:

                    !state.isLoading &&

                        !state.isRecording,

                onSelected:

                    (effect) {

                  ref

                      .read(

                        voiceStudioProvider

                            .notifier,

                      )

                      .selectEffect(effect);

                },

                titleForEffect:

                    _effectTitle,

                iconForEffect:

                    _effectIcon,

                colorForEffect:

                    _effectColor,

              ),

              const SizedBox(

                height: AppSpacing.lg,

              ),

              SizedBox(

                height: 54,

                child: FilledButton.icon(

                  onPressed:

                      state.isLoading ||

                              state.isRecording

                          ? null

                          : _applyEffect,

                  icon: state.isLoading

                      ? const SizedBox(

                          width: 20,

                          height: 20,

                          child:

                              CircularProgressIndicator(

                            strokeWidth: 2,

                            color: Colors.white,

                          ),

                        )

                      : const Icon(

                          Icons.auto_fix_high_rounded,

                        ),

                  label: Text(

                    state.isLoading

                        ? 'Applying Effect...'

                        : 'Apply ${_effectTitle(state.selectedEffect)}',

                  ),

                ),

              ),

            ],

            if (resultFile != null) ...[

              const SizedBox(

                height: AppSpacing.xl,

              ),

              _SectionTitle(

                title: 'Processed Audio',

                subtitle:

                    '${_effectTitle(state.selectedEffect)} effect',

              ),

              const SizedBox(

                height: AppSpacing.sm,

              ),

              _AudioPreviewCard(

                fileName:

                    resultFile.name,

                isPlaying:

                    _resultPlayerState ==

                        PlayerState.playing,

                position:

                    _resultPosition,

                duration:

                    _resultDuration,

                onToggle: () {

                  _toggleResultPlayback(

                    resultFile,

                  );

                },

                onRestart: () {

                  _restartResultPlayback(

                    resultFile,

                  );

                },

                onSeek:

                    _seekResult,

                formatDuration:

                    _formatDuration,

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

                          state.isLoading

                              ? null

                              : () {

                                  _saveToDevice(

                                    resultFile,

                                  );

                                },

                      icon: const Icon(

                        Icons.download_outlined,

                      ),

                      label:

                          const Text(

                        'Save / Export',

                      ),

                    ),

                  ),

                  const SizedBox(

                    width: AppSpacing.sm,

                  ),

                  Expanded(

                    child:

                        FilledButton.icon(

                      onPressed:

                          state.isLoading

                              ? null

                              : () {

                                  _addToCollection(

                                    resultFile,

                                  );

                                },

                      icon: const Icon(

                        Icons.folder_outlined,

                      ),

                      label:

                          const Text(

                        'Collection',

                      ),

                    ),

                  ),

                ],

              ),

            ],

            if (recordingFile == null &&

                !state.isRecording) ...[

              const SizedBox(

                height: AppSpacing.xl,

              ),

              _EmptyStudioState(
                onImportMp3: _importMp3,
              ),

            ],

          ],

        ),

      ),

    );

  }

}

class _StudioHeader extends StatelessWidget {

  const _StudioHeader({

    required this.isRecording,

    required this.isPaused,

    required this.duration,

    required this.formatDuration,

  });

  final bool isRecording;

  final bool isPaused;

  final Duration duration;

  final String Function(Duration)

      formatDuration;

  @override

  Widget build(BuildContext context) {

    String status;

    if (isPaused) {

      status = 'Paused';

    } else if (isRecording) {

      status = 'Recording...';

    } else {

      status = 'Ready to record';

    }

    return Column(

      children: [

        Text(

          formatDuration(duration),

          style: Theme.of(context)

              .textTheme

              .displaySmall

              ?.copyWith(

                fontWeight:

                    FontWeight.w700,

                letterSpacing: 1,

              ),

        ),

        const SizedBox(

          height: AppSpacing.xs,

        ),

        AnimatedSwitcher(

          duration:

              const Duration(

            milliseconds: 180,

          ),

          child: Text(

            status,

            key: ValueKey(status),

            style: Theme.of(context)

                .textTheme

                .bodyMedium

                ?.copyWith(

                  color: isRecording

                      ? AppColors.primaryLight

                      : AppColors.textMuted,

                  fontWeight:

                      FontWeight.w500,

                ),

          ),

        ),

      ],

    );

  }

}

class _RecordingControls

    extends StatelessWidget {

  const _RecordingControls({

    required this.isRecording,

    required this.isPaused,

    required this.isLoading,

    required this.onRecord,

    required this.onPause,

    required this.onResume,

    required this.onStop,

  });

  final bool isRecording;

  final bool isPaused;

  final bool isLoading;

  final VoidCallback onRecord;

  final VoidCallback onPause;

  final VoidCallback onResume;

  final VoidCallback onStop;

  @override

  Widget build(BuildContext context) {

    if (!isRecording) {

      return Center(

        child: VoiceRecordButton(

          isRecording: false,

          enabled: !isLoading,

          onPressed: onRecord,

        ),

      );

    }

    return Column(

      children: [

        Row(

          mainAxisAlignment:

              MainAxisAlignment.center,

          children: [

            _RoundActionButton(

              icon: Icons.close_rounded,

              tooltip: 'Discard',

              onPressed:

                  isLoading ? null : onStop,

              background:

                  AppColors.surface,

            ),

            const SizedBox(

              width: 28,

            ),

            VoiceRecordButton(

              isRecording: true,

              enabled: !isLoading,

              onPressed:

                  isPaused

                      ? onResume

                      : onPause,

            ),

            const SizedBox(

              width: 28,

            ),

            _RoundActionButton(

              icon: Icons.check_rounded,

              tooltip: 'Finish recording',

              onPressed:

                  isLoading ? null : onStop,

              background:

                  AppColors.surface,

            ),

          ],

        ),

        const SizedBox(

          height: AppSpacing.sm,

        ),

        Text(

          isPaused

              ? 'Recording paused'

              : 'Tap the center to pause',

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

}

class _RoundActionButton

    extends StatelessWidget {

  const _RoundActionButton({

    required this.icon,

    required this.tooltip,

    required this.onPressed,

    required this.background,

  });

  final IconData icon;

  final String tooltip;

  final VoidCallback? onPressed;

  final Color background;

  @override

  Widget build(BuildContext context) {

    return Tooltip(

      message: tooltip,

      child: IconButton.filled(

        onPressed: onPressed,

        style: IconButton.styleFrom(

          backgroundColor: background,

          foregroundColor:

              AppColors.textPrimary,

          minimumSize:

              const Size(52, 52),

        ),

        icon: Icon(icon),

      ),

    );

  }

}

class _SectionTitle

    extends StatelessWidget {

  const _SectionTitle({

    required this.title,

    required this.subtitle,

  });

  final String title;

  final String subtitle;

  @override

  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment:

          CrossAxisAlignment.start,

      children: [

        Text(

          title,

          style: Theme.of(context)

              .textTheme

              .titleLarge

              ?.copyWith(

                fontWeight:

                    FontWeight.w700,

              ),

        ),

        const SizedBox(

          height: 2,

        ),

        Text(

          subtitle,

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

}

class _EffectsGrid

    extends StatelessWidget {

  const _EffectsGrid({

    required this.selectedEffect,

    required this.enabled,

    required this.onSelected,

    required this.titleForEffect,

    required this.iconForEffect,

    required this.colorForEffect,

  });

  final VoiceEffect selectedEffect;

  final bool enabled;

  final ValueChanged<VoiceEffect>

      onSelected;

  final String Function(VoiceEffect)

      titleForEffect;

  final IconData Function(VoiceEffect)

      iconForEffect;

  final Color Function(VoiceEffect)

      colorForEffect;

  @override

  Widget build(BuildContext context) {

    final effects = VoiceEffect.values;

    return GridView.builder(

      shrinkWrap: true,

      physics:

          const NeverScrollableScrollPhysics(),

      gridDelegate:

          const SliverGridDelegateWithFixedCrossAxisCount(

        crossAxisCount: 3,

        crossAxisSpacing: 10,

        mainAxisSpacing: 10,

        childAspectRatio: 1.0,

      ),

      itemCount: effects.length,

      itemBuilder: (context, index) {

        final effect = effects[index];

        final selected =

            effect == selectedEffect;

        final color =

            colorForEffect(effect);

        return VoiceEffectCard(

          title: titleForEffect(effect),

          icon: iconForEffect(effect),

          color: color,

          selected: selected,

          enabled: enabled,

          onTap: () {

            onSelected(effect);

          },

        );

      },

    );

  }

}

class _AudioPreviewCard

    extends StatelessWidget {

  const _AudioPreviewCard({

    required this.fileName,

    required this.isPlaying,

    required this.position,

    required this.duration,

    required this.onToggle,

    required this.onRestart,

    required this.onSeek,

    required this.formatDuration,

  });

  final String fileName;

  final bool isPlaying;

  final Duration position;

  final Duration duration;

  final VoidCallback onToggle;

  final VoidCallback onRestart;

  final ValueChanged<Duration> onSeek;

  final String Function(Duration)

      formatDuration;

  @override

  Widget build(BuildContext context) {

    final safeDuration =

        duration <= Duration.zero

            ? const Duration(seconds: 1)

            : duration;

    final safePosition =

        position > safeDuration

            ? safeDuration

            : position;

    return Container(

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

        children: [

          Row(

            children: [

              Container(

                width: 46,

                height: 46,

                decoration: BoxDecoration(

                  color: AppColors.primary

                      .withValues(alpha: 0.12),

                  borderRadius:

                      BorderRadius.circular(

                    AppRadius.sm,

                  ),

                ),

                child: const Icon(

                  Icons.audio_file_rounded,

                  color:

                      AppColors.primaryLight,

                ),

              ),

              const SizedBox(

                width: AppSpacing.md,

              ),

              Expanded(

                child: Text(

                  fileName,

                  maxLines: 1,

                  overflow:

                      TextOverflow.ellipsis,

                  style: Theme.of(context)

                      .textTheme

                      .titleSmall,

                ),

              ),

            ],

          ),

          const SizedBox(

            height: AppSpacing.md,

          ),

          VoicePlayerControls(

            isPlaying: isPlaying,

            position: safePosition,

            duration: safeDuration,

            onToggle: onToggle,

            onRestart: onRestart,

            onSeek: onSeek,

            formatDuration:

                formatDuration,

          ),

        ],

      ),

    );

  }

}

class _EmptyStudioState

    extends StatelessWidget {

  const _EmptyStudioState({
    required this.onImportMp3,
  });

  final VoidCallback onImportMp3;

  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(

        AppSpacing.xl,

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

        children: [

          Container(

            width: 72,

            height: 72,

            decoration: BoxDecoration(

              color: AppColors.primary

                  .withValues(alpha: 0.12),

              shape: BoxShape.circle,

            ),

            child: const Icon(

              Icons.mic_none_rounded,

              size: 34,

              color:

                  AppColors.primaryLight,

            ),

          ),

          const SizedBox(

            height: AppSpacing.md,

          ),

          Text(

            'Ready to record',

            style: Theme.of(context)

                .textTheme

                .titleMedium

                ?.copyWith(

                  fontWeight:

                      FontWeight.w700,

                ),

          ),

          const SizedBox(

            height: AppSpacing.xs,

          ),

          Text(

            'Record your voice, preview it, '

            'then apply an effect.',

            textAlign:

                TextAlign.center,

            style: Theme.of(context)

                .textTheme

                .bodyMedium

                ?.copyWith(

                  color:

                      AppColors.textMuted,

                  height: 1.4,

                ),

          ),
          const SizedBox(

            height: AppSpacing.lg,

          ),

          SizedBox(

            width: double.infinity,

            height: 48,

            child: OutlinedButton.icon(

              onPressed: onImportMp3,

              icon: const Icon(

                Icons.file_upload_outlined,

              ),

              label: const Text('Import MP3'),

            ),

          ),

        ],

      ),

    );

  }

}