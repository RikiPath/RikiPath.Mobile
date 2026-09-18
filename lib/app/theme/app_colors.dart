import 'package:flutter/material.dart';

/// Semantic colors derived from the Neo-Japoniste Sakura Stitch references.
abstract final class AppColors {
  static const Color brandPrimary = Color(0xFFE05A7A);
  static const Color brandPrimaryPressed = Color(0xFFC24362);
  static const Color brandPrimaryDisabled = Color(0xFFEAE0E2);
  static const Color brandSecondary = Color(0xFFF8BBD0);
  static const Color brandSecondaryPressed = Color(0xFFF8DBE2);
  static const Color brandTint = Color(0xFFFFF0F3);
  static const Color brandBorder = Color(0xFFF8BBD0);
  static const Color brandSelectedTint = Color(0xFFFFF0F3);
  static const Color brandSelectedBorder = Color(0xFFE05A7A);
  static const Color brandGradientEnd = Color(0xFFFF8FA3);
  static const Color brandShadowSoft = Color(0x14E05A7A);
  static const Color brandShadow = Color(0x4DE05A7A);
  static const Color brandShadowStrong = Color(0x59E05A7A);
  static const Color neutralShadowSoft = Color(0x0A2D282A);
  static const Color neutralShadow = Color(0x142D282A);

  static const Color background = Color(0xFFFFF9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFFFF0F3);
  static const Color surfaceContainer = Color(0xFFFCE7EB);
  static const Color surfaceContainerHigh = Color(0xFFF8DBE2);
  static const Color input = Color(0xFFFFFFFF);
  static const Color inputProcessing = Color(0xFFF6EBEE);

  static const Color textPrimary = Color(0xFF2D282A);
  static const Color textBody = Color(0xFF2D282A);
  static const Color textSecondary = Color(0xFF695F63);
  static const Color textMuted = Color(0xFF9E9397);
  static const Color textDisabled = Color(0xFF9E9397);

  static const Color border = Color(0xFFE8DDE0);
  static const Color borderStrong = Color(0xFFDDBFC3);
  static const Color borderFocused = brandPrimary;

  static const Color error = Color(0xFFD32F2F);
  static const Color errorText = Color(0xFFD32F2F);
  static const Color errorBackground = Color(0xFFFDEDED);
  static const Color errorBorder = error;

  static const Color success = Color(0xFF079D47);
  static const Color successAccent = Color(0xFF079D47);
  static const Color successBackground = Color(0xFFE8F5E9);
  static const Color successBackgroundSoft = Color(0xFFE7F6EC);
  static const Color successBorder = Color(0xFFC8E6C9);
  static const Color successBorderSoft = Color(0xFFC3E7CB);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningText = Color(0xFF78350F);

  static const Color info = Color(0xFF1976D2);
  static const Color infoBackground = Color(0xFFEAF2FD);
  static const Color infoBorder = Color(0xFFD8E7FA);

  // Compatibility roles used throughout the existing learner presentation.
  // They intentionally resolve to the same Sakura surface system.
  static const Color learnerBackground = background;
  static const Color learnerSurfaceLow = brandTint;
  static const Color learnerSurface = surfaceContainer;
  static const Color learnerSurfaceHigh = brandSecondaryPressed;
  static const Color learnerSurfaceHighest = surfaceContainerHigh;
  static const Color learnerTextPrimary = textPrimary;
  static const Color learnerTextSecondary = textSecondary;
  static const Color learnerOutline = border;
  static const Color learnerPrimaryFixed = surfaceContainer;
  static const Color learnerTertiary = Color(0xFF8D4B00);
  static const Color learnerTertiaryBackground = Color(0xFFFFDCC3);

  static const Color jlptN5Foreground = brandPrimary;
  static const Color jlptN5Background = surfaceContainer;
  static const Color jlptN4Foreground = brandPrimaryPressed;
  static const Color jlptN4Background = brandSecondary;
  static const Color jlptN3Foreground = Color(0xFF942B46);
  static const Color jlptN3Background = border;

  static const Color progressTrack = surfaceContainer;

  // Skill accents established by the approved JLPT progress reference.
  static const Color skillGrammar = Color(0xFFD97706);
  static const Color skillListening = Color(0xFF9333EA);
  static const Color skillListeningBackground = Color(0xFFFAF5FF);

  /// Compatibility alias for pre-design-system frontend code.
  static const Color danger = errorText;
}
