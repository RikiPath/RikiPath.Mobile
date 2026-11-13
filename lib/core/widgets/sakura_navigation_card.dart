import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_card.dart';
import 'package:rikipath_mobile/core/widgets/sakura_3d_icon.dart';

/// Sakura Premium Navigation Card System component.
///
/// Unifies all screen navigation action cards (SRS Review, Practice, Meeting,
/// Notebook) into a consistent interactive pattern:
/// `[3D Icon] [Title + Short Description] [Chevron Right]`.
///
/// Features:
/// - Fully tappable card with interactive press feedback and reduced-motion support.
/// - Unaltered original 3D icon rendering with studio lighting.
/// - Adaptive layout supporting 1-2 line titles and descriptions without overflow.
/// - Optional contextual badge (e.g., active session resume indicator).
/// - Consistent neutral chevron and subtle Sakura card border/shadow styling.
class SakuraNavigationCard extends StatelessWidget {
  const SakuraNavigationCard({
    required this.title,
    required this.description,
    required this.onTap,
    this.icon3d,
    this.fallbackIcon = Icons.arrow_forward_rounded,
    this.badge,
    this.trailing,
    this.enabled = true,
    this.semanticLabel,
    this.iconExtent = 44.0,
    super.key,
  });

  final String title;
  final String description;
  final VoidCallback? onTap;
  final Sakura3DIconType? icon3d;
  final IconData fallbackIcon;
  final Widget? badge;
  final Widget? trailing;
  final bool enabled;
  final String? semanticLabel;
  final double iconExtent;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onTap != null;

    final leading = icon3d != null
        ? Sakura3DIcon(
            type: icon3d!,
            size: iconExtent,
            fallbackColor: AppColors.brandPrimary,
          )
        : Icon(
            fallbackIcon,
            size: iconExtent * 0.65,
            color: AppColors.brandPrimary,
          );

    final titleRow = Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: AppSpacing.space2),
          badge!,
        ],
      ],
    );

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleRow,
        const SizedBox(height: 3),
        Text(
          description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
      ],
    );

    final chevron = trailing ??
        const Icon(
          Icons.chevron_right_rounded,
          size: 24,
          color: AppColors.textTertiary,
        );

    return Semantics(
      button: true,
      enabled: effectiveEnabled,
      label: semanticLabel ?? '$title, $description',
      child: RikiCard(
        backgroundColor: AppColors.cardWarmWhite,
        borderColor: AppColors.cardBorderSubtle,
        boxShadow: AppShadows.cardSoft,
        borderRadius: AppRadius.cardLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        onTap: effectiveEnabled ? onTap : null,
        child: Opacity(
          opacity: effectiveEnabled ? 1.0 : 0.6,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: AppSpacing.space3),
              Expanded(child: textColumn),
              const SizedBox(width: AppSpacing.space2),
              chevron,
            ],
          ),
        ),
      ),
    );
  }
}
