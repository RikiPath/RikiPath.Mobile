import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';

class SharedBankScreen extends StatelessWidget {
  const SharedBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: 'Ngân hàng kiến thức',
        subtitle: 'Chọn tài nguyên bạn muốn khám phá',
        onBack: context.pop,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey<String>('shared_bank_landing'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space8,
          ),
          children: [
            _LibraryEntry(
              key: const ValueKey<String>('shared_bank_vocabulary'),
              icon3d: Sakura3DIconType.vocabulary,
              label: context.l10n.vocabulary,
              description: 'Khám phá và ghi nhớ từ mới.',
              onTap: () => context.push(AppRoutes.vocabulary),
            ),
            const SizedBox(height: AppSpacing.space3),
            _LibraryEntry(
              key: const ValueKey<String>('shared_bank_kanji'),
              icon3d: Sakura3DIconType.kanji,
              label: context.l10n.skillKanji,
              description: 'Khám phá chữ Hán và cách viết.',
              onTap: () => context.push(AppRoutes.kanji),
            ),
            const SizedBox(height: AppSpacing.space3),
            _LibraryEntry(
              key: const ValueKey<String>('shared_bank_grammar'),
              icon3d: Sakura3DIconType.grammar,
              label: context.l10n.grammar,
              description: 'Nắm vững các cấu trúc tiếng Nhật.',
              onTap: () => context.push(AppRoutes.grammar),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryEntry extends StatelessWidget {
  const _LibraryEntry({
    required this.icon3d,
    required this.label,
    required this.onTap,
    this.description,
    super.key,
  });

  final Sakura3DIconType icon3d;
  final String label;
  final String? description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      onTap: onTap,
      backgroundColor: AppColors.cardWarmWhite,
      borderColor: AppColors.cardBorderMuted,
      boxShadow: AppShadows.sakuraSubtle,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Sakura3DIcon(type: icon3d, size: 52),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle,
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.learnerTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
