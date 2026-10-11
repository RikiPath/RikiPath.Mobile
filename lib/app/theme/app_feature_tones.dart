import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';

@immutable
class RikiFeatureTone {
  const RikiFeatureTone({
    required this.foreground,
    required this.background,
    required this.border,
    required this.pressed,
  });

  final Color foreground;
  final Color background;
  final Color border;
  final Color pressed;
}

/// Feature accents based on the Neo-Japoniste Sakura visual language.
///
/// Sakura remains the primary product accent. Green is reserved for verified,
/// completed, and successful states; neutral tones support secondary content.
abstract final class AppFeatureTones {
  static const RikiFeatureTone brand = RikiFeatureTone(
    foreground: AppColors.brandPrimary,
    background: AppColors.brandTint,
    border: AppColors.brandBorder,
    pressed: AppColors.brandPrimaryPressed,
  );

  static const RikiFeatureTone learning = brand;

  static const RikiFeatureTone practice = learning;

  static const RikiFeatureTone review = brand;

  static const RikiFeatureTone success = RikiFeatureTone(
    foreground: AppColors.success,
    background: AppColors.successBackgroundSoft,
    border: AppColors.successBorderSoft,
    pressed: AppColors.success,
  );

  static const RikiFeatureTone ai = brand;

  static const RikiFeatureTone speech = brand;

  static const RikiFeatureTone writing = brand;

  static const RikiFeatureTone textScan = brand;

  static const RikiFeatureTone meeting = brand;

  static const RikiFeatureTone neutral = RikiFeatureTone(
    foreground: AppColors.textSecondary,
    background: AppColors.surfaceMuted,
    border: AppColors.border,
    pressed: AppColors.textPrimary,
  );
}
