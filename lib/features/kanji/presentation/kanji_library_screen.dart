import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/kanji/application/kanji_controller.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';
import 'package:rikipath_mobile/features/kanji/presentation/widgets/kanji_library_view.dart';
import 'package:rikipath_mobile/features/kanji/presentation/widgets/kanji_state_views.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';

class KanjiLibraryScreen extends ConsumerStatefulWidget {
  const KanjiLibraryScreen({super.key});

  @override
  ConsumerState<KanjiLibraryScreen> createState() => _KanjiLibraryScreenState();
}

class _KanjiLibraryScreenState extends ConsumerState<KanjiLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kanjiLibraryControllerProvider);
    final controller = ref.read(kanjiLibraryControllerProvider.notifier);
    final catalog = ref.watch(jlptCatalogControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.skillKanji,
        subtitle: context.l10n.library,
        onBack: context.pop,
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: KanjiLoadingView.new,
          error: (_, _) => KanjiErrorView(onRetry: controller.retry),
          data: (data) => KanjiLibraryView(
            state: data,
            catalog: catalog,
            searchController: _searchController,
            onSearch: controller.search,
            onFilter: controller.filterByLevel,
            onRetryCatalog: ref
                .read(jlptCatalogControllerProvider.notifier)
                .retry,
            onClear: () {
              _searchController.clear();
              controller.clear();
            },
            onOpenDetail: (entry) =>
                context.push(AppRoutes.kanjiDetail(entry.routeKey)),
            onPlayAudio: (entry) => _playAudio(context, entry),
            onLoadMore: controller.loadNextPage,
          ),
        ),
      ),
    );
  }

  Future<void> _playAudio(BuildContext context, KanjiEntry entry) async {
    final source = entry.audioUrl;
    if (source == null) return;
    try {
      await ref.read(kanjiAudioPlayerProvider).play(source);
    } catch (_) {
      if (!context.mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: context.l10n.toastAudioFailedTitle,
            description: context.l10n.kanjiAudioFailed,
          );
    }
  }
}
