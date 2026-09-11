import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiCard extends StatelessWidget {
  const RikiCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.boxShadow = AppShadows.cardSoft,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow> boxShadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: boxShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
