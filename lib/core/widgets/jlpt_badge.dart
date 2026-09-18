import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

enum JlptLevel {
  n5('N5'),
  n4('N4'),
  n3('N3');

  const JlptLevel(this.label);

  final String label;
}

class JlptBadge extends StatelessWidget {
  const JlptBadge(this.level, {super.key});

  final JlptLevel level;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(level);

    return Semantics(
      label: 'Trình độ JLPT ${level.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          level.label,
          style: AppTypography.badgeText.copyWith(color: colors.foreground),
        ),
      ),
    );
  }

  _JlptBadgeColors _colorsFor(JlptLevel level) {
    return switch (level) {
      JlptLevel.n5 => const _JlptBadgeColors(
        foreground: AppColors.jlptN5Foreground,
        background: AppColors.jlptN5Background,
        border: AppColors.brandBorder,
      ),
      JlptLevel.n4 => const _JlptBadgeColors(
        foreground: AppColors.jlptN4Foreground,
        background: AppColors.jlptN4Background,
        border: AppColors.brandPrimary,
      ),
      JlptLevel.n3 => const _JlptBadgeColors(
        foreground: AppColors.jlptN3Foreground,
        background: AppColors.jlptN3Background,
        border: AppColors.borderStrong,
      ),
    };
  }
}

class _JlptBadgeColors {
  const _JlptBadgeColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}
