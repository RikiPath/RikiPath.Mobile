import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/sakura_mascot.dart';
import 'package:rikipath_mobile/core/widgets/sakura_motifs.dart';

/// An educational guidance banner delivering actionable pedagogical tips
/// across Home, Roadmap, Kana, Grammar, and Notebook.
class SakuraEducationalBanner extends StatelessWidget {
  const SakuraEducationalBanner({
    required this.tag,
    required this.title,
    required this.message,
    this.mascotPose = SakuraMascotPose.guiding,
    this.onTap,
    this.onDismiss,
    this.compact = false,
    super.key,
  });

  /// Category tag, e.g. "Mẹo học tập", "Bí quyết JLPT", "Quy tắc nét", "SRS".
  final String tag;

  /// Concise header describing the tip.
  final String title;

  /// High-value educational advice.
  final String message;

  /// Mascot pose to reinforce pedagogical guidance.
  final SakuraMascotPose mascotPose;

  /// Optional action tap.
  final VoidCallback? onTap;

  /// Optional dismiss callback.
  final VoidCallback? onDismiss;

  /// If true, renders with a more compact padding for dense screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWarmWhite,
        borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
        border: Border.all(color: AppColors.borderSubtlePink, width: 1.2),
        boxShadow: AppShadows.sakuraSubtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
        child: Stack(
          children: [
            const Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SakuraDecorativeCorner(
                width: 90,
                height: 80,
                opacity: 0.22,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
                child: Padding(
                  padding: EdgeInsets.all(
                    compact ? AppSpacing.space3 : AppSpacing.space4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Riki-chan Mascot in educational guiding / study pose
                      Container(
                        width: compact ? 42 : 48,
                        height: compact ? 42 : 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.sakuraHeroGradient,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(
                            color: AppColors.borderSubtlePink,
                            width: 1,
                          ),
                        ),
                        child: SakuraMascot(
                          pose: mascotPose,
                          size: compact ? 36 : 42,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandTint,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: AppColors.brandBorder,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.brandPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                                if (onDismiss != null) ...[
                                  const Spacer(),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: onDismiss,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              title,
                              style: AppTypography.motivationalTitle.copyWith(
                                fontSize: compact ? 13 : 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              style: AppTypography.metadata.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: compact ? 11 : 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
