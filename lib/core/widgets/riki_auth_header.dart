import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/language_badge.dart';

class RikiAuthHeader extends StatelessWidget {
  const RikiAuthHeader({
    this.level,
    this.languageCode = 'VI',
    this.onLanguagePressed,
    this.onBack,
    this.backSemanticLabel = 'Quay lại',
    this.statusLabel,
    super.key,
  }) : assert(
          onBack == null || statusLabel == null,
          'A centered back header cannot also show a status badge.',
        );

  final JlptLevel? level;
  final String languageCode;
  final VoidCallback? onLanguagePressed;
  final VoidCallback? onBack;
  final String backSemanticLabel;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    if (onBack != null) {
      return SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox.square(
              dimension: 48,
              child: IconButton(
                onPressed: onBack,
                tooltip: backSemanticLabel,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const Expanded(
              child: Center(child: _BrandLockup(compact: true)),
            ),
            const SizedBox(width: 48),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: _BrandLockup(level: level)),
        const SizedBox(width: AppSpacing.space3),
        if (statusLabel != null)
          _StatusBadge(label: statusLabel!)
        else
          LanguageBadge(
            languageCode: languageCode,
            onPressed: onLanguagePressed,
          ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({this.level, this.compact = false});

  final JlptLevel? level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 32.0 : 40.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(
              compact ? AppRadius.compact : AppRadius.input,
            ),
            boxShadow: AppShadows.cardSoft,
          ),
          child: Text(
            '文',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 16 : 20,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Flexible(
          child: Text(
            'RikiPath',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: AppTypography.brandWordmark,
          ),
        ),
        if (level != null) ...[
          const SizedBox(width: AppSpacing.space2),
          JlptBadge(level!),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        border: Border.all(color: AppColors.successBorder),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.space1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.badgeText.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
