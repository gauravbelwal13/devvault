import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/theme/app_spacing.dart';

class VoiceEffectCard extends StatelessWidget {
  const VoiceEffectCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? color
        : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? effectiveColor.withValues(
                    alpha: 0.12,
                  )
                : AppColors.surface,
            borderRadius: BorderRadius.circular(
              AppRadius.card,
            ),
            border: Border.all(
              color: selected
                  ? effectiveColor.withValues(
                      alpha: 0.75,
                    )
                  : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: effectiveColor
                          .withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(
                    alpha: selected
                        ? 0.18
                        : 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: effectiveColor,
                  size: 23,
                ),
              ),

              const SizedBox(
                height: AppSpacing.sm,
              ),

              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
              ),

              if (selected) ...[
                const SizedBox(
                  height: 5,
                ),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}