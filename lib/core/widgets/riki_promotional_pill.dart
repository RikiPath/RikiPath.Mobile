import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiPromotionalPill extends StatelessWidget {
  const RikiPromotionalPill({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        border: Border.all(color: AppColors.brandBorder),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: AppSpacing.space1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('✨', style: AppTypography.metadata),
          Text(
            message,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
