import 'package:flutter/material.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class GrammarLoadingView extends StatelessWidget {
  const GrammarLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return RikiSectionSkeleton(
      key: const ValueKey<String>('grammar_loading_view'),
      semanticsLabel: context.l10n.loading,
      itemCount: 2,
      cardHeight: 108,
    );
  }
}

class GrammarEmptyView extends StatelessWidget {
  const GrammarEmptyView({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(
      key: const ValueKey<String>('grammar_empty_view'),
      icon: Icons.search_off_outlined,
      title: context.l10n.grammarEmptyTitle,
      message: context.l10n.vocabularyEmptyMessage,
      actionLabel: context.l10n.clearFilters,
      onAction: onClear,
    );
  }
}

class GrammarErrorView extends StatelessWidget {
  const GrammarErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      key: const ValueKey<String>('grammar_error_view'),
      title: context.l10n.grammarLoadFailed,
      message: context.l10n.checkConnectionRetry,
      actionLabel: context.l10n.retry,
      actionKey: const ValueKey<String>('grammar_retry_button'),
      onAction: onRetry,
    );
  }
}
