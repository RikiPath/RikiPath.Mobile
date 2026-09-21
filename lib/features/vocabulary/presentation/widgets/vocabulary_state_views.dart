import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class VocabularyLoadingView extends StatelessWidget {
  const VocabularyLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return RikiSectionSkeleton(
      key: const ValueKey<String>('vocabulary_loading_view'),
      semanticsLabel: context.l10n.loading,
      itemCount: 3,
      cardHeight: 116,
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
              context.l10n.vocabularyEmptyTitle,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              context.l10n.vocabularyEmptyMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.space5),
            RikiSecondaryButton(
              label: context.l10n.clearFilters,
              onPressed: onClear,
            ),
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
                context.l10n.vocabularyLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                context.l10n.checkConnectionRetry,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const ValueKey<String>('vocabulary_retry_button'),
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
