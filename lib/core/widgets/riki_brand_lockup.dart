import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

/// Canonical RikiPath mark, wordmark, and optional learner-level badge.
class RikiBrandLockup extends StatelessWidget {
  const RikiBrandLockup({this.level, this.compact = false, super.key});

  final JlptLevel? level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 32.0 : 40.0;

    return Semantics(
      container: true,
      label: level == null ? 'RikiPath' : 'RikiPath, JLPT ${level!.label}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const ValueKey<String>('riki_brand_mark'),
            width: markSize,
            height: markSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(AppRadius.compact),
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
              key: const ValueKey<String>('riki_brand_wordmark'),
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
      ),
    );
  }
}
