import 'package:flutter/material.dart';

/// Semantic colors derived from the approved RikiPath Stitch references.
abstract final class AppColors {
  static const Color brandPrimary = Color(0xFFB7131A);
  static const Color brandPrimaryPressed = Color(0xFF9B1016);
  static const Color brandPrimaryDisabled = Color(0xFFE2E8F0);
  static const Color brandTint = Color(0xFFFEF2F2);
  static const Color brandBorder = Color(0xFFFEE2E2);
  static const Color brandSelectedTint = Color(0xFFFFF1F2);
  static const Color brandSelectedBorder = Color(0xFFFDA4AF);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color input = Color(0xFFFFFFFF);
  static const Color inputProcessing = Color(0xFFF8FAFC);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color borderFocused = brandPrimary;

  static const Color error = Color(0xFFEF4444);
  static const Color errorText = Color(0xFFDC2626);
  static const Color errorBackground = Color(0xFFFEF2F2);

  static const Color success = Color(0xFF059669);
  static const Color successAccent = Color(0xFF10B981);
  static const Color successBackground = Color(0xFFECFDF5);
  static const Color successBackgroundSoft = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFA7F3D0);
  static const Color successBorderSoft = Color(0xFFBBF7D0);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningText = Color(0xFF78350F);

  static const Color info = Color(0xFF2563EB);
  static const Color infoBackground = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFDBEAFE);

  // Learner-shell surfaces documented by the approved post-auth Stitch set.
  // These remain separate from the auth surfaces so C6/C7 visuals stay stable.
  static const Color learnerBackground = Color(0xFFF8F9FF);
  static const Color learnerSurfaceLow = Color(0xFFEFF4FF);
  static const Color learnerSurface = Color(0xFFE6EEFF);
  static const Color learnerSurfaceHigh = Color(0xFFDEE9FC);
  static const Color learnerSurfaceHighest = Color(0xFFD9E3F6);
  static const Color learnerTextPrimary = Color(0xFF121C2A);
  static const Color learnerTextSecondary = Color(0xFF5B403D);
  static const Color learnerOutline = Color(0xFFE4BEB9);
  static const Color learnerPrimaryFixed = Color(0xFFFFDAD6);
  static const Color learnerTertiary = Color(0xFF8D4B00);
  static const Color learnerTertiaryBackground = Color(0xFFFFDCC3);

  /// Compatibility alias for pre-design-system frontend code.
  static const Color danger = errorText;
}
