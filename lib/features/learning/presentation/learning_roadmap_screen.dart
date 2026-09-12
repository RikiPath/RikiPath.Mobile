import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_roadmap_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_state_views.dart';

class LearningRoadmapScreen extends ConsumerWidget {
  const LearningRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningState = ref.watch(learningControllerProvider);
    final snapshot = learningState.asData?.value;
    final levelSuffix = snapshot == null ? '' : ' ${snapshot.jlptTarget.label}';
    final subtitle = snapshot == null
        ? 'Đang tải lộ trình'
        : '${snapshot.totalChapters} chương • ${snapshot.totalLessons} bài học';

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: 'Lộ trình JLPT$levelSuffix',
        subtitle: subtitle,
        level: snapshot?.jlptTarget,
        initials: snapshot?.initials,
        onBack: () => _goBack(context),
        onProfilePressed: () => context.go(AppRoutes.profile),
      ),
      body: SafeArea(
        top: false,
        child: learningState.when(
          loading: () => const LearningLoadingView(),
          error: (_, _) => LearningErrorView(
            onRetry: ref.read(learningControllerProvider.notifier).retry,
          ),
          data: (data) => LearningRoadmapView(
            snapshot: data,
            onOpenProgress: () => context.push(AppRoutes.learnProgress),
          ),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.learn);
  }
}
