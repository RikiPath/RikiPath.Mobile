import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/jlpt_progress_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_state_views.dart';

class JlptProgressScreen extends ConsumerWidget {
  const JlptProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningState = ref.watch(learningControllerProvider);
    final snapshot = learningState.asData?.value;
    final levelSuffix = snapshot == null ? '' : ' ${snapshot.jlptTarget.label}';

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.jlptProgress(levelSuffix),
        subtitle: context.l10n.fiveSkillBreakdown,
        onBack: () => _goBack(context),
      ),
      body: SafeArea(
        top: false,
        child: learningState.when(
          loading: () => const LearningLoadingView(),
          error: (_, _) => LearningErrorView(
            onRetry: ref.read(learningControllerProvider.notifier).retry,
          ),
          data: (data) => JlptProgressView(
            snapshot: data,
            onOpenRoadmap: () => context.go(AppRoutes.learnRoadmap),
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
    context.go(AppRoutes.learnRoadmap);
  }
}
