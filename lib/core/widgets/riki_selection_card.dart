import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiSelectionCard extends StatelessWidget {
  const RikiSelectionCard({
    required this.title,
    required this.description,
    required this.leading,
    required this.selected,
    required this.onPressed,
    this.badge,
    super.key,
  });

  final String title;
  final String description;
  final Widget leading;
  final bool selected;
  final VoidCallback? onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: selected ? AppColors.brandPrimary : AppColors.border,
      width: selected ? AppBorders.emphasized : AppBorders.thin,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: borderSide,
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow:
              selected ? AppShadows.selectedCard : AppShadows.cardSoft,
        ),
        child: Material(
          color: selected ? AppColors.brandSelectedTint : AppColors.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: shape,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: AppSpacing.space1,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              title,
                              style: selected
                                  ? AppTypography.sectionTitle
                                  : AppTypography.sectionTitle.copyWith(
                                      color: AppColors.textBody,
                                      fontWeight: FontWeight.w600,
                                    ),
                            ),
                            if (badge != null) _SelectionBadge(label: badge!),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          description,
                          style: AppTypography.metadata.copyWith(
                            color: selected
                                ? AppColors.textSecondary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  _SelectionIndicator(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.micro),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(
          color: AppColors.brandPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? AppColors.brandPrimary : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.brandPrimary : AppColors.borderStrong,
          width: AppBorders.emphasized,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
