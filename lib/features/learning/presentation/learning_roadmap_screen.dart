import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_state_views.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/standard_roadmap_view.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';

class LearningRoadmapScreen extends ConsumerWidget {
  const LearningRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmapState = ref.watch(standardRoadmapProvider);
    final placementState = ref.watch(placementTestStatusProvider);
    final pathState = ref.watch(learningPathControllerProvider);
    final roadmap = roadmapState.asData?.value;
    final placement = placementState.asData?.value;
    final eligible =
        placement?.hasCompletedPlacementTest == true &&
        placement?.isReadyForLearningPath == true;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.standardRoadmapTitle,
        subtitle: roadmap == null
            ? context.l10n.loadingRoadmap
            : context.l10n.standardRoadmapProgress(
                roadmap.completedLessons,
                roadmap.totalLessons,
              ),
        onBack: () => _goBack(context),
      ),
      body: SafeArea(
        top: false,
        child: roadmapState.when(
          loading: () => const LearningLoadingView(),
          error: (error, _) => LearningErrorView(
            onRetry: () => ref.invalidate(standardRoadmapProvider),
          ),
          data: (data) => StandardRoadmapView(
            roadmap: data,
            onOpenLesson: (lessonId) =>
                context.push(AppRoutes.lesson(lessonId)),
            onRefresh: () => _refresh(ref),
            canGenerateAiPath: eligible,
            hasCompletedPlacement: placement?.hasCompletedPlacementTest == true,
            isGeneratingAiPath: pathState.isLoading,
            aiPathError: _pathError(context, pathState, placementState),
            aiPath: pathState.asData?.value,
            onGenerateAiPath: () {
              if (eligible) {
                ref.read(learningPathControllerProvider.notifier).generate();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(standardRoadmapProvider);
    ref.invalidate(placementTestStatusProvider);
    ref.invalidate(learningPathControllerProvider);
    await ref.read(standardRoadmapProvider.future);
  }

  String? _pathError(
    BuildContext context,
    AsyncValue<Object?> pathState,
    AsyncValue<Object?> placementState,
  ) {
    if (placementState.hasError) {
      return appErrorMessage(
        placementState.error!,
        context.l10n,
        fallback: context.l10n.checkConnectionRetry,
      );
    }
    if (pathState.hasError) {
      final error = pathState.error!;
      if (error is ValidationError) {
        return context.l10n.learningPathRequirements;
      }
      return appErrorMessage(
        error,
        context.l10n,
        fallback: context.l10n.learningPathGenerateFailed,
      );
    }
    return null;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.learn);
  }
}
