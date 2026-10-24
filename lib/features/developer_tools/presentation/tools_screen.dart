import 'package:devvault/features/developer_tools/presentation/screens/local_image_generator_screen.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';

import 'screens/audio_trimmer_screen.dart';
import 'screens/image_compression_screen.dart';
import 'screens/image_converter_screen.dart';
import 'screens/image_cropper_screen.dart';
import 'screens/image_resize_screen.dart';
import 'screens/media_pdf_screen.dart';
import 'screens/video_trimmer_screen.dart';
import 'screens/voice_studio_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static const int _totalTools = 9;

  void _openTool(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Developer Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          120,
        ),
        children: [
          // ============================================================
          // HEADER
          // ============================================================

          const _ToolsHeader(
            totalTools: _totalTools,
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          // ============================================================
          // LOCAL AI
          // ============================================================

          const _SectionIntro(
            icon: Icons.auto_awesome_rounded,
            title: 'Local AI',
            description:
                'Private AI tools running directly on your device.',
            accentColor: Color(0xFF9C6CFF),
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _AiToolCard(
            icon: Icons.mic_rounded,
            title: 'Voice Studio',
            description:
                'Record, transform and apply voice effects locally.',
            accentColor: const Color(0xFF8B5CF6),
            badge: 'OFFLINE',
            onTap: () {
              _openTool(
                context,
                const VoiceStudioScreen(),
              );
            },
          ),

          const SizedBox(
            height: AppSpacing.sm,
          ),

          _AiToolCard(
  icon: Icons.auto_awesome_rounded,
  title: 'AI Image Generator',
  description:
      'Generate images from text using a local AI model.',
  accentColor: const Color(0xFF10B981),
  badge: 'LOCAL',
  onTap: () {
    _openTool(
      context,
      const LocalImageGeneratorScreen(),
    );
  },
),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          // ============================================================
          // IMAGE TOOLS
          // ============================================================

          const _ToolSection(
            title: 'Image',
            icon: Icons.image_outlined,
            children: [],
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _ToolCard(
            icon: Icons.photo_size_select_large_outlined,
            title: 'Image Resize',
            description:
                'Resize images while maintaining their aspect ratio.',
            onTap: () {
              _openTool(
                context,
                const ImageResizeScreen(),
              );
            },
          ),

          _ToolCard(
            icon: Icons.compress_outlined,
            title: 'Image Compression',
            description:
                'Reduce image file size while keeping good quality.',
            onTap: () {
              _openTool(
                context,
                const ImageCompressionScreen(),
              );
            },
          ),

          _ToolCard(
            icon: Icons.transform_outlined,
            title: 'Image Converter',
            description:
                'Convert images between JPG, PNG and WebP formats.',
            onTap: () {
              _openTool(
                context,
                const ImageConverterScreen(),
              );
            },
          ),

          _ToolCard(
            icon: Icons.crop_outlined,
            title: 'Image Cropper',
            description:
                'Crop images using custom dimensions or aspect ratios.',
            onTap: () {
              _openTool(
                context,
                const ImageCropperScreen(),
              );
            },
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          // ============================================================
          // VIDEO TOOLS
          // ============================================================

          const _ToolSection(
            title: 'Video',
            icon: Icons.video_library_outlined,
            children: [],
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _ToolCard(
            icon: Icons.content_cut_outlined,
            title: 'Video Trimmer',
            description:
                'Trim a video by selecting a start and end position.',
            onTap: () {
              _openTool(
                context,
                const VideoTrimmerScreen(),
              );
            },
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          // ============================================================
          // AUDIO TOOLS
          // ============================================================

          const _ToolSection(
            title: 'Audio',
            icon: Icons.audiotrack_outlined,
            children: [],
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _ToolCard(
            icon: Icons.content_cut_outlined,
            title: 'Audio Trimmer',
            description:
                'Trim an audio file and keep only the required segment.',
            onTap: () {
              _openTool(
                context,
                const AudioTrimmerScreen(),
              );
            },
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          // ============================================================
          // DOCUMENT TOOLS
          // ============================================================

          const _ToolSection(
            title: 'Documents',
            icon: Icons.description_outlined,
            children: [],
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _ToolCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Media → PDF',
            description:
                'Convert one or multiple images into a PDF document.',
            onTap: () {
              _openTool(
                context,
                const MediaPdfScreen(),
              );
            },
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          // ============================================================
          // FUTURE LOCAL AI ARCHITECTURE
          // ============================================================

          const _LocalAiInfoCard(),
        ],
      ),
    );
  }
}

// ============================================================================
// TOOLS HEADER
// ============================================================================

class _ToolsHeader extends StatelessWidget {
  const _ToolsHeader({
    required this.totalTools,
  });

  final int totalTools;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(
              alpha: 0.18,
            ),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(
                AppRadius.md,
              ),
            ),
            child: const Icon(
              Icons.build_rounded,
              color: AppColors.primaryLight,
              size: 27,
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
                  'Developer Toolkit',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
                const SizedBox(
                  height: AppSpacing.xs,
                ),
                Text(
                  '$totalTools tools available locally',
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
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                AppRadius.chip,
              ),
            ),
            child: const Text(
              'LOCAL',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION INTRO
// ============================================================================

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(
              alpha: 0.12,
            ),
            borderRadius:
                BorderRadius.circular(
              AppRadius.md,
            ),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 21,
          ),
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
                height: 3,
              ),
              Text(
                description,
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
        ),
      ],
    );
  }
}

