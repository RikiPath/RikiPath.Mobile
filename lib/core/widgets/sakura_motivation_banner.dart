import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/sakura_motifs.dart';

/// A friendly Sakura encouragement banner matching the showcase style.
class SakuraMotivationBanner extends StatelessWidget {
  const SakuraMotivationBanner({
    this.title = 'Học mỗi ngày',
    this.subtitle = 'Tiến bộ hơn mỗi ngày! がんばろう! 🌸',
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
        gradient: AppColors.sakuraHeroGradient,
        borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
        border: Border.all(color: AppColors.borderSubtlePink, width: 1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0DE05A7A),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
        child: Stack(
          children: [
            const Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: SakuraDecorativeCorner(width: 120, height: 90, opacity: 0.35),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3 + 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x10E05A7A),
                          offset: Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const SakuraBlossomMark(size: 26),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.motivationalTitle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                japaneseCheer,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: AppColors.brandPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.motivationalBody,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
