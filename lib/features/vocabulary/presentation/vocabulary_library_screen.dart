import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/vocabulary/application/vocabulary_controller.dart';
import 'package:rikipath_mobile/features/vocabulary/domain/vocabulary.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/widgets/vocabulary_library_view.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/widgets/vocabulary_state_views.dart';

class VocabularyLibraryScreen extends ConsumerWidget {
  const VocabularyLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vocabularyLibraryControllerProvider);
    final controller = ref.read(vocabularyLibraryControllerProvider.notifier);
    final savedKeys = ref.watch(savedVocabularyKeysProvider).value;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.vocabulary,
        subtitle: context.l10n.library,
        level: state.value?.query.level,
        initials: null,
        onBack: context.pop,
        onProfilePressed: () => context.go(AppRoutes.profile),
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: VocabularyLoadingView.new,
          error: (_, _) => VocabularyErrorView(onRetry: controller.retry),
          data: (data) => VocabularyLibraryView(
            state: data,
            savedVocabularyKeys: savedKeys ?? const <String>{},
            onSearch: controller.search,
            onFilter: controller.filterByLevel,
            onClear: controller.clear,
            onOpenDetail: (entry) =>
                context.push(AppRoutes.vocabularyDetail(entry.routeKey)),
            onPlayAudio: (entry) => _playAudio(context, ref, entry),
            onLoadMore: controller.loadNextPage,
          ),
        ),
      ),
    );
  }

  Future<void> _playAudio(
    BuildContext context,
    WidgetRef ref,
    VocabularyEntry entry,
  ) async {
    final source = entry.audioUrl;
    if (source == null) return;
    try {
      await ref.read(vocabularyAudioPlayerProvider).play(source);
    } catch (_) {
      if (!context.mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: context.l10n.toastAudioFailedTitle,
            description: context.l10n.vocabularyAudioFailed,
          );
    }
  }
}
