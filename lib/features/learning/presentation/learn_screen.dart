import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_home_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_state_views.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningState = ref.watch(learningControllerProvider);
    final snapshot = learningState.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.root(
        level: snapshot?.jlptTarget,
        streakDays: snapshot?.streakDays,
        hasUnreadNotifications: snapshot?.hasUnreadNotifications ?? false,
        initials: snapshot?.initials,
        onProfilePressed: () => context.go(AppRoutes.profile),
      ),
      body: SafeArea(
        top: false,
        child: learningState.when(
          loading: () => const LearningLoadingView(),
          error: (_, _) => LearningErrorView(
            onRetry: ref.read(learningControllerProvider.notifier).retry,
          ),
          data: (data) => LearningHomeView(
            snapshot: data,
            onOpenRoadmap: () => context.push(AppRoutes.learnRoadmap),
          ),
        ),
      ),
    );
  }
}
