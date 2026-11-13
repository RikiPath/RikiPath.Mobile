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
    const accent = AppColors.brandPrimary;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      icon: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0F4), Color(0xFFFFE5EB)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF8BBD0).withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1CE05A7A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: accent, size: 28),
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
        OutlinedButton(
          key: cancelKey,
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color(0xFFFFF7F9),
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: Color(0xFFEBDDE1), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppColors.brandShadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
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
