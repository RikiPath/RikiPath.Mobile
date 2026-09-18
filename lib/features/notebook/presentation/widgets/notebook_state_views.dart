import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class NotebookLoadingView extends StatelessWidget {
  const NotebookLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('notebook_loading_view'),
      child: CircularProgressIndicator(),
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
              'Không thể tải Sổ từ',
              style: AppTypography.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              'Kiểm tra kết nối rồi thử lại.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space4),
            FilledButton(
              key: const ValueKey<String>('notebook_retry_button'),
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
