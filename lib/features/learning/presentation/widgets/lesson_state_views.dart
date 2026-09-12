import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class LessonLoadingView extends StatelessWidget {
  const LessonLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('lesson_loading_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: const [
        _LessonSkeleton(height: 210),
        SizedBox(height: AppSpacing.space4),
        _LessonSkeleton(height: 120),
        SizedBox(height: AppSpacing.space4),
        _LessonSkeleton(height: 76),
        SizedBox(height: AppSpacing.space4),
        _LessonSkeleton(height: 76),
        SizedBox(height: AppSpacing.space4),
        _LessonSkeleton(height: 76),
      ],
    );
  }
}

class LessonLoadErrorView extends StatelessWidget {
  const LessonLoadErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('lesson_load_error_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        const SizedBox(height: AppSpacing.space10),
        RikiCard(
          boxShadow: const <BoxShadow>[],
          child: Column(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.errorBackground,
                foregroundColor: AppColors.errorText,
                child: Icon(Icons.cloud_off_outlined),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Chưa thể tải bài học',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Vui lòng kiểm tra kết nối và thử lại.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              RikiPrimaryButton(
                key: const ValueKey<String>('lesson_load_retry_button'),
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

class _LessonSkeleton extends StatelessWidget {
  const _LessonSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Align(
        alignment: Alignment.topLeft,
        child: FractionallySizedBox(
          widthFactor: 0.68,
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.learnerSurfaceHigh,
              borderRadius: BorderRadius.circular(AppRadius.compact),
            ),
          ),
        ),
      ),
    );
  }
}
