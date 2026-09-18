import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class LanguageBadge extends StatelessWidget {
  const LanguageBadge({this.languageCode = 'VI', this.onPressed, super.key});

  final String languageCode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onPressed != null,
      label: 'Ngôn ngữ $languageCode',
      child: Material(
        color: AppColors.surface,
        shape: const StadiumBorder(side: AppBorders.standard),
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.language,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    languageCode,
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.textBody,
                    ),
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
