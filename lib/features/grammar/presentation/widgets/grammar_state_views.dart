import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class GrammarLoadingView extends StatelessWidget {
  const GrammarLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('grammar_loading_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: const [
        _GrammarSkeleton(height: 48),
        SizedBox(height: AppSpacing.space3),
        _GrammarSkeleton(height: 40),
        SizedBox(height: AppSpacing.space4),
        _GrammarSkeleton(height: 172),
        SizedBox(height: AppSpacing.space3),
        _GrammarSkeleton(height: 172),
      ],
    );
  }
}

class GrammarEmptyView extends StatelessWidget {
  const GrammarEmptyView({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('grammar_empty_view'),
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
              'Không tìm thấy ngữ pháp',
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

class GrammarErrorView extends StatelessWidget {
  const GrammarErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('grammar_error_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        const SizedBox(height: AppSpacing.space10),
        RikiCard(
          boxShadow: const <BoxShadow>[],
          borderColor: AppColors.learnerOutline,
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
                'Chưa thể tải thư viện ngữ pháp',
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
                key: const ValueKey<String>('grammar_retry_button'),
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

class _GrammarSkeleton extends StatelessWidget {
  const _GrammarSkeleton({required this.height});

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
