import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class LearningLoadingView extends StatelessWidget {
  const LearningLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('learning_loading_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: const [
        _SkeletonBlock(height: 44),
        SizedBox(height: AppSpacing.space4),
        _SkeletonCard(height: 280),
        SizedBox(height: AppSpacing.space4),
        _SkeletonCard(height: 180),
        SizedBox(height: AppSpacing.space4),
        _SkeletonCard(height: 150),
      ],
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
                'Chưa thể tải nội dung học tập',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Vui lòng kiểm tra kết nối và thử lại.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const ValueKey<String>('learning_retry_button'),
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

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.learnerOutline,
      boxShadow: const <BoxShadow>[],
      child: _SkeletonBlock(height: height),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.learnerSurfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.compact),
      ),
    );
  }
}
