import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/sakura_motifs.dart';

/// Full-width Neo-Japoniste Sakura Hero Banner delivering daily encouragement
/// with airy, premium typography, delicate blossom badge, and soft floating petals.
class SakuraMotivationBanner extends StatelessWidget {
  const SakuraMotivationBanner({
    this.title = 'Học mỗi ngày',
    this.subtitle = 'Mỗi ngày một chút, chạm mục tiêu JLPT.',
    this.japaneseCheer = 'がんばろう！',
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String japaneseCheer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWarmWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cardBorderSubtle,
          width: 1,
        ),
        boxShadow: AppShadows.sakuraSubtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned(
              right: -6,
              top: -6,
              bottom: -6,
              child: SakuraDecorativeCorner(
                width: 130,
                height: 96,
                opacity: 0.28,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brandTint,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.borderSubtlePink,
                            width: 1,
                          ),
                        ),
                        child: const SakuraBlossomMark(size: 24),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.cardTitle.copyWith(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.learnerTextPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.space2),
                                Container(
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
                                    japaneseCheer,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: AppColors.brandPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.learnerTextSecondary,
                                fontSize: 12,
                                height: 1.35,
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
