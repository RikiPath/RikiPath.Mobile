import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiConfirmationDialog extends StatelessWidget {
  const RikiConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.icon = Icons.help_outline,
    this.destructive = false,
    this.confirmKey,
    this.cancelKey,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool destructive;
  final Key? confirmKey;
  final Key? cancelKey;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.brandPrimary;
    final background = destructive
        ? AppColors.errorBackground
        : AppColors.brandTint;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      icon: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: accent, size: 26),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTypography.sectionTitle,
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall,
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          key: cancelKey,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

Future<bool> showRikiConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  IconData icon = Icons.help_outline,
  bool destructive = false,
  Key? confirmKey,
  Key? cancelKey,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => RikiConfirmationDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          icon: icon,
          destructive: destructive,
          confirmKey: confirmKey,
          cancelKey: cancelKey,
        ),
      ) ??
      false;
}
