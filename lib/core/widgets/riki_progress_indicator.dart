import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiProgressIndicator extends StatelessWidget {
  const RikiProgressIndicator({this.value, this.semanticsLabel, super.key})
    : assert(value == null || (value >= 0 && value <= 1));

  final double? value;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: value,
        minHeight: AppSpacing.space1,
        color: AppColors.brandPrimary,
        backgroundColor: AppColors.progressTrack,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}
