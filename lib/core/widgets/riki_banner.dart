import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiInfoBanner extends StatelessWidget {
  const RikiInfoBanner({
    required this.message,
    this.title,
    this.icon = Icons.info_outline,
    super.key,
  });

  final String message;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _RikiBanner(
      title: title,
      message: message,
      icon: icon,
      foregroundColor: AppColors.info,
      backgroundColor: AppColors.infoBackground,
      borderColor: AppColors.infoBorder,
    );
  }
}

class RikiWarningBanner extends StatelessWidget {
  const RikiWarningBanner({
    required this.message,
    this.title,
    this.icon = Icons.lightbulb_outline,
    super.key,
  });

  final String message;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _RikiBanner(
      title: title,
      message: message,
      icon: icon,
      foregroundColor: AppColors.warningText,
      iconColor: AppColors.warning,
      backgroundColor: AppColors.warningBackground,
      borderColor: AppColors.warningBorder,
    );
  }
}

class RikiSuccessBanner extends StatelessWidget {
  const RikiSuccessBanner({
    required this.message,
    this.title,
    this.icon = Icons.check_circle_outline,
    super.key,
  });

  final String message;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _RikiBanner(
      title: title,
      message: message,
      icon: icon,
      foregroundColor: AppColors.success,
      backgroundColor: AppColors.successBackground,
      borderColor: AppColors.successBorder,
    );
  }
}

class RikiErrorBanner extends StatelessWidget {
  const RikiErrorBanner({
    required this.message,
    this.title,
    this.icon = Icons.error_outline,
    super.key,
  });

  final String message;
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _RikiBanner(
      title: title,
      message: message,
      icon: icon,
      foregroundColor: AppColors.errorText,
      backgroundColor: AppColors.errorBackground,
      borderColor: AppColors.brandBorder,
    );
  }
}

class _RikiBanner extends StatelessWidget {
  const _RikiBanner({
    required this.message,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.borderColor,
    this.title,
    Color? iconColor,
  }) : iconColor = iconColor ?? foregroundColor;

  final String? title;
  final String message;
  final IconData icon;
  final Color foregroundColor;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final semanticText = title == null ? message : '$title. $message';

    return Semantics(
      container: true,
      label: semanticText,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.banner),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: AppTypography.cardTitle.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                  ],
                  Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: foregroundColor,
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
