import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/kanji/application/kanji_controller.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/presentation/widgets/kanji_state_views.dart';

class KanjiLibraryView extends StatelessWidget {
  const KanjiLibraryView({
    required this.state,
    required this.searchController,
    required this.onSearch,
    required this.onFilter,
    required this.onClear,
    required this.onOpenDetail,
    required this.onPlayAudio,
    required this.onLoadMore,
    super.key,
  });

  final KanjiLibraryState state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<JlptLevel?> onFilter;
  final VoidCallback onClear;
  final ValueChanged<KanjiEntry> onOpenDetail;
  final ValueChanged<KanjiEntry> onPlayAudio;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.page.items.isEmpty) return KanjiEmptyView(onClear: onClear);

    return ListView(
      key: const ValueKey<String>('kanji_library_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space6,
      ),
      children: [
        TextField(
          key: const ValueKey<String>('kanji_search_field'),
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: onSearch,
          decoration: InputDecoration(
            hintText: context.l10n.kanjiSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: context.l10n.search,
              onPressed: () => onSearch(searchController.text),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _LevelChip(
                label: context.l10n.all,
                selected: state.query.level == null,
                onSelected: () => onFilter(null),
              ),
              for (final level in JlptLevel.values) ...[
                const SizedBox(width: AppSpacing.space2),
                _LevelChip(
                  label: level.label,
                  selected: state.query.level == level,
                  onSelected: () => onFilter(level),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.kanjiCount(state.page.totalCount),
                style: AppTypography.sectionTitle,
              ),
            ),
            if (state.page.source == KanjiDataSource.fixture)
              Flexible(
                child: Container(
                  key: const ValueKey<String>('kanji_fixture_label'),
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
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        for (final entry in state.page.items) ...[
          _KanjiCard(
            entry: entry,
            onOpen: () => onOpenDetail(entry),
            onPlayAudio: entry.audioUrl == null
                ? null
                : () => onPlayAudio(entry),
          ),
          const SizedBox(height: AppSpacing.space3),
        ],
        if (state.pageError != null) ...[
          Text(
            state.pageError!,
            textAlign: TextAlign.center,
            style: AppTypography.validationText,
          ),
          const SizedBox(height: AppSpacing.space2),
        ],
        if (state.page.hasNextPage)
          Center(
            child: state.isLoadingMore
                ? RikiInlineLoader(
                    key: ValueKey<String>('kanji_loading_more'),
                    semanticsLabel: context.l10n.loading,
                  )
                : RikiSecondaryButton(
                    key: const ValueKey<String>('kanji_load_more_button'),
                    label: context.l10n.showMore,
                    onPressed: onLoadMore,
                  ),
          ),
      ],
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      key: ValueKey<String>('kanji_level_$label'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.brandTint,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.brandPrimary : AppColors.border,
      ),
      labelStyle: AppTypography.badgeText.copyWith(
        color: selected
            ? AppColors.brandPrimary
            : AppColors.learnerTextSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
    );
  }
}

class _KanjiCard extends StatelessWidget {
  const _KanjiCard({
    required this.entry,
    required this.onOpen,
    required this.onPlayAudio,
  });

  final KanjiEntry entry;
  final VoidCallback onOpen;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.kanjiDetailSemantics(entry.character),
      child: InkWell(
        key: ValueKey<String>('kanji_card_${entry.routeKey}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: RikiCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.learnerSurfaceLow,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Text(
                  entry.character,
                  style: AppTypography.heroTitle.copyWith(fontSize: 48),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        JlptBadge(entry.level),
                        Text(
                          context.l10n.strokeCount(entry.strokeCount),
                          style: AppTypography.metadata,
                        ),
                        if (entry.sinoVietnamese != null)
                          Text(
                            entry.sinoVietnamese!,
                            style: AppTypography.badgeText.copyWith(
                              color: AppColors.brandPrimary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      entry.meaning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle,
                    ),
                    if (entry.onYomi != null || entry.kunYomi != null) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        [
                          if (entry.onYomi != null)
                            '${context.l10n.onReading}: ${entry.onYomi}',
                          if (entry.kunYomi != null)
                            '${context.l10n.kunReading}: ${entry.kunYomi}',
                        ].join('  •  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.metadata,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: onPlayAudio == null
                    ? context.l10n.audioUnavailable
                    : context.l10n.listenReading,
                onPressed: onPlayAudio,
                icon: Icon(
                  Icons.volume_up_outlined,
                  color: onPlayAudio == null
                      ? AppColors.textMuted
                      : AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
