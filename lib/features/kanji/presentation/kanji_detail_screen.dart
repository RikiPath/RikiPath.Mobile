import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/kanji/application/kanji_controller.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/presentation/widgets/kanji_detail_view.dart';
import 'package:rikipath_mobile/features/kanji/presentation/widgets/kanji_state_views.dart';
import 'package:rikipath_mobile/features/kanji/presentation/widgets/kanji_stroke_order_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';

class KanjiDetailScreen extends ConsumerWidget {
  const KanjiDetailScreen({required this.routeKey, super.key});

  final String routeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = kanjiDetailControllerProvider(routeKey);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final data = state.value;
    final entry = data?.entry;
    final showingStrokes = data?.showStrokeOrder ?? false;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: showingStrokes
            ? context.l10n.strokeOrder
            : context.l10n.kanjiDetail,
        subtitle: entry == null
            ? context.l10n.library
            : '${entry.character} • ${entry.sinoVietnamese ?? entry.meaning}',
        onBack: showingStrokes
            ? controller.closeStrokeOrder
            : () => context.pop(),
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: KanjiLoadingView.new,
          error: (_, _) => KanjiErrorView(onRetry: controller.retry),
          data: (detail) => detail.showStrokeOrder
              ? KanjiStrokeOrderView(
                  state: detail,
                  onClose: controller.closeStrokeOrder,
                  onSelectStroke: controller.selectStroke,
                  onPrevious: controller.previousStroke,
                  onNext: controller.nextStroke,
                  onRestart: controller.restartStrokeOrder,
                )
              : KanjiDetailView(
                  state: detail,
                  onPlayAudio: controller.playAudio,
                  onSave: () => _chooseNotebookList(context, ref, controller),
                  onOpenStrokeOrder: controller.openStrokeOrder,
                ),
        ),
      ),
    );
  }

  Future<void> _chooseNotebookList(
    BuildContext context,
    WidgetRef ref,
    KanjiDetailController controller,
  ) async {
    final lists = await controller.loadNotebookLists();
    if (!context.mounted || lists.isEmpty) return;

    final selected = await showModalBottomSheet<KanjiNotebookList>(
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
                key: ValueKey<String>('kanji_notebook_${list.id}'),
                leading: const Icon(Icons.book_outlined),
                title: Text(list.name),
                subtitle: Text(context.l10n.itemCount(list.entryCount)),
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
