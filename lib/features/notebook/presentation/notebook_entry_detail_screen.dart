import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/notebook/application/demo_notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

class NotebookEntryDetailScreen extends ConsumerWidget {
  const NotebookEntryDetailScreen({required this.entryKey, super.key});

  final String entryKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = NotebookEntryKey.tryParse(entryKey);
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.notebookEntryTitle)),
      body: key == null
          ? _Unavailable(message: context.l10n.notebookEntryUnavailable)
          : key.origin == NotebookItemOrigin.fixture
          ? _fixtureBody(context, ref, key)
          : _liveBody(context, ref, key),
    );
  }

  Widget _fixtureBody(
    BuildContext context,
    WidgetRef ref,
    NotebookEntryKey key,
  ) {
    final local = ref.watch(demoNotebookControllerProvider);
    return local.when(
      loading: () => const Center(child: RikiInlineLoader()),
      error: (_, _) =>
          _Unavailable(message: context.l10n.notebookEntryUnavailable),
      data: (data) {
        final entry = data.entries
            .where((candidate) => candidate.key == key)
            .firstOrNull;
        if (entry == null) {
          return _Unavailable(message: context.l10n.notebookEntryUnavailable);
        }
        return _EntryDetail(
          entry: entry,
          onRemove: () => _removeFixture(context, ref, entry),
        );
      },
    );
  }

  Widget _liveBody(BuildContext context, WidgetRef ref, NotebookEntryKey key) {
    final notebook = ref.watch(notebookControllerProvider);
    return notebook.when(
      loading: () => const Center(child: RikiInlineLoader()),
      error: (_, _) =>
          _Unavailable(message: context.l10n.notebookEntryUnavailable),
      data: (data) {
        final entry = data.liveEntries
            .where((candidate) => candidate.key == key)
            .firstOrNull;
        if (entry == null) {
          return _Unavailable(message: context.l10n.notebookEntryUnavailable);
        }
        return _EntryDetail(
          entry: entry,
          onRemove: () => _removeLive(context, ref, entry),
        );
      },
    );
  }

  Future<void> _removeFixture(
    BuildContext context,
    WidgetRef ref,
    NotebookEntry entry,
  ) async {
    if (!await _confirmRemove(context, entry) || !context.mounted) return;
    await ref.read(demoNotebookControllerProvider.notifier).removeEntry(entry);
    final state = await ref.read(demoNotebookControllerProvider.future);
    if (!context.mounted ||
        state.entries.any((candidate) => candidate.key == entry.key)) {
      return;
    }
    context.pop();
  }

  Future<void> _removeLive(
    BuildContext context,
    WidgetRef ref,
    NotebookEntry entry,
  ) async {
    if (!await _confirmRemove(context, entry) || !context.mounted) return;
    final removed = await ref
        .read(notebookControllerProvider.notifier)
        .removeEntry(entry);
    if (removed && context.mounted) context.pop();
  }

  Future<bool> _confirmRemove(BuildContext context, NotebookEntry entry) async {
    return showRikiConfirmationDialog(
      context: context,
      title: context.l10n.removeFromNotebookQuestion,
      message: context.l10n.removeEntryMessage(entry.term),
      confirmLabel: context.l10n.delete,
      cancelLabel: context.l10n.cancel,
      icon: Icons.bookmark_remove_outlined,
      destructive: true,
    );
  }
}

class _EntryDetail extends StatelessWidget {
  const _EntryDetail({required this.entry, required this.onRemove});

  final NotebookEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('notebook_entry_detail_view'),
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        RikiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.term,
                style: AppTypography.heroTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              if (entry.reading != null) ...[
                const SizedBox(height: AppSpacing.space1),
                Text(
                  entry.reading!,
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              Text(entry.meaning, style: AppTypography.sectionTitle),
              if (entry.note != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(entry.note!, style: AppTypography.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        OutlinedButton.icon(
          key: const ValueKey<String>('notebook_detail_remove_button'),
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
          label: Text(context.l10n.removeFromNotebook),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('notebook_entry_unavailable'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Text(
          message,
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
