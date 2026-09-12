import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
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
        title: _title(session),
        subtitle: _subtitle(session),
        level: session?.lesson.level,
        initials: null,
        onBack: () => _handleBack(context, controller, session),
        onProfilePressed: () => context.go(AppRoutes.profile),
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
      ),
      LessonStage.article => LessonArticleOnlyView(
        lesson: lesson,
        onOpenVideo: controller.showVideo,
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

  String _title(LessonSession? session) {
    if (session == null) {
      return 'Bài học';
    }
    if (session.stage == LessonStage.completed) {
      return 'Hoàn thành bài học';
    }
    return 'Bài ${session.lesson.lessonNumber}';
  }

  String _subtitle(LessonSession? session) {
    if (session == null) {
      return 'Đang tải nội dung';
    }
    if (session.stage == LessonStage.video ||
        session.stage == LessonStage.article) {
      return '${session.lesson.curriculum} • ${session.lesson.focus}';
    }
    return 'Chương ${session.lesson.chapterNumber} • '
        '${session.lesson.category} ${session.lesson.level.label}';
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
