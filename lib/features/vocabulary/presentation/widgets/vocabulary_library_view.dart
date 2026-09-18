import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/vocabulary/application/vocabulary_controller.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/widgets/vocabulary_state_views.dart';

class VocabularyLibraryView extends StatefulWidget {
  const VocabularyLibraryView({
    required this.state,
    required this.onSearch,
    required this.onFilter,
    required this.onClear,
    required this.onOpenDetail,
    required this.onPlayAudio,
    required this.onLoadMore,
    super.key,
  });

  final VocabularyLibraryState state;
  final ValueChanged<String> onSearch;
  final ValueChanged<JlptLevel?> onFilter;
  final VoidCallback onClear;
  final ValueChanged<VocabularyEntry> onOpenDetail;
  final ValueChanged<VocabularyEntry> onPlayAudio;
  final VoidCallback onLoadMore;

  @override
  State<VocabularyLibraryView> createState() => _VocabularyLibraryViewState();
}

class _VocabularyLibraryViewState extends State<VocabularyLibraryView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.query.keyword);
  }

  @override
  void didUpdateWidget(covariant VocabularyLibraryView oldWidget) {
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
            key: const ValueKey<String>('vocabulary_search_field'),
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: widget.onSearch,
            decoration: InputDecoration(
              hintText: 'Tìm từ tiếng Nhật, cách đọc hoặc nghĩa...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
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
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            children: [
              _LevelFilterChip(
                key: const ValueKey<String>('vocabulary_filter_all'),
                label: 'Tất cả',
                selected: state.query.level == null,
                onSelected: () => widget.onFilter(null),
              ),
              for (final level in JlptLevel.values) ...[
                const SizedBox(width: AppSpacing.space2),
                _LevelFilterChip(
                  key: ValueKey<String>('vocabulary_filter_${level.name}'),
                  label: 'JLPT ${level.label}',
                  selected: state.query.level == level,
                  onSelected: () => widget.onFilter(level),
                ),
              ],
            ],
          ),
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
              if (state.page.source == VocabularyDataSource.fixture)
                Flexible(
                  child: Container(
                    key: const ValueKey<String>('vocabulary_fixture_badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningBackground,
                      borderRadius: BorderRadius.circular(AppRadius.tag),
                    ),
                    child: Text(
                      'Dữ liệu minh họa',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.warningText,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '${state.page.totalCount} từ',
                style: AppTypography.metadata,
              ),
            ],
          ),
        ),
        Expanded(
          child: state.page.items.isEmpty
              ? VocabularyEmptyView(onClear: widget.onClear)
              : ListView.separated(
                  key: const ValueKey<String>('vocabulary_list'),
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
                    return _VocabularyCard(
                      entry: entry,
                      onOpen: () => widget.onOpenDetail(entry),
                      onPlayAudio: () => widget.onPlayAudio(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LevelFilterChip extends StatelessWidget {
  const _LevelFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.brandTint,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? AppColors.brandPrimary : AppColors.border,
      ),
      labelStyle: AppTypography.badgeText.copyWith(
        color: selected ? AppColors.brandPrimary : AppColors.learnerTextPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  const _VocabularyCard({
    required this.entry,
    required this.onOpen,
    required this.onPlayAudio,
  });

  final VocabularyEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onPlayAudio;

  @override
  Widget build(BuildContext context) {
    final sinoVietnamese = entry.enrichment?.sinoVietnamese;
    final partOfSpeech = entry.partOfSpeech?.trim();

    return Semantics(
      button: true,
      label: '${entry.word}, ${entry.reading}, ${entry.meaning}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('vocabulary_card_${entry.routeKey}'),
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: RikiCard(
            borderColor: AppColors.learnerOutline,
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.reading,
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        entry.word,
                        style: AppTypography.heroTitle.copyWith(
                          color: AppColors.learnerTextPrimary,
                          fontSize: 28,
                        ),
                      ),
                      if (sinoVietnamese != null) ...[
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          sinoVietnamese,
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        entry.meaning,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: AppColors.learnerTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      Wrap(
                        spacing: AppSpacing.space2,
                        runSpacing: AppSpacing.space2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          JlptBadge(entry.level),
                          if (partOfSpeech != null && partOfSpeech.isNotEmpty)
                            _Tag(label: partOfSpeech),
                          if (entry.isSaved == true)
                            const _Tag(
                              label: 'Đã lưu',
                              icon: Icons.bookmark,
                              foregroundColor: AppColors.success,
                              backgroundColor: AppColors.successBackground,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                IconButton(
                  key: ValueKey<String>('vocabulary_audio_${entry.routeKey}'),
                  tooltip: entry.audioUrl == null
                      ? 'Chưa có âm thanh'
                      : 'Nghe phát âm',
                  onPressed: entry.audioUrl == null ? null : onPlayAudio,
                  icon: Icon(
                    Icons.volume_up_outlined,
                    color: entry.audioUrl == null
                        ? AppColors.textDisabled
                        : AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    this.icon,
    this.foregroundColor = AppColors.textSecondary,
    this.backgroundColor = AppColors.surfaceSubtle,
  });

  final String label;
  final IconData? icon;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.tag),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            label,
            style: AppTypography.badgeText.copyWith(color: foregroundColor),
          ),
        ],
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space4),
          child: CircularProgressIndicator(),
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
        RikiSecondaryButton(label: 'Tải thêm', onPressed: onPressed),
      ],
    );
  }
}
