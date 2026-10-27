import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_home_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_state_views.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningState = ref.watch(learningControllerProvider);
    final catalog = ref.watch(jlptCatalogControllerProvider);
    final snapshot = learningState.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.root(
        streakDays: snapshot?.streakDays,
        hasUnreadNotifications: snapshot?.hasUnreadNotifications ?? false,
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
            catalog: catalog.whenData(
              (levels) => levels
                  .where(
                    (level) => const <String>{
                      'N5',
                      'N4',
                      'N3',
                    }.contains(level.code.toUpperCase()),
                  )
                  .toList(growable: false),
            ),
            onSelectLevel: (level) => _selectLevel(context, ref, level),
            onRetryCatalog: ref
                .read(jlptCatalogControllerProvider.notifier)
                .retry,
            onRefresh: ref.read(learningControllerProvider.notifier).retry,
            onOpenRoadmap: () => context.push(AppRoutes.learnRoadmap),
            onOpenLibrary: () => context.push(AppRoutes.sharedBank),
            onOpenLesson: () =>
                context.push(AppRoutes.lesson(data.currentLesson.routeId)),
          ),
        ),
      ),
    );
  }

  Future<void> _selectLevel(
    BuildContext context,
    WidgetRef ref,
    JlptLevelCatalogItem item,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.changeStudyLevelTitle),
        content: Text(context.l10n.changeStudyLevelConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey<String>('confirm_current_study_level_change'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    try {
      final repository = ref.read(userProfileRepositoryProvider);
      if (repository is! StudyLevelProfileRepository) {
        throw UnsupportedError('Current study level cannot be persisted.');
      }
      await (repository as StudyLevelProfileRepository).switchStudyLevel(
        currentStudyLevelId: item.id,
      );
      await ref
          .read(learnerJourneyControllerProvider.notifier)
          .selectCatalogLevel(item);
      ref.invalidate(standardRoadmapProvider);
      ref.invalidate(learningControllerProvider);
      ref.invalidate(userProfileControllerProvider);
    } catch (_) {
      if (!context.mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: context.l10n.toastActionFailedTitle,
            description: context.l10n.checkConnectionRetry,
          );
    }
  }
}
