import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/presentation/widgets/notebook_state_views.dart';
import 'package:rikipath_mobile/features/notebook/presentation/widgets/notebook_view.dart';

class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notebookControllerProvider);
    final controller = ref.read(notebookControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.navigationNotebook),
        actions: [
          IconButton(
            tooltip: context.l10n.navigationProfile,
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: NotebookLoadingView.new,
          error: (_, _) => NotebookErrorView(onRetry: controller.retry),
          data: (data) => NotebookView(
            state: data,
            onSearch: controller.search,
            onClearSearch: controller.clearSearch,
            onSelectCollection: controller.selectCollection,
            onRetry: controller.retry,
            onDismissMutationError: controller.clearMutationError,
            onCreateCollection: () =>
                _createCollection(context, ref, controller),
            onAddEntry: () => _addManualEntry(context, ref, controller),
            onOpenVocabulary: (entry) {
              final routeKey = entry.vocabularyRouteKey;
              if (routeKey != null) {
                context.push(AppRoutes.notebookVocabularyDetail(routeKey));
              }
            },
            onRemoveEntry: (entry) =>
                _confirmRemove(context, ref, controller, entry),
          ),
        ),
      ),
    );
  }

  Future<void> _createCollection(
    BuildContext context,
    WidgetRef ref,
    NotebookController controller,
  ) async {
    final request = await showModalBottomSheet<_CreateCollectionRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateCollectionSheet(),
    );
    if (request == null || !context.mounted) return;
    final success = await controller.createCollection(
      name: request.name,
      description: request.description,
    );
    if (!context.mounted || !success) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .success(title: context.l10n.collectionCreated);
  }

  Future<void> _addManualEntry(
    BuildContext context,
    WidgetRef ref,
    NotebookController controller,
  ) async {
    final request = await showModalBottomSheet<_ManualEntryRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ManualEntrySheet(),
    );
    if (request == null || !context.mounted) return;
    final success = await controller.addManualEntry(
      word: request.word,
      reading: request.reading,
      meaning: request.meaning,
      note: request.note,
    );
    if (!context.mounted || !success) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .success(title: context.l10n.wordAddedToNotebook);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    NotebookController controller,
    NotebookEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.removeFromNotebookQuestion),
        content: Text(context.l10n.removeEntryMessage(entry.term)),
        actions: [
          TextButton(
            key: const ValueKey<String>('notebook_cancel_remove_button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey<String>('notebook_confirm_remove_button'),
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final removed = await controller.removeEntry(entry);
    if (!context.mounted || !removed) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .success(title: context.l10n.removedFromNotebook);
  }
}

class _CreateCollectionRequest {
  const _CreateCollectionRequest({required this.name, this.description});

  final String name;
  final String? description;
}

class _CreateCollectionSheet extends StatefulWidget {
  const _CreateCollectionSheet();

  @override
  State<_CreateCollectionSheet> createState() => _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends State<_CreateCollectionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space4,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.createCollection,
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              key: const ValueKey<String>('notebook_collection_name_field'),
              controller: _nameController,
              autofocus: true,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: context.l10n.collectionNameRequiredLabel,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.l10n.collectionNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.space2),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.optionalDescription,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            FilledButton(
              key: const ValueKey<String>('notebook_create_collection_submit'),
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.of(context).pop(
                  _CreateCollectionRequest(
                    name: _nameController.text,
                    description: _descriptionController.text,
                  ),
                );
              },
              child: Text(context.l10n.createCollectionAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualEntryRequest {
  const _ManualEntryRequest({
    required this.word,
    required this.meaning,
    this.reading,
    this.note,
  });

  final String word;
  final String? reading;
  final String meaning;
  final String? note;
}

class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet();

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _readingController = TextEditingController();
  final _meaningController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _wordController.dispose();
    _readingController.dispose();
    _meaningController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.space4,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.addNewWord, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.space1),
            Text(
              context.l10n.notebookApiFieldsHint,
              style: AppTypography.metadata,
            ),
            const SizedBox(height: AppSpacing.space4),
            TextFormField(
              key: const ValueKey<String>('notebook_manual_word_field'),
              controller: _wordController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.japaneseWordRequiredLabel,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.l10n.wordRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              key: const ValueKey<String>('notebook_manual_reading_field'),
              controller: _readingController,
              decoration: InputDecoration(
                labelText: context.l10n.optionalReading,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              key: const ValueKey<String>('notebook_manual_meaning_field'),
              controller: _meaningController,
              decoration: InputDecoration(
                labelText: context.l10n.meaningRequiredLabel,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.l10n.meaningRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              key: const ValueKey<String>('notebook_manual_note_field'),
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.optionalPersonalNote,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            FilledButton.icon(
              key: const ValueKey<String>('notebook_manual_submit_button'),
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.of(context).pop(
                  _ManualEntryRequest(
                    word: _wordController.text,
                    reading: _readingController.text,
                    meaning: _meaningController.text,
                    note: _noteController.text,
                  ),
                );
              },
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(context.l10n.saveToNotebook),
            ),
          ],
        ),
      ),
    );
  }
}
