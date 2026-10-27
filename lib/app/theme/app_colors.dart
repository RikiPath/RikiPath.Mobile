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
  static const Color brandShadowSoft = Color(0x14E05A7A);
  static const Color brandShadow = Color(0x4DE05A7A);
  static const Color brandShadowStrong = Color(0x59E05A7A);
  static const Color neutralShadowSoft = Color(0x0A2D282A);
  static const Color neutralShadow = Color(0x142D282A);

  // Neutral foundations keep Sakura as an accent instead of tinting every
  // layer of the learner experience. Brand tints remain available below for
  // selected, interactive, and progress states.
  static const Color backgroundPrimary = Color(0xFFF7F6F7);
  static const Color backgroundSecondary = Color(0xFFFBFAFA);
  static const Color surfacePrimary = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F2F3);
  static const Color surfaceMutedStrong = Color(0xFFEDE9EA);

  // Auth uses a warm neutral paper-like canvas while keeping Sakura for
  // brand and interaction accents rather than tinting the full page.
  static const Color authBackground = backgroundSecondary;

  static const Color background = backgroundPrimary;
  static const Color profileBackground = backgroundPrimary;
  static const Color profileNeutralSurface = surfacePrimary;
  static const Color profileAccentSurface = Color(0xFFFFF3F6);
  static const Color surface = surfacePrimary;
  static const Color surfaceSubtle = surfaceMuted;
  static const Color surfaceContainer = Color(0xFFFCE7EB);
  static const Color surfaceContainerHigh = Color(0xFFF8DBE2);
  static const Color input = Color(0xFFFFFFFF);
  static const Color inputProcessing = Color(0xFFF6EBEE);

  static const Color textPrimary = Color(0xFF2D282A);
  static const Color textBody = Color(0xFF2D282A);
  static const Color textSecondary = Color(0xFF695F63);
  static const Color textMuted = Color(0xFF9E9397);
  static const Color textDisabled = Color(0xFF9E9397);

  static const Color border = Color(0xFFE5E0E2);
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

  // Calm feature accents keep cards neutral while giving each learning tool
  // a stable visual meaning. These colors are intentionally desaturated so
  // Sakura remains the strongest brand and primary-action color.
  static const Color featureBlue = Color(0xFF4F6F99);
  static const Color featureBluePressed = Color(0xFF3D587B);
  static const Color featureBlueBackground = Color(0xFFEEF3F8);
  static const Color featureBlueBorder = Color(0xFFD6E0EA);

  static const Color featureViolet = Color(0xFF74558A);
  static const Color featureVioletPressed = Color(0xFF5B426D);
  static const Color featureVioletBackground = Color(0xFFF4EFF7);
  static const Color featureVioletBorder = Color(0xFFDDD1E5);

  static const Color featureIndigo = Color(0xFF4F628C);
  static const Color featureIndigoPressed = Color(0xFF3E4F73);
  static const Color featureIndigoBackground = Color(0xFFEFF1F7);
  static const Color featureIndigoBorder = Color(0xFFD4DAE7);

  static const Color featureTeal = Color(0xFF2E7872);
  static const Color featureTealPressed = Color(0xFF245F5A);
  static const Color featureTealBackground = Color(0xFFEDF7F5);
  static const Color featureTealBorder = Color(0xFFCBE4DF);

  static const Color featureAmber = Color(0xFF956119);
  static const Color featureAmberPressed = Color(0xFF754B12);
  static const Color featureAmberBackground = Color(0xFFFFF5E7);
  static const Color featureAmberBorder = Color(0xFFEED9B8);

  // Compatibility roles used throughout the existing learner presentation.
  // Large areas stay neutral; Sakura is reserved for purposeful emphasis.
  static const Color learnerBackground = background;
  static const Color learnerSurfaceLow = backgroundSecondary;
  static const Color learnerSurface = surfacePrimary;
  static const Color learnerSurfaceHigh = surfaceMuted;
  static const Color learnerSurfaceHighest = surfaceMutedStrong;
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

  // Compatibility alias for pre-design-system frontend code.
  static const Color danger = errorText;

  // ---------------------------------------------------------------------------
  // Sakura System Expansion
  // ---------------------------------------------------------------------------
  // Rich Sakura tonal scale for modern Japanese learning aesthetic.
  // Preserves existing canonical tokens above for full regression safety.
  static const Color sakura50 = Color(0xFFFFF5F7);
  static const Color sakura100 = Color(0xFFFFE8ED);
  static const Color sakura200 = Color(0xFFFDC8D3);
  static const Color sakura300 = Color(0xFFF99CB0);
  static const Color sakura400 = Color(0xFFEE6F8E);
  static const Color sakura500 = brandPrimary; // 0xFFE05A7A
  static const Color sakura600 = brandPrimaryPressed; // 0xFFC24362
  static const Color sakura700 = Color(0xFFA1334E);
  static const Color sakura800 = Color(0xFF82273D);
  static const Color sakura900 = Color(0xFF651E2F);
  static const Color sakuraDeep = Color(0xFF8C2340);

  // Surfaces: Warm white, porcelain & subtle Sakura borders
  static const Color cardWarmWhite = Color(0xFFFFFFFF);
  static const Color cardWarmPorcelain = Color(0xFFFCFBFB);
  static const Color cardBorderSubtle = Color(0xFFF3E7EA);
  static const Color cardBorderMuted = Color(0xFFEFE8EA);
  static const Color borderSubtlePink = Color(0xFFF7DDE3);

  // Category Pastel Tones (Học tập, Từ vựng, Ngữ pháp, Luyện nghe)
  static const Color pastelGreenBg = Color(0xFFE8F7EE);
  static const Color pastelGreenFg = Color(0xFF1E824C);
  static const Color pastelGreenBorder = Color(0xFFC7EBD4);

  static const Color pastelBlueBg = Color(0xFFEAF2FD);
  static const Color pastelBlueFg = Color(0xFF206AC0);
  static const Color pastelBlueBorder = Color(0xFFCBE0FA);

  static const Color pastelOrangeBg = Color(0xFFFFF2E6);
  static const Color pastelOrangeFg = Color(0xFFD46B08);
  static const Color pastelOrangeBorder = Color(0xFFFFDAB8);

  static const Color pastelPurpleBg = Color(0xFFF4ECFB);
  static const Color pastelPurpleFg = Color(0xFF8338EC);
  static const Color pastelPurpleBorder = Color(0xFFE0C9F7);

  // Gradients for Hero surfaces and banners
  static const LinearGradient sakuraHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFFF3F5),
      Color(0xFFFFECF0),
      Color(0xFFFFF8F9),
    ],
  );

  static const LinearGradient sakuraCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFFFFFF),
      Color(0xFFFFFBFB),
    ],
  );

  static const LinearGradient sakuraAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFE05A7A),
      Color(0xFFD64468),
    ],
  );
}
