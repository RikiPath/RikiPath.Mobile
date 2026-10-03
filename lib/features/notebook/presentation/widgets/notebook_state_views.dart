import 'package:flutter/material.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

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
    return RikiErrorState(
      key: const ValueKey<String>('notebook_error_view'),
      title: context.l10n.notebookLoadFailed,
      message: context.l10n.checkConnectionShort,
      actionLabel: context.l10n.retry,
      actionKey: const ValueKey<String>('notebook_retry_button'),
      onAction: onRetry,
    );
  }
}
