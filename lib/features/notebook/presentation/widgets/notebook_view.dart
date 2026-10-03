import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

class NotebookView extends StatefulWidget {
  const NotebookView({
    required this.state,
    required this.onSearch,
    required this.onClearSearch,
    required this.onSelectCollection,
    required this.onRetry,
    required this.onDismissMutationError,
    required this.onDismissEntriesError,
    required this.onCreateCollection,
    required this.onAddEntry,
    required this.onOpenEntry,
    required this.onRemoveEntry,
    super.key,
  });

  final NotebookLibraryState state;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<NotebookCollection> onSelectCollection;
  final VoidCallback onRetry;
  final VoidCallback onDismissMutationError;
  final VoidCallback onDismissEntriesError;
  final VoidCallback onCreateCollection;
  final VoidCallback onAddEntry;
  final ValueChanged<NotebookEntry> onOpenEntry;
  final ValueChanged<NotebookEntry> onRemoveEntry;

  @override
  State<NotebookView> createState() => _NotebookViewState();
}

class _NotebookViewState extends State<NotebookView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.query);
  }

  @override
  void didUpdateWidget(covariant NotebookView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.query != _searchController.text) {
      _searchController.text = widget.state.query;
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
    if (state.collections.isEmpty) {
      return _EmptyNotebook(onCreateCollection: widget.onCreateCollection);
    }

    final selected = state.selectedCollection;
    return Column(
      children: [
        if (state.isCreatingCollection || state.isAddingEntry)
          RikiProgressIndicator(
            key: const ValueKey<String>('notebook_mutation_progress'),
            semanticsLabel: context.l10n.processingSemantics,
          ),
        Expanded(
          child: ListView(
            key: const ValueKey<String>('notebook_content'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            children: [
              _OverviewCard(
                collectionCount: state.collections.length,
                entryCount: state.collections.fold<int>(
                  0,
                  (total, item) => total + item.entryCount,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.yourCollections,
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>(
                      'notebook_create_collection_button',
                    ),
                    tooltip: context.l10n.createCollection,
                    onPressed: state.isCreatingCollection
                        ? null
                        : widget.onCreateCollection,
                    icon: const Icon(Icons.create_new_folder_outlined),
                  ),
                ],
              ),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  key: const ValueKey<String>('notebook_collection_list'),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.collections.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.space2),
                  itemBuilder: (context, index) {
                    final collection = state.collections[index];
                    final isSelected =
                        collection.routeKey == state.selectedCollectionKey;
                    return ChoiceChip(
                      key: ValueKey<String>(
                        'notebook_collection_${collection.routeKey}',
                      ),
                      label: Text(
                        '${collection.name} (${collection.entryCount})',
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: AppColors.brandTint,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : AppColors.border,
                      ),
                      labelStyle: AppTypography.badgeText.copyWith(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                      onSelected: state.isLoadingEntries
                          ? null
                          : (_) => widget.onSelectCollection(collection),
                    );
                  },
                ),
              ),
              if (selected?.description != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(selected!.description!, style: AppTypography.metadata),
              ],
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey<String>('notebook_search_field'),
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(() {});
                        widget.onSearch(value);
                      },
                      decoration: InputDecoration(
                        hintText: context.l10n.notebookSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: context.l10n.clearSearch,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                  widget.onClearSearch();
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  IconButton.filled(
                    key: const ValueKey<String>('notebook_add_entry_button'),
                    tooltip: context.l10n.addNewWord,
                    onPressed: state.isAddingEntry || !state.canAddManualEntry
                        ? null
                        : widget.onAddEntry,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (state.mutationError != null) ...[
                const SizedBox(height: AppSpacing.space3),
                _InlineError(
                  key: const ValueKey<String>('notebook_mutation_error'),
                  message: state.mutationError!,
                  onDismiss: widget.onDismissMutationError,
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              if (state.isLoadingEntries)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space4,
                  ),
                  child: RikiShimmer(
                    key: const ValueKey<String>('notebook_entries_loading'),
                    semanticsLabel: context.l10n.loading,
                    child: const Column(
                      children: [
                        RikiSkeletonCard(height: 88, trailing: true),
                        SizedBox(height: AppSpacing.space3),
                        RikiSkeletonCard(height: 88),
                      ],
                    ),
                  ),
                )
              else if (state.entriesError != null && state.entries.isEmpty)
                _EntriesError(
                  message: state.entriesError!,
                  onRetry: widget.onRetry,
                )
              else if (state.visibleEntries.isEmpty)
                _EmptyEntries(
                  hasQuery: state.query.isNotEmpty,
                  onClear: widget.onClearSearch,
                  onAddEntry: widget.onAddEntry,
                )
              else ...[
                if (state.entriesError != null) ...[
                  _InlineError(
                    key: const ValueKey<String>('notebook_live_entries_error'),
                    message: state.entriesError!,
                    onDismiss: widget.onDismissEntriesError,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.savedWords,
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    Text(
                      context.l10n.itemCount(state.visibleEntries.length),
                      style: AppTypography.metadata,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                ...state.visibleEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: _NotebookEntryCard(
                      entry: entry,
                      isRemoving: state.removingEntryKeys.contains(
                        entry.routeKey,
                      ),
                      onOpen: () => widget.onOpenEntry(entry),
                      onRemove: () => widget.onRemoveEntry(entry),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.collectionCount,
    required this.entryCount,
  });

  final int collectionCount;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.learnerOutline,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.learnerPrimaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.collections_bookmark_outlined,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.savedItemCount(entryCount),
                  style: AppTypography.sectionTitle,
                ),
                Text(
                  context.l10n.personalCollectionCount(collectionCount),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookEntryCard extends StatelessWidget {
  const _NotebookEntryCard({
    required this.entry,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
  });

  final NotebookEntry entry;
  final bool isRemoving;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onOpen != null,
      label: onOpen == null ? null : context.l10n.openWordDetail(entry.term),
      child: InkWell(
        key: ValueKey<String>('notebook_entry_${entry.routeKey}'),
        onTap: isRemoving ? null : onOpen,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.reading != null)
                          Text(
                            entry.reading!,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(
                          entry.term,
                          style: AppTypography.compactPageTitle.copyWith(
                            color: AppColors.learnerTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRemoving)
                    const SizedBox.square(
                      dimension: 40,
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.space2),
                        child: RikiInlineLoader(
                          key: ValueKey<String>('notebook_remove_progress'),
                          size: 18,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      key: ValueKey<String>(
                        'notebook_remove_${entry.routeKey}',
                      ),
                      tooltip: context.l10n.removeFromNotebook,
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(entry.meaning, style: AppTypography.body),
              if (entry.note != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space2),
                  decoration: BoxDecoration(
                    color: AppColors.learnerSurfaceLow,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Text(entry.note!, style: AppTypography.bodySmall),
                ),
              ],
              const SizedBox(height: AppSpacing.space3),
              Row(
                children: [
                  _ContentTypeBadge(entry.contentType),
                  const Spacer(),
                  if (onOpen != null) ...[
                    Text(
                      context.l10n.detail,
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.brandPrimary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentTypeBadge extends StatelessWidget {
  const _ContentTypeBadge(this.type);

  final NotebookContentType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      NotebookContentType.vocabulary => context.l10n.vocabulary,
      NotebookContentType.kanji => context.l10n.notebookKanjiLabel,
      NotebookContentType.grammar => context.l10n.grammar,
      NotebookContentType.manual => context.l10n.personalWord,
      NotebookContentType.unknown => context.l10n.savedItem,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(color: AppColors.brandPrimary),
      ),
    );
  }
}

class _EmptyNotebook extends StatelessWidget {
  const _EmptyNotebook({required this.onCreateCollection});

  final VoidCallback onCreateCollection;

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(
      key: const ValueKey<String>('notebook_empty_view'),
      icon: Icons.collections_bookmark_outlined,
      title: context.l10n.notebookEmptyTitle,
      message: context.l10n.notebookEmptyMessage,
      actionLabel: context.l10n.createCollectionAction,
      onAction: onCreateCollection,
      actionKey: const ValueKey<String>(
        'notebook_empty_create_collection_button',
      ),
    );
  }
}

class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries({
    required this.hasQuery,
    required this.onClear,
    required this.onAddEntry,
  });

  final bool hasQuery;
  final VoidCallback onClear;
  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context) {
    return RikiEmptyState(
      key: ValueKey<String>(
        hasQuery ? 'notebook_search_empty_view' : 'notebook_entries_empty_view',
      ),
      icon: hasQuery ? Icons.search_off_outlined : Icons.bookmark_border,
      title: hasQuery
          ? context.l10n.noMatchingWord
          : context.l10n.collectionHasNoWords,
      message: hasQuery
          ? context.l10n.notebookSearchEmptyMessage
          : context.l10n.notebookCollectionEmptyMessage,
      actionLabel: hasQuery
          ? context.l10n.clearSearch
          : context.l10n.addNewWord,
      onAction: hasQuery ? onClear : onAddEntry,
      actionKey: ValueKey<String>(
        hasQuery ? 'notebook_clear_search_button' : 'notebook_empty_add_button',
      ),
      compact: true,
    );
  }
}

class _EntriesError extends StatelessWidget {
  const _EntriesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      key: const ValueKey<String>('notebook_entries_error'),
      borderColor: AppColors.brandBorder,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        children: [
          Text(
            message,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onDismiss,
    super.key,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorText),
          const SizedBox(width: AppSpacing.space2),
          Expanded(child: Text(message, style: AppTypography.validationText)),
          IconButton(
            tooltip: context.l10n.close,
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
