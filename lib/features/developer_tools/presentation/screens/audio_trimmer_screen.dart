import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:devvault/features/collections/presentation/providers/collections_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/tool_file_entity.dart';
import '../providers/audio_trimmer_provider.dart';
import '../providers/tool_file_providers.dart';

class AudioTrimmerScreen extends ConsumerStatefulWidget {
  const AudioTrimmerScreen({
    super.key,
  });

  @override
  ConsumerState<AudioTrimmerScreen> createState() =>
      _AudioTrimmerScreenState();
}

class _AudioTrimmerScreenState
    extends ConsumerState<AudioTrimmerScreen> {
  File? _selectedFile;

  Duration _duration = Duration.zero;
  Duration _start = Duration.zero;
  Duration _end = Duration.zero;

  // ============================================================
  // ORIGINAL AUDIO PLAYER
  // ============================================================

  final AudioPlayer _originalPlayer = AudioPlayer();

  StreamSubscription<Duration>? _originalPositionSubscription;
  StreamSubscription<Duration>? _originalDurationSubscription;
  StreamSubscription<PlayerState>? _originalPlayerStateSubscription;
  StreamSubscription<void>? _originalCompletionSubscription;

  Duration _originalPlaybackPosition = Duration.zero;
  Duration _originalPlaybackDuration = Duration.zero;

  PlayerState _originalPlayerState = PlayerState.stopped;

  String? _loadedOriginalAudioPath;

  // ============================================================
  // TRIMMED AUDIO PLAYER
  // ============================================================

  final AudioPlayer _trimmedPlayer = AudioPlayer();

  StreamSubscription<Duration>? _trimmedPositionSubscription;
  StreamSubscription<Duration>? _trimmedDurationSubscription;
  StreamSubscription<PlayerState>? _trimmedPlayerStateSubscription;
  StreamSubscription<void>? _trimmedCompletionSubscription;

  Duration _trimmedPlaybackPosition = Duration.zero;
  Duration _trimmedPlaybackDuration = Duration.zero;

  PlayerState _trimmedPlayerState = PlayerState.stopped;

  String? _loadedTrimmedAudioPath;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // ORIGINAL PLAYER LISTENERS
    // ==========================================================

    _originalPositionSubscription =
        _originalPlayer.onPositionChanged.listen((position) {
      if (!mounted) {
        return;
      }

      setState(() {
        _originalPlaybackPosition = position;
      });
    });

    _originalDurationSubscription =
        _originalPlayer.onDurationChanged.listen((duration) {
      if (!mounted) {
        return;
      }

      setState(() {
        _originalPlaybackDuration = duration;
      });
    });

    _originalPlayerStateSubscription =
        _originalPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _originalPlayerState = state;
      });
    });

    _originalCompletionSubscription =
        _originalPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _originalPlaybackPosition = _originalPlaybackDuration;
        _originalPlayerState = PlayerState.completed;
      });
    });

    // ==========================================================
    // TRIMMED PLAYER LISTENERS
    // ==========================================================

    _trimmedPositionSubscription =
        _trimmedPlayer.onPositionChanged.listen((position) {
      if (!mounted) {
        return;
      }

      setState(() {
        _trimmedPlaybackPosition = position;
      });
    });

    _trimmedDurationSubscription =
        _trimmedPlayer.onDurationChanged.listen((duration) {
      if (!mounted) {
        return;
      }

      setState(() {
        _trimmedPlaybackDuration = duration;
      });
    });

    _trimmedPlayerStateSubscription =
        _trimmedPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() {
        _trimmedPlayerState = state;
      });
    });

    _trimmedCompletionSubscription =
        _trimmedPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _trimmedPlaybackPosition = _trimmedPlaybackDuration;
        _trimmedPlayerState = PlayerState.completed;
      });
    });
  }

  @override
  void dispose() {
    // Original player subscriptions.
    _originalPositionSubscription?.cancel();
    _originalDurationSubscription?.cancel();
    _originalPlayerStateSubscription?.cancel();
    _originalCompletionSubscription?.cancel();

    // Trimmed player subscriptions.
    _trimmedPositionSubscription?.cancel();
    _trimmedDurationSubscription?.cancel();
    _trimmedPlayerStateSubscription?.cancel();
    _trimmedCompletionSubscription?.cancel();

    _originalPlayer.dispose();
    _trimmedPlayer.dispose();

    super.dispose();
  }

  // ============================================================
  // PICK AUDIO
  // ============================================================

  Future<void> _pickAudio() async {
    final selected = await FilePicker.pickFile(
      type: FileType.audio,
    );

    if (selected == null) {
      return;
    }

    final selectedPath = selected.path;

    if (selectedPath == null) {
      _showMessage(
        'Unable to access the selected audio file.',
      );
      return;
    }

    final selectedFile = File(selectedPath);

    if (!await selectedFile.exists()) {
      _showMessage(
        'The selected audio file is no longer available.',
      );
      return;
    }

    await _stopOriginalPlayback();
    await _stopTrimmedPlayback();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedFile = selectedFile;

      _duration = Duration.zero;
      _start = Duration.zero;
      _end = Duration.zero;

      _originalPlaybackPosition = Duration.zero;
      _originalPlaybackDuration = Duration.zero;

      _trimmedPlaybackPosition = Duration.zero;
      _trimmedPlaybackDuration = Duration.zero;

      _loadedOriginalAudioPath = null;
      _loadedTrimmedAudioPath = null;

      _originalPlayerState = PlayerState.stopped;
      _trimmedPlayerState = PlayerState.stopped;
    });

    try {
      await _originalPlayer.setSourceDeviceFile(
        selectedPath,
      );

      _loadedOriginalAudioPath = selectedPath;

      final loadedDuration =
          await _originalPlayer.getDuration();

      if (!mounted) {
        return;
      }

      if (loadedDuration == null ||
          loadedDuration <= Duration.zero) {
        _showMessage(
          'Unable to determine audio duration.',
        );
        return;
      }

      setState(() {
        _duration = loadedDuration;
        _start = Duration.zero;
        _end = loadedDuration;

        _originalPlaybackDuration = loadedDuration;
      });
    } catch (error) {
      _showMessage(
        'Unable to load audio preview: $error',
      );
    }

    ref
        .read(audioTrimmerProvider.notifier)
        .clear();
  }

  // ============================================================
  // ORIGINAL AUDIO
  // ============================================================

  Future<void> _stopOriginalPlayback() async {
    try {
      await _originalPlayer.stop();
    } catch (_) {
      // Player may already be stopped.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _originalPlaybackPosition = Duration.zero;
      _originalPlayerState = PlayerState.stopped;
    });
  }

  Future<void> _playSelectedAudio() async {
    final file = _selectedFile;

    if (file == null) {
      _showMessage(
        'Select an audio file first.',
      );
      return;
    }

    try {
      // Never allow both players to play simultaneously.
      await _stopTrimmedPlayback();

      if (_loadedOriginalAudioPath != file.path) {
        await _originalPlayer.setSourceDeviceFile(
          file.path,
        );

        _loadedOriginalAudioPath = file.path;

        final duration =
            await _originalPlayer.getDuration();

        if (duration != null && mounted) {
          setState(() {
            _originalPlaybackDuration = duration;
          });
        }
      }

      await _originalPlayer.seek(_start);
      await _originalPlayer.resume();
    } catch (error) {
      _showMessage(
        'Unable to play audio: $error',
      );
    }
  }

  Future<void> _toggleSelectedAudio() async {
    if (_originalPlayerState == PlayerState.playing) {
      await _originalPlayer.pause();
      return;
    }

    await _playSelectedAudio();
  }

  Future<void> _seekOriginalPlayback(
    double milliseconds,
  ) async {
    await _originalPlayer.seek(
      Duration(
        milliseconds: milliseconds.round(),
      ),
    );
  }

  // ============================================================
  // TRIMMING
  // ============================================================

  Future<void> _trim() async {
    final file = _selectedFile;

    if (file == null) {
      _showMessage(
        'Select an audio file first.',
      );
      return;
    }

    if (_duration <= Duration.zero) {
      _showMessage(
        'Audio duration is not available.',
      );
      return;
    }

    if (_start >= _end) {
      _showMessage(
        'Start time must be before end time.',
      );
      return;
    }

    if (_end > _duration) {
      _showMessage(
        'End time cannot exceed the audio duration.',
      );
      return;
    }

    await _stopOriginalPlayback();
    await _stopTrimmedPlayback();

    await ref.read(
      audioTrimmerProvider.notifier,
    ).trim(
          file: file,
          start: _start,
          end: _end,
        );
  }

  // ============================================================
  // TRIMMED AUDIO
  // ============================================================

  Future<void> _stopTrimmedPlayback() async {
    try {
      await _trimmedPlayer.stop();
    } catch (_) {
      // Player may already be stopped.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _trimmedPlaybackPosition = Duration.zero;
      _trimmedPlayerState = PlayerState.stopped;
    });
  }

  Future<void> _playTrimmedAudio(
    ToolFileEntity file,
  ) async {
    try {
      // Stop original player first.
      await _stopOriginalPlayback();

      if (_loadedTrimmedAudioPath != file.path) {
        await _trimmedPlayer.setSourceDeviceFile(
          file.path,
        );

        _loadedTrimmedAudioPath = file.path;

        final duration =
            await _trimmedPlayer.getDuration();

        if (mounted) {
          setState(() {
            _trimmedPlaybackDuration =
                duration ?? Duration.zero;
            _trimmedPlaybackPosition =
                Duration.zero;
          });
        }
      }

      await _trimmedPlayer.seek(Duration.zero);
      await _trimmedPlayer.resume();
    } catch (error) {
      _showMessage(
        'Unable to play trimmed audio: $error',
      );
    }
  }

  Future<void> _toggleTrimmedPlayback(
    ToolFileEntity file,
  ) async {
    if (_trimmedPlayerState == PlayerState.playing) {
      await _trimmedPlayer.pause();
      return;
    }

    await _playTrimmedAudio(file);
  }

  Future<void> _seekTrimmedPlayback(
    double milliseconds,
  ) async {
    await _trimmedPlayer.seek(
      Duration(
        milliseconds: milliseconds.round(),
      ),
    );
  }

  Future<void> _restartTrimmedAudio(
    ToolFileEntity file,
  ) async {
    try {
      await _stopOriginalPlayback();

      if (_loadedTrimmedAudioPath != file.path) {
        await _trimmedPlayer.setSourceDeviceFile(
          file.path,
        );

        _loadedTrimmedAudioPath = file.path;

        final duration =
            await _trimmedPlayer.getDuration();

        if (mounted) {
          setState(() {
            _trimmedPlaybackDuration =
                duration ?? Duration.zero;
            _trimmedPlaybackPosition =
                Duration.zero;
          });
        }
      }

      await _trimmedPlayer.seek(Duration.zero);
      await _trimmedPlayer.resume();
    } catch (error) {
      _showMessage(
        'Unable to restart audio: $error',
      );
    }
  }

  // ============================================================
  // SAVE / EXPORT
  // ============================================================

  Future<void> _saveToDevice(
    ToolFileEntity file,
  ) async {
    try {
      final sourceFile = File(file.path);

      if (!await sourceFile.exists()) {
        _showMessage(
          'The trimmed audio file is no longer available.',
        );
        return;
      }

      final bytes = await sourceFile.readAsBytes();

      final output = await FilePicker.saveFile(
        dialogTitle: 'Save trimmed audio',
        fileName: file.name,
        bytes: bytes,
        mimeType: file.mimeType ?? 'audio/mpeg',
        type: FileType.audio,
      );

      if (!mounted) {
        return;
      }

      if (output == null) {
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

  // ============================================================
  // COLLECTION
  // ============================================================

  Future<void> _addToCollection(
    ToolFileEntity file,
  ) async {
    final collectionsAsync =
        ref.read(collectionsProvider);

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
              for (final collection in collections)
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
      final now = DateTime.now();

      final updatedFile = ToolFileEntity(
        id: file.id,
        name: file.name,
        path: file.path,
        extension: file.extension,
        mimeType: file.mimeType,
        sizeBytes: file.sizeBytes,
        toolType: file.toolType,
        collectionId: collectionId,
        createdAt: file.createdAt,
        updatedAt: now,
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

  // ============================================================
  // HELPERS
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      audioTrimmerProvider,
    );

    ref.listen<AudioTrimmerState>(
      audioTrimmerProvider,
      (previous, next) {
        if (next.error != null &&
            next.error != previous?.error) {
          _showMessage(next.error!);
        }

        if (next.savedFile != null &&
            next.savedFile != previous?.savedFile) {
          // A newly generated result must not reuse the
          // previously loaded trimmed-player source.
          _loadedTrimmedAudioPath = null;

          _trimmedPlaybackPosition =
              Duration.zero;

          _trimmedPlaybackDuration =
              Duration.zero;

          _trimmedPlayerState =
              PlayerState.stopped;

          _showMessage(
            'Audio trimmed and saved successfully.',
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Audio Trimmer',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),
        children: [
          _FileSelectorCard(
            file: _selectedFile,
            onPick: _pickAudio,
          ),

          if (_selectedFile != null &&
              _duration > Duration.zero) ...[
            const SizedBox(
              height: AppSpacing.lg,
            ),

            _OriginalAudioCard(
              isPlaying:
                  _originalPlayerState ==
                      PlayerState.playing,
              position:
                  _originalPlaybackPosition,
              duration: _duration,
              onToggle:
                  _toggleSelectedAudio,
              onRestart:
                  _playSelectedAudio,
              formatDuration:
                  _formatDuration,
              onSeek:
                  _seekOriginalPlayback,
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            _TimelineCard(
              duration: _duration,
              start: _start,
              end: _end,
              onStartChanged: (value) {
                setState(() {
                  _start = value;
                });
              },
              onEndChanged: (value) {
                setState(() {
                  _end = value;
                });
              },
              formatDuration:
                  _formatDuration,
            ),

            const SizedBox(
              height: AppSpacing.lg,
            ),

            FilledButton.icon(
              onPressed:
                  state.isLoading
                      ? null
                      : _trim,
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
                      Icons.content_cut_rounded,
                    ),
              label: Text(
                state.isLoading
                    ? 'Trimming...'
                    : 'Trim Audio',
              ),
            ),
          ],

          if (state.savedFile != null) ...[
            const SizedBox(
              height: AppSpacing.lg,
            ),

            _ResultCard(
              file: state.savedFile!,

              isPlaying:
                  _trimmedPlayerState ==
                      PlayerState.playing,

              position:
                  _trimmedPlaybackPosition,

              duration:
                  _trimmedPlaybackDuration,

              onToggle: () {
                _toggleTrimmedPlayback(
                  state.savedFile!,
                );
              },

              onRestart: () {
                _restartTrimmedAudio(
                  state.savedFile!,
                );
              },

              onSeek:
                  _seekTrimmedPlayback,

              onSave: () {
                _saveToDevice(
                  state.savedFile!,
                );
              },

              onCollection: () {
                _addToCollection(
                  state.savedFile!,
                );
              },

              formatDuration:
                  _formatDuration,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// FILE SELECTOR
// ============================================================================

class _FileSelectorCard extends StatelessWidget {
  const _FileSelectorCard({
    required this.file,
    required this.onPick,
  });

  final File? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final fileName = file?.path
            .split(Platform.pathSeparator)
            .last ??
        'Choose an audio file';

    return Container(
      padding: const EdgeInsets.all(
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
      child: Column(
        children: [
          const Icon(
            Icons.audio_file_outlined,
            size: 52,
            color: AppColors.primaryLight,
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          Text(
            fileName,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(
              Icons.folder_open_outlined,
            ),
            label: Text(
              file == null
                  ? 'Select Audio'
                  : 'Change Audio',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ORIGINAL AUDIO CARD
// ============================================================================

class _OriginalAudioCard
    extends StatelessWidget {
  const _OriginalAudioCard({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onRestart,
    required this.onSeek,
    required this.formatDuration,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final VoidCallback onRestart;
  final ValueChanged<double> onSeek;
  final String Function(Duration)
      formatDuration;

  @override
  Widget build(BuildContext context) {
    final safePosition =
        position > duration
            ? duration
            : position;

    final maxMilliseconds =
        duration.inMilliseconds <= 0
            ? 1
            : duration.inMilliseconds;

    return Container(
      padding: const EdgeInsets.all(
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Original Audio',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          Slider(
            min: 0,
            max:
                maxMilliseconds.toDouble(),
            value: safePosition
                .inMilliseconds
                .clamp(
                  0,
                  maxMilliseconds,
                )
                .toDouble(),
            onChanged: onSeek,
          ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(
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
                formatDuration(duration),
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
            height: AppSpacing.sm,
          ),
          Row(
            children: [
              IconButton.filled(
                onPressed: onToggle,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              const SizedBox(
                width: AppSpacing.sm,
              ),
              OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(
                  Icons.replay_rounded,
                ),
                label: const Text(
                  'Play Selection',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TIMELINE
// ============================================================================

class _TimelineCard
    extends StatelessWidget {
  const _TimelineCard({
    required this.duration,
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.formatDuration,
  });

  final Duration duration;
  final Duration start;
  final Duration end;
  final ValueChanged<Duration>
      onStartChanged;
  final ValueChanged<Duration>
      onEndChanged;
  final String Function(Duration)
      formatDuration;

  @override
  Widget build(BuildContext context) {
    final maxMilliseconds =
        duration.inMilliseconds;

    if (maxMilliseconds <= 0) {
      return const SizedBox.shrink();
    }

    final safeStart = start
        .inMilliseconds
        .clamp(
          0,
          maxMilliseconds,
        )
        .toDouble();

    final safeEnd = end
        .inMilliseconds
        .clamp(
          0,
          maxMilliseconds,
        )
        .toDouble();

    final normalizedEnd =
        safeEnd < safeStart
            ? safeStart
            : safeEnd;

    return Container(
      padding: const EdgeInsets.all(
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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Trim Range',
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          RangeSlider(
            min: 0,
            max:
                maxMilliseconds.toDouble(),
            values: RangeValues(
              safeStart,
              normalizedEnd,
            ),
            onChanged: (values) {
              onStartChanged(
                Duration(
                  milliseconds:
                      values.start.round(),
                ),
              );

              onEndChanged(
                Duration(
                  milliseconds:
                      values.end.round(),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              _TimeValue(
                label: 'START',
                value:
                    formatDuration(start),
              ),
              _TimeValue(
                label: 'END',
                value:
                    formatDuration(end),
              ),
            ],
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          Text(
            'Selected: '
            '${formatDuration(end - start)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color:
                      AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TIME VALUE
// ============================================================================

class _TimeValue
    extends StatelessWidget {
  const _TimeValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(
                color:
                    AppColors.textMuted,
              ),
        ),
        const SizedBox(
          height: AppSpacing.xs,
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium,
        ),
      ],
    );
  }
}

// ============================================================================
// RESULT CARD
// ============================================================================

class _ResultCard
    extends StatelessWidget {
  const _ResultCard({
    required this.file,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onRestart,
    required this.onSeek,
    required this.onSave,
    required this.onCollection,
    required this.formatDuration,
  });

  final ToolFileEntity file;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final VoidCallback onRestart;
  final ValueChanged<double> onSeek;
  final VoidCallback onSave;
  final VoidCallback onCollection;
  final String Function(Duration)
      formatDuration;

  @override
  Widget build(BuildContext context) {
    final safePosition =
        position > duration
            ? duration
            : position;

    final maxMilliseconds =
        duration.inMilliseconds <= 0
            ? 1
            : duration.inMilliseconds;

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
                Icons.check_circle_outline_rounded,
                color:
                    AppColors.primaryLight,
              ),
              const SizedBox(
                width: AppSpacing.md,
              ),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: AppSpacing.md,
          ),
          Text(
            'Trimmed Audio',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color:
                      AppColors.textMuted,
                ),
          ),
          const SizedBox(
            height: AppSpacing.sm,
          ),
          Slider(
            min: 0,
            max:
                maxMilliseconds.toDouble(),
            value: safePosition
                .inMilliseconds
                .clamp(
                  0,
                  maxMilliseconds,
                )
                .toDouble(),
            onChanged:
                duration <= Duration.zero
                    ? null
                    : onSeek,
          ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(
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
                formatDuration(duration),
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
            height: AppSpacing.sm,
          ),
          Row(
            children: [
              IconButton.filled(
                onPressed: onToggle,
                icon: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
              const SizedBox(
                width: AppSpacing.sm,
              ),
              OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(
                  Icons.replay_rounded,
                ),
                label: const Text(
                  'Restart',
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
                  onPressed: onSave,
                  icon: const Icon(
                    Icons.download_outlined,
                  ),
                  label: const Text(
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
                      onCollection,
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
}