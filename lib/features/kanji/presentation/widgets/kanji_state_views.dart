import 'package:flutter/material.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

class KanjiLoadingView extends StatelessWidget {
  const KanjiLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return RikiSectionSkeleton(
      key: const ValueKey<String>('kanji_loading_view'),
      semanticsLabel: context.l10n.loading,
      itemCount: 2,
      cardHeight: 112,
    );
  }
}

class KanjiEmptyView extends StatelessWidget {
  const KanjiEmptyView({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(
      key: const ValueKey<String>('kanji_empty_view'),
      icon: Icons.search_off_outlined,
      title: context.l10n.kanjiEmptyTitle,
      message: context.l10n.vocabularyEmptyMessage,
      actionLabel: context.l10n.clearFilters,
      onAction: onClear,
    );
  }
}

class KanjiErrorView extends StatelessWidget {
  const KanjiErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiErrorState(
      key: const ValueKey<String>('kanji_error_view'),
      title: context.l10n.kanjiLoadFailed,
      message: context.l10n.checkConnectionRetry,
      actionLabel: context.l10n.retry,
      actionKey: const ValueKey<String>('kanji_retry_button'),
      onAction: onRetry,
    );
  }
}
