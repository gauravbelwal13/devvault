import 'dart:io';

import 'package:flutter/material.dart';

import 'package:devvault/features/developer_tools/data/services/local_image_model_service.dart';

import '../../data/services/local_image_generation_service.dart';

enum ImageGenerationQuality {
  fast,
  standard,
  quality,
}

class LocalImageGeneratorScreen extends StatefulWidget {
  const LocalImageGeneratorScreen({super.key});

  @override
  State<LocalImageGeneratorScreen> createState() =>
      _LocalImageGeneratorScreenState();
}

class _LocalImageGeneratorScreenState
    extends State<LocalImageGeneratorScreen> {
  final LocalImageGenerationService _service =
      LocalImageGenerationService();

  final TextEditingController _promptController =
      TextEditingController();

  final TextEditingController _negativePromptController =
      TextEditingController();

  bool _initializing = false;
  bool _generating = false;
  bool _initialized = false;

  String _status = 'Model not initialized';

  File? _generatedImage;

  ImageGenerationQuality _quality =
      ImageGenerationQuality.fast;

  // ------------------------------------------------------------
  // Generation presets
  // ------------------------------------------------------------

  int get _width {
    switch (_quality) {
      case ImageGenerationQuality.fast:
        return 256;

      case ImageGenerationQuality.standard:
        return 384;

      case ImageGenerationQuality.quality:
        return 512;
    }
  }

  int get _height {
    switch (_quality) {
      case ImageGenerationQuality.fast:
        return 256;

      case ImageGenerationQuality.standard:
        return 384;

      case ImageGenerationQuality.quality:
        return 512;
    }
  }

  int get _steps {
    switch (_quality) {
      case ImageGenerationQuality.fast:
        return 5;

      case ImageGenerationQuality.standard:
        return 15;

      case ImageGenerationQuality.quality:
        return 25;
    }
  }

  String get _qualityTitle {
    switch (_quality) {
      case ImageGenerationQuality.fast:
        return 'Fast';

      case ImageGenerationQuality.standard:
        return 'Standard';

      case ImageGenerationQuality.quality:
        return 'Quality';
    }
  }

  String get _qualityDescription {
    switch (_quality) {
      case ImageGenerationQuality.fast:
        return 'Quick preview • 256×256 • 5 steps';

      case ImageGenerationQuality.standard:
        return 'Balanced quality • 384×384 • 15 steps';

      case ImageGenerationQuality.quality:
        return 'Best quality • 512×512 • 25 steps';
    }
  }

  // ------------------------------------------------------------
  // Initialize model
  // ------------------------------------------------------------

  Future<void> _initializeModel() async {
    if (_initializing || _initialized) {
      return;
    }

    setState(() {
      _initializing = true;
      _status = 'Checking model...';
    });

    try {
      const modelService = LocalImageModelService();

      final installed =
          await modelService.isModelInstalled();

      if (!installed) {
        throw Exception(
          'Stable Diffusion model is not installed.',
        );
      }

      final modelPath =
          await modelService.getModelPath();

      if (!mounted) return;

      setState(() {
        _status = 'Loading Stable Diffusion...';
      });

      await _service.initialize(
        modelPath: modelPath,
      );

      if (!mounted) return;

      setState(() {
        _initialized = true;
        _status = 'Model ready';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _initialized = false;
        _status = 'Initialization failed: $error';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _initializing = false;
      });
    }
  }

  // ------------------------------------------------------------
  // Generate image
  // ------------------------------------------------------------

  Future<void> _generateImage() async {
    final prompt =
        _promptController.text.trim();

    if (prompt.isEmpty) {
      setState(() {
        _status = 'Enter a prompt first.';
      });

      return;
    }

    if (!_initialized) {
      setState(() {
        _status =
            'Initialize the model first.';
      });

      return;
    }

    setState(() {
      _generating = true;
      _generatedImage = null;
      _status =
          'Generating $_qualityTitle image...';
    });

    try {
      final image =
          await _service.generate(
        prompt: prompt,
        negativePrompt:
            _negativePromptController.text.trim(),

        width: _width,
        height: _height,
        steps: _steps,

        // Keep the same seed while testing.
        // Change to -1 later for random generation.
        seed: 42,
      );

      if (!mounted) return;

      setState(() {
        _generatedImage = image;
        _status =
            'Generation complete • $_qualityTitle';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _status =
            'Generation failed: $error';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _generating = false;
      });
    }
  }

  // ------------------------------------------------------------
  // Dispose
  // ------------------------------------------------------------

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();

    _service.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Image Generator',
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              // ------------------------------------------------
              // Image preview
              // ------------------------------------------------

              Container(
                height: 300,

                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(20),

                  color: colors
                      .surfaceContainerHighest,
                ),

                clipBehavior:
                    Clip.antiAlias,

                child: _generatedImage != null
                    ? Image.file(
                        _generatedImage!,
                        fit: BoxFit.contain,
                      )
                    : Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          Icon(
                            Icons
                                .image_outlined,
                            size: 64,
                            color:
                                colors.onSurfaceVariant,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            'Your generated image',
                            style: theme
                                .textTheme
                                .bodyMedium,
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // Prompt
              // ------------------------------------------------

              TextField(
                controller:
                    _promptController,

                maxLines: 4,

                enabled: !_generating,

                textInputAction:
                    TextInputAction.newline,

                decoration:
                    const InputDecoration(
                  labelText: 'Prompt',

                  hintText:
                      'A futuristic city at sunset...',

                  border:
                      OutlineInputBorder(),

                  alignLabelWithHint: true,

                  prefixIcon: Padding(
                    padding:
                        EdgeInsets.only(
                      bottom: 55,
                    ),

                    child: Icon(
                      Icons
                          .edit_note_rounded,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // Negative prompt
              // ------------------------------------------------

              TextField(
                controller:
                    _negativePromptController,

                maxLines: 2,

                enabled: !_generating,

                decoration:
                    const InputDecoration(
                  labelText:
                      'Negative prompt',

                  hintText:
                      'blurry, low quality, distorted',

                  border:
                      OutlineInputBorder(),

                  alignLabelWithHint: true,

                  prefixIcon:
                      Icon(Icons.block_rounded),
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // Quality selector
              // ------------------------------------------------

              Text(
                'Generation Quality',
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 10),

              SegmentedButton<
                  ImageGenerationQuality>(
                segments: const [
                  ButtonSegment<
                      ImageGenerationQuality>(
                    value:
                        ImageGenerationQuality
                            .fast,

                    icon: Icon(
                      Icons.bolt_rounded,
                    ),

                    label:
                        Text('Fast'),
                  ),

                  ButtonSegment<
                      ImageGenerationQuality>(
                    value:
                        ImageGenerationQuality
                            .standard,

                    icon: Icon(
                      Icons
                          .balance_rounded,
                    ),

                    label:
                        Text('Standard'),
                  ),

                  ButtonSegment<
                      ImageGenerationQuality>(
                    value:
                        ImageGenerationQuality
                            .quality,

                    icon: Icon(
                      Icons
                          .auto_awesome_rounded,
                    ),

                    label:
                        Text('Quality'),
                  ),
                ],

                selected: {
                  _quality,
                },

                onSelectionChanged:
                    _generating
                        ? null
                        : (selection) {
                            setState(() {
                              _quality =
                                  selection.first;
                            });
                          },
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // Preset information
              // ------------------------------------------------

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      colors.surfaceContainerHighest,

                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons
                          .tune_rounded,
                      size: 20,
                      color:
                          colors.primary,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        _qualityDescription,
                        style: theme
                            .textTheme
                            .bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // Status
              // ------------------------------------------------

              AnimatedSwitcher(
                duration:
                    const Duration(
                  milliseconds: 200,
                ),

                child: Text(
                  _status,
                  key: ValueKey(_status),

                  textAlign:
                      TextAlign.center,

                  style: theme
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color:
                            colors.onSurfaceVariant,
                      ),
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // Initialize button
              // ------------------------------------------------

              if (!_initialized)
                FilledButton.icon(
                  onPressed:
                      _initializing
                          ? null
                          : _initializeModel,

                  icon: _initializing
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
                              .memory_rounded,
                        ),

                  label: Text(
                    _initializing
                        ? 'Loading Model...'
                        : 'Initialize Model',
                  ),
                ),

              // ------------------------------------------------
              // Generate button
              // ------------------------------------------------

              if (_initialized)
                SizedBox(
                  height: 52,

                  child:
                      FilledButton.icon(
                    onPressed:
                        _generating
                            ? null
                            : _generateImage,

                    icon: _generating
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
                                .auto_awesome_rounded,
                          ),

                    label: Text(
                      _generating
                          ? 'Generating...'
                          : 'Generate Image',
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // Current configuration
              // ------------------------------------------------

              if (_initialized)
                Text(
                  'Local • $_width×$_height • $_steps steps',
                  textAlign:
                      TextAlign.center,

                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color:
                            colors.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}