// ============================================================================
// AI TOOL CARD
// ============================================================================

class _AiToolCard extends StatelessWidget {
  const _AiToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        AppRadius.xl,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppRadius.xl,
        ),
        child: Ink(
          padding: const EdgeInsets.all(
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(
                  alpha: 0.16,
                ),
                AppColors.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(
              AppRadius.xl,
            ),
            border: Border.all(
              color: accentColor.withValues(
                alpha: 0.20,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 28,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                          ),
                        ),

                        const SizedBox(
                          width: AppSpacing.sm,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                AppSpacing.xs,
                            vertical: 3,
                          ),
                          decoration:
                              BoxDecoration(
                            color: accentColor
                                .withValues(
                              alpha: 0.12,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              AppRadius.chip,
                            ),
                          ),
                          child: Text(
                            badge,
                            style:
                                TextStyle(
                              color:
                                  accentColor,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: AppSpacing.xs,
                    ),

                    Text(
                      description,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors
                                .textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: AppSpacing.sm,
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EXISTING TOOL SECTION
// ============================================================================

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.md,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.primaryLight,
              ),
            ),

            const SizedBox(
              width: AppSpacing.sm,
            ),

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
          ],
        ),

        if (children.isNotEmpty) ...[
          const SizedBox(
            height: AppSpacing.md,
          ),
          ...children,
        ],
      ],
    );
  }
}

// ============================================================================
// EXISTING TOOL CARD
// ============================================================================

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.sm,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.lg,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            AppRadius.lg,
          ),
          child: Container(
            padding: const EdgeInsets.all(
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.md,
                    ),
                  ),
                  child: Icon(
                    icon,
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
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                      ),

                      const SizedBox(
                        height: AppSpacing.xs,
                      ),

                      Text(
                        description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: AppColors
                                  .textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: AppSpacing.sm,
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOCAL AI ARCHITECTURE CARD
// ============================================================================

class _LocalAiInfoCard extends StatelessWidget {
  const _LocalAiInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.lg,
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
            Icons.security_rounded,
            color: AppColors.success,
            size: 22,
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
                  'Private by design',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),

                const SizedBox(
                  height: AppSpacing.xs,
                ),

                Text(
                  'Local AI processing is designed to keep '
                  'your media on the device. Model management '
                  'will be added without changing the existing '
                  'developer-tool architecture.',
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
          ),
        ],
      ),
    );
  }
}