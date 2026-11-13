import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Sakura Library Hero Banner for RikiPath Mobile.
///
/// Designed in accordance with the Sakura Design System and PO directive:
/// - Full-width layout matching the Practice Hero Banner
/// - Responsive compact 3:1 aspect ratio (~120dp on 360dp, ~137dp on 412dp)
/// - Zero border radius, zero outer margin, no card wrapper or heavy shadow
/// - Preserves the adorable 3D anime chibi fox mascot reading a book on the left
/// - Clear right text-safe zone with localized/harmonized typography
class SakuraLibraryHeroBanner extends StatelessWidget {
  const SakuraLibraryHeroBanner({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  static const String assetPath =
      'assets/images/learning/sakura_library_hero.png';

  @override
  Widget build(BuildContext context) {
    const titleText = 'Khám phá kho kiến thức Nhật Bản';
    const subtitleText = 'Mỗi bài học, một bước tiến mới.';
    const badgeText = 'ライブラリ';

    return Semantics(
      container: true,
      button: onTap != null,
      label: '$badgeText. $titleText. $subtitleText',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.brandPrimary.withValues(alpha: 0.12),
          highlightColor: AppColors.brandPrimary.withValues(alpha: 0.06),
          child: AspectRatio(
            // Responsive 3:1 aspect ratio (2172 x 724 px) matching Practice Banner
            aspectRatio: 2172 / 724,
            child: SizedBox(
              key: const ValueKey('learning_library_hero_banner'),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.25),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: Illustrated 3D Chibi Fox Mascot & Sakura Library Artwork
                    Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, _, _) => const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.sakuraHeroGradient,
                        ),
                      ),
                    ),

                    // Layer 2: Subtle soft gradient on the right side for legibility
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: const [0.0, 0.38, 0.68, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.30),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Layer 3: Localized Text Overlay (Right-aligned, never overlapping mascot)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final leftOffset =
                            (constraints.maxWidth * 0.44).clamp(155.0, 210.0);
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            leftOffset,
                            6,
                            AppSpacing.space4,
                            6,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Japanese Tag Pill matching Practice Hero Banner
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEEF1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFFFD1DC),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    badgeText,
                                    style: TextStyle(
                                      color: AppColors.brandPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),

                                // Banner Title
                                Text(
                                  titleText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: constraints.maxWidth < 380
                                        ? 13.5
                                        : 15.0,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2C1E20),
                                    letterSpacing: -0.2,
                                    height: 1.18,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Banner Subtitle
                                Text(
                                  subtitleText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: constraints.maxWidth < 380
                                        ? 10.5
                                        : 11.5,
                                    color: const Color(0xFF5A3E42),
                                    height: 1.22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
