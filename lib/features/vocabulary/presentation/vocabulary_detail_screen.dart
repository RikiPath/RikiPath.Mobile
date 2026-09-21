import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/vocabulary/application/vocabulary_controller.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/widgets/vocabulary_detail_view.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/widgets/vocabulary_state_views.dart';

class VocabularyDetailScreen extends ConsumerWidget {
  const VocabularyDetailScreen({required this.routeKey, super.key});

  final String routeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = vocabularyDetailControllerProvider(routeKey);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final entry = state.value?.entry;
    final savedKeys = ref.watch(savedVocabularyKeysProvider).value;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.vocabularyDetail,
        subtitle: entry?.reading ?? context.l10n.library,
        level: entry?.level,
        initials: null,
        onBack: context.pop,
        onProfilePressed: () => context.go(AppRoutes.profile),
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: VocabularyLoadingView.new,
          error: (_, _) => VocabularyErrorView(onRetry: controller.retry),
          data: (data) => VocabularyDetailView(
            state: data,
            isSaved: savedKeys?.contains(data.entry.routeKey) ?? false,
            onPlayAudio: controller.playAudio,
            onSave: () => _chooseNotebookList(context, ref, controller),
            onOpenLesson: (lesson) =>
                context.push(AppRoutes.lesson(lesson.routeId)),
          ),
        ),
      ),
    );
  }

  Future<void> _chooseNotebookList(
    BuildContext context,
    WidgetRef ref,
    VocabularyDetailController controller,
  ) async {
    final lists = await controller.loadNotebookLists();
    if (!context.mounted || lists.isEmpty) return;

    final selected = await showModalBottomSheet<NotebookCollection>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSpacing.space4),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                0,
                AppSpacing.space4,
                AppSpacing.space2,
              ),
              child: Text(
                context.l10n.chooseNotebook,
                style: AppTypography.sectionTitle,
              ),
            ),
            for (final list in lists)
              ListTile(
                key: ValueKey<String>('vocabulary_notebook_${list.routeKey}'),
                leading: const Icon(Icons.book_outlined),
                title: Text(list.name),
                subtitle: Text(context.l10n.wordCount(list.entryCount)),
                onTap: () => Navigator.of(context).pop(list),
              ),
          ],
        ),
      ),
    );

    if (selected == null) return;
    final saved = await controller.saveToNotebook(selected);
    if (!context.mounted || !saved) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .success(title: context.l10n.savedToCollection(selected.name));
  }
}
