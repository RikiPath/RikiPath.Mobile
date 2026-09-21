import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class LessonLoadingView extends StatelessWidget {
  const LessonLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return RikiShimmer(
      key: const ValueKey<String>('lesson_loading_view'),
      semanticsLabel: context.l10n.loading,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: const [
          RikiSkeletonCard(height: 158, leading: false, lineCount: 4),
          SizedBox(height: AppSpacing.space4),
          RikiSkeletonCard(height: 88, leading: true, lineCount: 2),
          SizedBox(height: AppSpacing.space4),
          RikiSkeletonCard(height: 80, leading: true, lineCount: 1),
          SizedBox(height: AppSpacing.space4),
          RikiSkeletonCard(height: 80, leading: true, lineCount: 1),
        ],
      ),
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
                context.l10n.lessonLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                context.l10n.checkConnectionRetry,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              RikiPrimaryButton(
                key: const ValueKey<String>('lesson_load_retry_button'),
                label: context.l10n.retry,
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
