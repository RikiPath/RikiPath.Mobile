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
    return RikiErrorState(
      key: const ValueKey<String>('learning_error_view'),
      title: context.l10n.learningLoadFailed,
      message: context.l10n.checkConnectionRetry,
      actionLabel: context.l10n.retry,
      actionKey: const ValueKey<String>('learning_retry_button'),
      onAction: onRetry,
    );
  }
}
