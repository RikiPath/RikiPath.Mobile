import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';

final learnerStartupDestinationProvider =
    FutureProvider.autoDispose<LearnerStartupDestination>((ref) async {
      final placement = await ref.watch(placementTestControllerProvider.future);
      if (placement.hasActiveAttempt ||
          placement.result != null ||
          placement.shouldRetryResultRecovery) {
        return LearnerStartupDestination.placementTest;
      }

      final profile = await ref
          .watch(userProfileRepositoryProvider)
          .loadProfile();
      final targetLevelId = profile.targetJlptLevelId;
      final currentLevelId =
          profile.currentStudyLevelId ??
          profile.startingJlptLevelId ??
          targetLevelId;
      if (currentLevelId == null && targetLevelId == null) {
        return LearnerStartupDestination.onboarding;
      }
      final catalog = await ref
          .watch(jlptCatalogRepositoryProvider)
          .loadLevels();
      JlptLevelCatalogItem? currentLevel;
      JlptLevelCatalogItem? targetLevel;
      for (final level in catalog) {
        if (level.id == currentLevelId) currentLevel = level;
        if (level.id == targetLevelId) {
          targetLevel = level;
        }
      }
      if (currentLevel == null || targetLevel == null) {
        ref
            .read(onboardingControllerProvider.notifier)
            .hydrateFromProfile(
              currentStudyLevel: currentLevel,
              targetLevel: targetLevel,
              dailyMinutes: profile.dailyStudyMinutes,
              targetExamDate: profile.targetExamDate,
            );
        return LearnerStartupDestination.onboarding;
      }
      await ref
          .read(learnerJourneyControllerProvider.notifier)
          .setCatalogPreferences(
            item: currentLevel,
            dailyStudyMinutes: profile.dailyStudyMinutes,
          );
      return LearnerStartupDestination.home;
    });

enum LearnerStartupDestination { onboarding, placementTest, home }
