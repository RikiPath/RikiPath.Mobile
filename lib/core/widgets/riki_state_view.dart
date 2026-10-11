import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';

/// A consistent, responsive presentation for a screen or section with no
/// content. Business/state decisions remain with the owning feature.
class RikiEmptyState extends StatelessWidget {
  const RikiEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.actionIcon,
    this.compact = false,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be supplied together.',
       );

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final IconData? actionIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RikiStateView(
      icon: icon,
      iconColor: AppColors.brandPrimary,
      iconBackgroundColor: AppColors.brandTint,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      actionKey: actionKey,
      actionIcon: actionIcon,
      compact: compact,
    );
  }
}

/// A consistent error presentation with a clear, non-destructive retry action.
class RikiErrorState extends StatelessWidget {
  const RikiErrorState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionKey,
    this.icon = Icons.cloud_off_outlined,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final Key? actionKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return RikiStateView(
      icon: icon,
      iconColor: AppColors.errorText,
      iconBackgroundColor: AppColors.errorBackground,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      actionKey: actionKey,
      compact: compact,
      actionIcon: Icons.refresh,
    );
  }
}

class RikiStateView extends StatelessWidget {
  const RikiStateView({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.actionIcon,
    this.compact = false,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be supplied together.',
       );

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final IconData? actionIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? AppSpacing.space4 : AppSpacing.space6;
    final iconExtent = compact ? 56.0 : 72.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Semantics(
          container: true,
          label: '$title. $message',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: iconExtent,
                  height: iconExtent,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: compact ? 27 : 32, color: iconColor),
                ),
              ),
              SizedBox(height: compact ? AppSpacing.space3 : AppSpacing.space4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(
                  height: compact ? AppSpacing.space4 : AppSpacing.space5,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 160,
                    maxWidth: 280,
                  ),
                  child: RikiSecondaryButton(
                    key: actionKey,
                    label: actionLabel!,
                    leadingIcon: actionIcon,
                    onPressed: onAction,
                  ),
                ),
              ],
            ],
          ),
        );

        if (!constraints.hasBoundedHeight) {
          return Padding(padding: EdgeInsets.all(padding), child: content);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - padding * 2).clamp(
                0,
                double.infinity,
              ),
            ),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
