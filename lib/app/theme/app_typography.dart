import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';

/// Platform-sans typography roles derived from the Stitch type hierarchy.
///
/// No font family is forced here. Flutter therefore uses the platform font and
/// the fallback chain configured by [AppTheme].
abstract final class AppTypography {
  static const TextStyle brandWordmark = TextStyle(
    color: AppColors.brandPrimary,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle heroTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 26,
    height: 1.35,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.65,
  );

  static const TextStyle pageTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static const TextStyle compactPageTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    height: 1.27,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 1.38,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textBody,
    fontSize: 14,
    height: 1.57,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    height: 1.46,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle metadata = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle inputLabel = TextStyle(
    color: AppColors.textBody,
    fontSize: 12,
    height: 1.34,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle inputText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15,
    height: 1.34,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle validationText = TextStyle(
    color: AppColors.errorText,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );

  static const TextTheme textTheme = TextTheme(
    displaySmall: heroTitle,
    headlineMedium: heroTitle,
    headlineSmall: pageTitle,
    titleLarge: compactPageTitle,
    titleMedium: sectionTitle,
    titleSmall: cardTitle,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: buttonLabel,
    labelMedium: badgeText,
    labelSmall: metadata,
  );
}
