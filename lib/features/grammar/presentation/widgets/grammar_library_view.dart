import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/catalog/presentation/jlpt_catalog_filter_chips.dart';
import 'package:rikipath_mobile/features/grammar/application/grammar_controller.dart';
import 'package:rikipath_mobile/features/grammar/domain/grammar.dart';
import 'package:rikipath_mobile/features/grammar/presentation/widgets/grammar_state_views.dart';

class GrammarLibraryView extends StatefulWidget {
  const GrammarLibraryView({
    required this.state,
    required this.catalog,
    required this.onSearch,
    required this.onFilter,
    required this.onRetryCatalog,
    required this.onClear,
    required this.onOpenDetail,
    required this.onLoadMore,
    super.key,
  });

  final GrammarLibraryState state;
  final AsyncValue<List<JlptLevelCatalogItem>> catalog;
  final ValueChanged<String> onSearch;
  final ValueChanged<JlptLevelCatalogItem?> onFilter;
  final VoidCallback onRetryCatalog;
  final VoidCallback onClear;
  final ValueChanged<GrammarEntry> onOpenDetail;
  final VoidCallback onLoadMore;

  @override
  State<GrammarLibraryView> createState() => _GrammarLibraryViewState();
}

class _GrammarLibraryViewState extends State<GrammarLibraryView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.query.keyword);
  }

  @override
  void didUpdateWidget(covariant GrammarLibraryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.query.keyword != _searchController.text) {
      _searchController.text = widget.state.query.keyword;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3,
            AppSpacing.space4,
            AppSpacing.space2,
          ),
          child: TextField(
            key: const ValueKey<String>('grammar_search_field'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: widget.onSearch,
            decoration: InputDecoration(
              hintText: context.l10n.grammarSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.l10n.clearSearch,
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        widget.onSearch('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        JlptCatalogFilterChips(
          catalog: widget.catalog,
          selected: state.query.level,
          onSelected: widget.onFilter,
          onRetry: widget.onRetryCatalog,
          keyPrefix: 'grammar_filter',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space1,
            AppSpacing.space4,
            AppSpacing.space2,
          ),
          child: Row(
            children: [
              if (state.page.source == GrammarDataSource.fixture) ...[
                Flexible(
                  child: Container(
                    key: const ValueKey<String>('grammar_fixture_label'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningBackground,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      context.l10n.sampleData,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.warningText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
              ] else
                const Spacer(),
              Text(
                context.l10n.grammarPatternCount(state.page.totalCount),
                style: AppTypography.metadata,
              ),
            ],
          ),
        ),
        Expanded(
          child: state.page.items.isEmpty
              ? GrammarEmptyView(onClear: widget.onClear)
              : ListView.separated(
                  key: const ValueKey<String>('grammar_list'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space1,
                    AppSpacing.space4,
                    AppSpacing.space8,
                  ),
                  itemCount:
                      state.page.items.length +
                      (state.page.hasNextPage || state.pageError != null
                          ? 1
                          : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space3),
                  itemBuilder: (context, index) {
                    if (index == state.page.items.length) {
                      return _LoadMore(
                        loading: state.isLoadingMore,
                        error: state.pageError,
                        onPressed: widget.onLoadMore,
                      );
                    }
                    final entry = state.page.items[index];
                    return _GrammarCard(
                      entry: entry,
                      onOpen: () => widget.onOpenDetail(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GrammarCard extends StatelessWidget {
  const _GrammarCard({required this.entry, required this.onOpen});

  final GrammarEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.grammarDetailSemantics(entry.title),
      child: InkWell(
        key: ValueKey<String>('grammar_card_${entry.routeKey}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: RikiCard(
          borderColor: AppColors.learnerOutline,
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: AppTypography.pageTitle.copyWith(
                        color: AppColors.learnerTextPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
              if (entry.explanation != null) ...[
                const SizedBox(height: AppSpacing.space1),
                Text(
                  entry.explanation!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: AppColors.learnerTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.learnerSurfaceLow,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Text(
                  context.l10n.grammarStructureInline(entry.structure),
                  style: AppTypography.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              JlptBadge(entry.level),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({
    required this.loading,
    required this.error,
    required this.onPressed,
  });

  final bool loading;
  final String? error;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: RikiInlineLoader(semanticsLabel: context.l10n.loading),
        ),
      );
    }
    return Column(
      children: [
        if (error != null) ...[
          Text(
            error!,
            textAlign: TextAlign.center,
            style: AppTypography.validationText,
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
        RikiSecondaryButton(
          key: const ValueKey<String>('grammar_load_more_button'),
          label: context.l10n.loadMore,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
