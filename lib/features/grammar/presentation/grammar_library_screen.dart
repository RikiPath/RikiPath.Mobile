import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/grammar/application/grammar_controller.dart';
import 'package:rikipath_mobile/features/grammar/presentation/widgets/grammar_library_view.dart';
import 'package:rikipath_mobile/features/grammar/presentation/widgets/grammar_state_views.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';

class GrammarLibraryScreen extends ConsumerWidget {
  const GrammarLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(grammarLibraryControllerProvider);
    final controller = ref.read(grammarLibraryControllerProvider.notifier);
    final catalog = ref.watch(jlptCatalogControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.grammar,
        subtitle: context.l10n.library,
        onBack: context.pop,
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: GrammarLoadingView.new,
          error: (_, _) => GrammarErrorView(onRetry: controller.retry),
          data: (data) => GrammarLibraryView(
            state: data,
            catalog: catalog,
            onSearch: controller.search,
            onFilter: controller.filterByLevel,
            onRetryCatalog: ref
                .read(jlptCatalogControllerProvider.notifier)
                .retry,
            onClear: controller.clear,
            onOpenDetail: (entry) =>
                context.push(AppRoutes.grammarDetail(entry.routeKey)),
            onLoadMore: controller.loadNextPage,
          ),
        ),
      ),
    );
  }
}
