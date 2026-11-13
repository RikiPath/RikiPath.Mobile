import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

/// Sakura Practice Hero Banner for RikiPath Mobile.
///
/// Designed in accordance with the Sakura Design System and PO directive:
/// - Full-width edge-to-edge layout matching the Home Time Banner
/// - Responsive compact 3:1 aspect ratio (~120dp on 360dp, ~137dp on 412dp)
/// - Zero border radius, zero outer margin, no card wrapper or heavy shadow
/// - Preserves the adorable 3D anime chibi fox mascot on the left
/// - Localized motivational copy & Japanese badge pill on the right
class PracticeHeroBanner extends StatelessWidget {
  const PracticeHeroBanner({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  static const String assetWebp =
      'assets/images/practice/practice_hero_banner.webp';
  static const String assetPng =
      'assets/images/practice/practice_hero_banner.png';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      container: true,
      button: onTap != null,
      label:
          '${l10n.practiceHeroBadge}. ${l10n.practiceHeroTitle}. ${l10n.practiceHeroSubtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.brandPrimary.withValues(alpha: 0.12),
          highlightColor: AppColors.brandPrimary.withValues(alpha: 0.06),
          child: AspectRatio(
            // Responsive 3:1 aspect ratio (2048 x 682 px) matching Home Time Banners
            aspectRatio: 2048 / 682,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.25),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Illustrated 3D Chibi Fox Mascot & Sakura Artwork
                  Image.asset(
                    assetWebp,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        assetPng,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.sakuraHeroGradient,
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Layer 2: Subtle soft gradient on the right side for legibility
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: const [0.0, 0.36, 0.65, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Layer 3: Localized Text Overlay (Right-aligned, never overlapping mascot)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final leftOffset =
                          (constraints.maxWidth * 0.38).clamp(130.0, 185.0);
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
                              // Japanese Motivational Tag Pill
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
                                child: Text(
                                  l10n.practiceHeroBadge,
                                  style: const TextStyle(
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
                                l10n.practiceHeroTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: constraints.maxWidth < 380
                                      ? 14.0
                                      : 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2C1E20),
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Banner Subtitle
                              Text(
                                l10n.practiceHeroSubtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: constraints.maxWidth < 380
                                      ? 10.5
                                      : 11.5,
                                  color: const Color(0xFF5A3E42),
                                  height: 1.25,
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
    );
  }
}
