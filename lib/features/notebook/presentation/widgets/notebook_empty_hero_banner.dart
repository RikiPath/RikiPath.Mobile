import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

/// Sakura Empty-State Hero Banner for Notebook Home.
///
/// Displayed ONLY when the user has 0 collections after successful load.
///
/// Visual Specifications:
/// - Full-width edge-to-edge layout matching the Practice and Library banners
/// - Responsive compact 3:1 aspect ratio (2048 x 682 px)
/// - Zero border radius, zero outer margin, no card wrapper or heavy shadow
/// - Flush against top app bar when mounted at the top of the scroll container
/// - Adorable 3D chibi fox mascot (Riki-chan) on the left holding Japanese notebook & pen
/// - Clean pastel pink-cream gradient on the right with sakura cherry blossom branch
/// - Localized badge pill, title, and description rendered via Flutter
class SakuraNotebookEmptyBanner extends StatelessWidget {
  const SakuraNotebookEmptyBanner({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  static const String assetWebp =
      'assets/images/notebook/notebook_empty_hero_banner.webp';
  static const String assetPng =
      'assets/images/notebook/notebook_empty_hero_banner.png';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      container: true,
      button: onTap != null,
      label:
          '${l10n.notebookEmptyHeroBadge}. ${l10n.notebookEmptyHeroTitle}. ${l10n.notebookEmptyHeroDescription}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.brandPrimary.withValues(alpha: 0.12),
          highlightColor: AppColors.brandPrimary.withValues(alpha: 0.06),
          child: AspectRatio(
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

                      // Layer 2: Subtle soft gradient on the right side for text legibility
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: const [0.0, 0.34, 0.65, 1.0],
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

                      // Layer 3: Localized Text Overlay
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final leftOffset =
                              (constraints.maxWidth * 0.36).clamp(120.0, 175.0);
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
                                  // Motivational Tag Pill
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
                                      l10n.notebookEmptyHeroBadge,
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
                                    l10n.notebookEmptyHeroTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.cardTitle.copyWith(
                                      fontSize: constraints.maxWidth < 380
                                          ? 13.5
                                          : 15.0,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2C1E20),
                                      letterSpacing: -0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),

                                  // Banner Subtitle
                                  Text(
                                    l10n.notebookEmptyHeroDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: constraints.maxWidth < 380
                                          ? 10.0
                                          : 11.0,
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
