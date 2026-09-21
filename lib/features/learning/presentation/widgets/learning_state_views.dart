import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class LearningLoadingView extends StatelessWidget {
  const LearningLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return RikiShimmer(
      key: const ValueKey<String>('learning_loading_view'),
      semanticsLabel: context.l10n.loading,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: const [
          RikiSkeleton(height: 44, borderRadius: AppRadius.input),
          SizedBox(height: AppSpacing.space4),
          RikiSkeletonCard(height: 216, leading: false, lineCount: 5),
          SizedBox(height: AppSpacing.space4),
          RikiSkeletonCard(height: 116, leading: true),
          SizedBox(height: AppSpacing.space4),
          RikiSkeletonCard(height: 92, leading: true, lineCount: 2),
        ],
      ),
    );
  }
}

class LearningErrorView extends StatelessWidget {
  const LearningErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('learning_error_view'),
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
                radius: 26,
                backgroundColor: AppColors.errorBackground,
                foregroundColor: AppColors.errorText,
                child: Icon(Icons.cloud_off_outlined),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                context.l10n.learningLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                context.l10n.checkConnectionRetry,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const ValueKey<String>('learning_retry_button'),
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
