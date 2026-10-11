import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

/// Notes-style Notebook home. This surface intentionally presents collections
/// only; words belong to [NotebookCollectionView].
class NotebookView extends StatefulWidget {
  const NotebookView({
    required this.state,
    required this.onCreateCollection,
    required this.onOpenCollection,
    required this.onDismissMutationError,
    super.key,
  });

  final NotebookLibraryState state;
  final VoidCallback onCreateCollection;
  final ValueChanged<NotebookCollection> onOpenCollection;
  final VoidCallback onDismissMutationError;

  @override
  State<NotebookView> createState() => _NotebookViewState();
}

class _NotebookViewState extends State<NotebookView> {
  final _searchController = TextEditingController();
  String _query = '';

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

    final normalizedQuery = _query.trim().toLowerCase();
    final visibleCollections = normalizedQuery.isEmpty
        ? state.collections
        : state.collections
              .where((collection) {
                return <String?>[
                  collection.name,
                  collection.description,
                ].whereType<String>().any(
                  (value) => value.toLowerCase().contains(normalizedQuery),
                );
              })
              .toList(growable: false);

    return Column(
      children: [
        if (state.isCreatingCollection)
          RikiProgressIndicator(
            key: const ValueKey<String>('notebook_mutation_progress'),
            semanticsLabel: context.l10n.processingSemantics,
          ),
        Expanded(
          child: ListView(
            key: const ValueKey<String>('notebook_content'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              const SizedBox(height: AppSpacing.space5),
              Text(
                context.l10n.yourCollections,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space3),
              TextField(
                key: const ValueKey<String>('notebook_collection_search_field'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: context.l10n.collectionSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.l10n.clearSearch,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              SizedBox(
                width: double.infinity,
                child: RikiSecondaryButton(
                  key: const ValueKey<String>(
                    'notebook_create_collection_button',
                  ),
                  label: context.l10n.createCollection,
                  leadingIcon: Icons.add,
                  onPressed: state.isCreatingCollection
                      ? null
                      : widget.onCreateCollection,
                ),
              ),
              if (state.mutationError != null) ...[
                const SizedBox(height: AppSpacing.space3),
                NotebookInlineError(
                  key: const ValueKey<String>('notebook_mutation_error'),
                  message: state.mutationError!,
                  onDismiss: widget.onDismissMutationError,
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              if (visibleCollections.isEmpty)
                RikiEmptyState(
                  key: const ValueKey<String>(
                    'notebook_collection_search_empty_view',
                  ),
                  icon: Icons.folder_off_outlined,
                  title: context.l10n.noMatchingCollection,
                  message: context.l10n.collectionSearchEmptyMessage,
                  actionLabel: context.l10n.clearSearch,
                  onAction: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  compact: true,
                )
              else
                ListView.separated(
                  key: const ValueKey<String>('notebook_collection_list'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleCollections.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space3),
                  itemBuilder: (context, index) {
                    final collection = visibleCollections[index];
                    return _CollectionCard(
                      collection: collection,
                      onTap: () => widget.onOpenCollection(collection),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class NotebookCollectionView extends StatefulWidget {
  const NotebookCollectionView({
    required this.state,
    required this.collection,
    required this.onSearch,
    required this.onClearSearch,
    required this.onRetryEntries,
    required this.onDismissMutationError,
    required this.onDismissEntriesError,
    required this.onAddEntry,
    required this.onOpenEntry,
    required this.onRemoveEntry,
    super.key,
  });

  final NotebookLibraryState state;
  final NotebookCollection collection;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onRetryEntries;
  final VoidCallback onDismissMutationError;
  final VoidCallback onDismissEntriesError;
  final VoidCallback onAddEntry;
  final ValueChanged<NotebookEntry> onOpenEntry;
  final ValueChanged<NotebookEntry> onRemoveEntry;

  @override
  State<NotebookCollectionView> createState() => _NotebookCollectionViewState();
}

class _NotebookCollectionViewState extends State<NotebookCollectionView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.query);
  }

  @override
  void didUpdateWidget(covariant NotebookCollectionView oldWidget) {
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
    final isSelected =
        state.selectedCollectionKey == widget.collection.routeKey;
    final canAdd = isSelected && state.canAddManualEntry;

    return Column(
      children: [
        if (state.isAddingEntry)
          RikiProgressIndicator(
            key: const ValueKey<String>('notebook_mutation_progress'),
            semanticsLabel: context.l10n.processingSemantics,
          ),
        Expanded(
          child: ListView(
            key: const ValueKey<String>('notebook_collection_content'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            children: [
              _CollectionSummary(collection: widget.collection),
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
                  if (canAdd) ...[
                    const SizedBox(width: AppSpacing.space2),
                    IconButton.filled(
                      key: const ValueKey<String>('notebook_add_entry_button'),
                      tooltip: context.l10n.addNewWord,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.brandPrimaryDisabled,
                        disabledForegroundColor: Colors.white,
                      ),
                      onPressed: state.isAddingEntry ? null : widget.onAddEntry,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ],
              ),
              if (state.mutationError != null) ...[
                const SizedBox(height: AppSpacing.space3),
                NotebookInlineError(
                  key: const ValueKey<String>('notebook_mutation_error'),
                  message: state.mutationError!,
                  onDismiss: widget.onDismissMutationError,
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              if (!isSelected || state.isLoadingEntries)
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
                  onRetry: widget.onRetryEntries,
                )
              else if (state.visibleEntries.isEmpty)
                _EmptyEntries(
                  hasQuery: state.query.isNotEmpty,
                  canAddEntry: canAdd,
                  onClear: widget.onClearSearch,
                  onAddEntry: widget.onAddEntry,
                )
              else ...[
                if (state.entriesError != null) ...[
                  NotebookInlineError(
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
                    child: NotebookEntryCard(
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

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.onTap});

  final NotebookCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.openCollection(collection.name),
      child: RikiCard(
        key: ValueKey<String>('notebook_collection_${collection.routeKey}'),
        onTap: onTap,
        borderColor: AppColors.learnerOutline,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: collection.source == NotebookDataSource.fixture
                    ? AppColors.successBackgroundSoft
                    : AppColors.brandTint,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Icon(
                collection.source == NotebookDataSource.fixture
                    ? Icons.auto_stories_outlined
                    : Icons.folder_outlined,
                color: collection.source == NotebookDataSource.fixture
                    ? AppColors.success
                    : AppColors.brandPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    collection.description?.trim().isNotEmpty == true
                        ? collection.description!
                        : context.l10n.itemCount(collection.entryCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                  if (collection.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      context.l10n.itemCount(collection.entryCount),
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space2),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.collection});

  final NotebookCollection collection;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.learnerOutline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              color: AppColors.brandPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.itemCount(collection.entryCount),
                  style: AppTypography.cardTitle,
                ),
                if (collection.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(collection.description!, style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
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

class NotebookEntryCard extends StatelessWidget {
  const NotebookEntryCard({
    required this.entry,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
    super.key,
  });

  final NotebookEntry entry;
  final bool isRemoving;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.openWordDetail(entry.term),
      child: RikiCard(
        key: ValueKey<String>('notebook_entry_${entry.routeKey}'),
        onTap: isRemoving ? null : onOpen,
        borderColor: AppColors.learnerOutline,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Text(
                entry.term.characters.firstOrNull ?? '文',
                style: AppTypography.cardTitle.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.term,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle,
                        ),
                      ),
                      if (entry.reading != null) ...[
                        const SizedBox(width: AppSpacing.space2),
                        Flexible(
                          child: Text(
                            entry.reading!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    entry.meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  NotebookContentTypeBadge(type: entry.contentType),
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
                key: ValueKey<String>('notebook_remove_${entry.routeKey}'),
                tooltip: context.l10n.removeFromNotebook,
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class NotebookContentTypeBadge extends StatelessWidget {
  const NotebookContentTypeBadge({required this.type, super.key});

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
    final tone = switch (type) {
      NotebookContentType.vocabulary => AppFeatureTones.brand,
      NotebookContentType.kanji => AppFeatureTones.learning,
      NotebookContentType.grammar => AppFeatureTones.review,
      NotebookContentType.manual => AppFeatureTones.ai,
      NotebookContentType.unknown => AppFeatureTones.neutral,
    };
    return RikiStatusPill(label: label, tone: tone);
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
      actionIcon: Icons.add,
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
    required this.canAddEntry,
    required this.onClear,
    required this.onAddEntry,
  });

  final bool hasQuery;
  final bool canAddEntry;
  final VoidCallback onClear;
  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context) {
    final showAction = hasQuery || canAddEntry;
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
      actionLabel: showAction
          ? (hasQuery ? context.l10n.clearSearch : context.l10n.addNewWord)
          : null,
      actionIcon: hasQuery ? null : Icons.add,
      onAction: showAction ? (hasQuery ? onClear : onAddEntry) : null,
      actionKey: showAction
          ? ValueKey<String>(
              hasQuery
                  ? 'notebook_clear_search_button'
                  : 'notebook_empty_add_button',
            )
          : null,
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

class NotebookInlineError extends StatelessWidget {
  const NotebookInlineError({
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
