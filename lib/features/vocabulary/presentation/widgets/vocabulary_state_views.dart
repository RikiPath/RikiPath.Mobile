import 'package:flutter/material.dart';
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
    return RikiEmptyState(
      key: const ValueKey<String>('vocabulary_empty_view'),
      icon: Icons.search_off_outlined,
      title: context.l10n.vocabularyEmptyTitle,
      message: context.l10n.vocabularyEmptyMessage,
      actionLabel: context.l10n.clearFilters,
      onAction: onClear,
    );
  }
}

class VocabularyErrorView extends StatelessWidget {
  const VocabularyErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      key: const ValueKey<String>('vocabulary_error_view'),
      title: context.l10n.vocabularyLoadFailed,
      message: context.l10n.checkConnectionRetry,
      actionLabel: context.l10n.retry,
      actionKey: const ValueKey<String>('vocabulary_retry_button'),
      onAction: onRetry,
    );
  }
}
