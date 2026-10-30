import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_session.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_completion_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_content_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_detail_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_locked_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_state_views.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_video_view.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonState = ref.watch(lessonControllerProvider(lessonId));
    final session = lessonState.value;
    final controller = ref.read(lessonControllerProvider(lessonId).notifier);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: _title(context, session),
        subtitle: _subtitle(context, session),
        onBack: () => _handleBack(context, controller, session),
      ),
      body: SafeArea(
        top: false,
        child: lessonState.when(
          loading: () => const LessonLoadingView(),
          error: (_, _) => LessonLoadErrorView(onRetry: controller.retry),
          data: (data) => _body(context, ref, controller, data),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    LessonController controller,
    LessonSession session,
  ) {
    final lesson = session.lesson;
    if (lesson.availability == LessonAvailability.locked) {
      return LessonLockedView(
        lesson: lesson,
        onContinuePrerequisite: lesson.prerequisite == null
            ? null
            : () => context.go(AppRoutes.lesson(lesson.prerequisite!.routeId)),
        onBackToRoadmap: () => context.go(AppRoutes.learnRoadmap),
      );
    }

    return switch (session.stage) {
      LessonStage.detail => LessonDetailView(
        lesson: lesson,
        onStart: controller.openVideo,
        onToggleBookmark: (index) {
          _bookmarkVocabulary(context, ref, controller, lesson, index);
        },
        onToggleKanji: (index) {
          _bookmarkKanji(context, ref, controller, lesson, index);
        },
        onToggleGrammar: (index) {
          _bookmarkGrammar(context, ref, controller, lesson, index);
        },
      ),
      LessonStage.video => LessonVideoView(
        session: session,
        videoController: ref
            .watch(lessonMediaDriverProvider(lessonId))
            .videoController,
        onTogglePlayback: controller.togglePlayback,
        onRetry: controller.openVideo,
        onShowArticle: controller.showArticle,
        onSelectTab: controller.selectTab,
        onComplete: controller.completeLesson,
        onToggleBookmark: (index) {
          _bookmarkVocabulary(context, ref, controller, lesson, index);
        },
      ),
      LessonStage.article => LessonArticleOnlyView(
        lesson: lesson,
        onOpenVideo: controller.showVideo,
        onToggleBookmark: (index) {
          _bookmarkVocabulary(context, ref, controller, lesson, index);
        },
        onToggleKanji: (index) {
          _bookmarkKanji(context, ref, controller, lesson, index);
        },
        onToggleGrammar: (index) {
          _bookmarkGrammar(context, ref, controller, lesson, index);
        },
        onComplete: controller.completeLesson,
        isCompleting: session.isCompleting,
        completionErrorMessage: session.completionErrorMessage,
      ),
      LessonStage.completed => LessonCompletionView(
        lesson: lesson,
        onNextLesson: lesson.nextLesson == null
            ? null
            : () => context.go(AppRoutes.lesson(lesson.nextLesson!.routeId)),
        onBackToRoadmap: () => context.go(AppRoutes.learnRoadmap),
      ),
    };
  }

  Future<void> _bookmarkVocabulary(
    BuildContext context,
    WidgetRef ref,
    LessonController controller,
    Lesson lesson,
    int index,
  ) async {
    if (lesson.remoteLessonId == null) {
      await controller.toggleFixtureVocabulary(index);
      return;
    }
    if (lesson.vocabulary[index].isSaved) return;
    final collection = await _selectLiveCollection(context, ref);
    if (collection == null) return;
    final saved = await controller.saveLiveVocabulary(index, collection);
    if (!context.mounted) return;
    _notifyBookmark(context, ref, saved, collection.name);
  }

  Future<void> _bookmarkKanji(
    BuildContext context,
    WidgetRef ref,
    LessonController controller,
    Lesson lesson,
    int index,
  ) async {
    if (lesson.kanji[index].isSaved) return;
    final collection = await _selectLiveCollection(context, ref);
    if (collection == null) return;
    final saved = await controller.saveLiveKanji(index, collection);
    if (!context.mounted) return;
    _notifyBookmark(context, ref, saved, collection.name);
  }

  Future<void> _bookmarkGrammar(
    BuildContext context,
    WidgetRef ref,
    LessonController controller,
    Lesson lesson,
    int index,
  ) async {
    if (lesson.remoteLessonId == null) {
      await controller.toggleFixtureGrammar(index);
      return;
    }
    if (lesson.relatedGrammar[index].isSaved) return;
    final saved = await controller.saveLiveGrammar(index);
    if (!context.mounted) return;
    final toast = ref.read(rikiToastServiceProvider.notifier);
    if (saved) {
      toast.success(title: context.l10n.saved);
    } else {
      toast.error(
        title: context.l10n.toastActionFailedTitle,
        description: context.l10n.checkConnectionRetry,
      );
    }
  }

  Future<NotebookCollection?> _selectLiveCollection(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final collections = await ref
          .read(notebookRepositoryProvider)
          .loadCollections();
      final live = collections
          .where((collection) => collection.isLive)
          .toList();
      if (!context.mounted) return null;
      if (live.isEmpty) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: context.l10n.toastActionFailedTitle,
              description: context.l10n.notebookEmptyMessage,
            );
        return null;
      }
      return await showModalBottomSheet<NotebookCollection>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppSpacing.space4),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Text(
                  context.l10n.saveToNotebook,
                  style: AppTypography.sectionTitle,
                ),
              ),
              for (final collection in live)
                ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(collection.name),
                  subtitle: Text('${collection.entryCount}'),
                  onTap: () => Navigator.of(sheetContext).pop(collection),
                ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .error(
              title: context.l10n.toastActionFailedTitle,
              description: context.l10n.notebookListsLoadFailed,
            );
      }
      return null;
    }
  }

  void _notifyBookmark(
    BuildContext context,
    WidgetRef ref,
    bool saved,
    String collectionName,
  ) {
    final toast = ref.read(rikiToastServiceProvider.notifier);
    if (saved) {
      toast.success(title: context.l10n.savedToCollection(collectionName));
    } else {
      toast.error(
        title: context.l10n.toastActionFailedTitle,
        description: context.l10n.checkConnectionRetry,
      );
    }
  }

  String _title(BuildContext context, LessonSession? session) {
    if (session == null) {
      return context.l10n.lesson;
    }
    if (session.stage == LessonStage.completed) {
      return context.l10n.completeLesson;
    }
    return context.l10n.lessonNumber(session.lesson.lessonNumber);
  }

  String _subtitle(BuildContext context, LessonSession? session) {
    if (session == null) {
      return context.l10n.loadingContent;
    }
    if (session.stage == LessonStage.video ||
        session.stage == LessonStage.article) {
      return '${session.lesson.curriculum} • ${session.lesson.focus}';
    }
    return session.lesson.chapterNumber > 0
        ? context.l10n.chapterLessonSummary(
            session.lesson.chapterNumber,
            session.lesson.category,
            session.lesson.level.label,
          )
        : '${session.lesson.category} • ${session.lesson.level.label}';
  }

  void _handleBack(
    BuildContext context,
    LessonController controller,
    LessonSession? session,
  ) {
    if (session != null &&
        session.lesson.availability == LessonAvailability.available &&
        (session.stage == LessonStage.video ||
            session.stage == LessonStage.article)) {
      controller.showDetail();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.learnRoadmap);
  }
}
