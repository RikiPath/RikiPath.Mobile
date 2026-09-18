import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class VocabularyLoadingView extends StatelessWidget {
  const VocabularyLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('vocabulary_loading_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: const [
        _VocabularySkeleton(height: 48),
        SizedBox(height: AppSpacing.space4),
        _VocabularySkeleton(height: 34),
        SizedBox(height: AppSpacing.space4),
        _VocabularySkeleton(height: 180),
        SizedBox(height: AppSpacing.space3),
        _VocabularySkeleton(height: 180),
        SizedBox(height: AppSpacing.space3),
        _VocabularySkeleton(height: 180),
      ],
    );
  }
}

class VocabularyEmptyView extends StatelessWidget {
  const VocabularyEmptyView({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('vocabulary_empty_view'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.learnerSurface,
              foregroundColor: AppColors.brandPrimary,
              child: Icon(Icons.search_off_outlined),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              'Không tìm thấy từ vựng',
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Thử từ khóa khác hoặc bỏ bộ lọc JLPT.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.space5),
            RikiSecondaryButton(label: 'Xóa bộ lọc', onPressed: onClear),
          ],
        ),
      ),
    );
  }
}

class VocabularyErrorView extends StatelessWidget {
  const VocabularyErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('vocabulary_error_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        const SizedBox(height: AppSpacing.space10),
        RikiCard(
          borderColor: AppColors.learnerOutline,
          boxShadow: const <BoxShadow>[],
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.errorBackground,
                foregroundColor: AppColors.errorText,
                child: Icon(Icons.cloud_off_outlined),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Chưa thể tải thư viện từ vựng',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Vui lòng kiểm tra kết nối và thử lại.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const ValueKey<String>('vocabulary_retry_button'),
                label: 'Thử lại',
                leadingIcon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VocabularySkeleton extends StatelessWidget {
  const _VocabularySkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.learnerSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    );
  }
}
