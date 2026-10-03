import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiProgressIndicator extends StatelessWidget {
  const RikiProgressIndicator({
    this.value,
    this.semanticsLabel,
    this.minHeight = AppSpacing.space1,
    this.color = AppColors.brandPrimary,
    this.backgroundColor = AppColors.progressTrack,
    super.key,
  }) : assert(value == null || (value >= 0 && value <= 1));

  final double? value;
  final String? semanticsLabel;
  final double minHeight;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value,
        minHeight: minHeight,
        color: color,
        backgroundColor: backgroundColor,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}
