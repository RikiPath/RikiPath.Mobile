import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';

class NotebookLoadingView extends StatelessWidget {
  const NotebookLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return RikiSectionSkeleton(
      key: const ValueKey<String>('notebook_loading_view'),
      semanticsLabel: context.l10n.loading,
      itemCount: 3,
      cardHeight: 92,
    );
  }
}

class NotebookErrorView extends StatelessWidget {
  const NotebookErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('notebook_error_view'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              context.l10n.notebookLoadFailed,
              style: AppTypography.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              context.l10n.checkConnectionShort,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            FilledButton(
              key: const ValueKey<String>('notebook_retry_button'),
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
