import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/home/application/home_controller.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(homeControllerProvider);
    final dashboard = dashboardState.asData?.value;
    final journeyState = ref.watch(learnerJourneyControllerProvider);
    final learningState = ref.watch(learningControllerProvider);
    final analyticsState = ref.watch(learnerAnalyticsControllerProvider);
    final practiceState = ref.watch(demoPracticeControllerProvider);
    final notificationState = ref.watch(notificationControllerProvider);
    final analytics = analyticsState.value;
    final selectedLevel = journeyState.value?.hasSelectedLevel == true
        ? journeyState.value?.selectedLevel
        : null;
    final liveStreak = analytics?.isAvailable(AnalyticsSection.streak) == true
        ? analytics?.streakDays
        : null;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: HomeHeader(
        level: selectedLevel,
        streakDays: liveStreak,
        isStreakLoading: analyticsState.isLoading,
        unreadNotificationCount: notificationState.value?.unreadCount,
        initials: dashboard?.initials,
        onProfilePressed: () => context.go(AppRoutes.profile),
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
      ),
      body: SafeArea(
        top: false,
        child: HomeDashboardView(
          dashboardState: dashboardState,
          journeyState: journeyState,
          learningState: learningState,
          analyticsState: analyticsState,
          practiceState: practiceState,
          onRefreshLive: () => _refreshLiveData(ref),
          onRetryHome: ref.read(homeControllerProvider.notifier).retry,
          onRetryLearning: ref.read(learningControllerProvider.notifier).retry,
          onRetryAnalytics: ref
              .read(learnerAnalyticsControllerProvider.notifier)
              .retry,
          onRetryPractice: ref
              .read(demoPracticeControllerProvider.notifier)
              .retry,
          onOpenLearning: () {
            final journey = journeyState.value;
            final learning = learningState.value;
            if (journey?.hasSelectedLevel != true || learning == null) {
              context.go(AppRoutes.learn);
              return;
            }
            if (!learning.hasCurrentLesson) {
              context.go(AppRoutes.learnRoadmap);
              return;
            }
            context.go(AppRoutes.lesson(learning.currentLesson.routeId));
          },
          onOpenRoadmap: () {
            if (journeyState.value?.hasSelectedLevel == true) {
              context.go(AppRoutes.learnRoadmap);
            } else {
              context.go(AppRoutes.learn);
            }
          },
          onOpenNotebook: () => context.go(AppRoutes.notebook),
          onOpenPractice: () {
            final practice = practiceState.value;
            if (practice?.hasActiveMockAttempt == true) {
              context.go(AppRoutes.mockTest(practice!.mockTest.id));
            } else if (practice?.hasRecentMockResult == true) {
              context.go(AppRoutes.mockTestResult(practice!.mockTest.id));
            } else {
              context.go(AppRoutes.practice);
            }
          },
          onOpenReview: () => context.go(AppRoutes.dailyReview),
          onOpenAnalytics: () => context.push(AppRoutes.analytics),
        ),
      ),
    );
  }
}

Future<void> _refreshLiveData(WidgetRef ref) async {
  Future<void> settle(Future<Object?> request) async {
    try {
      await request;
    } catch (_) {
      // Each live section owns and renders its error independently.
    }
  }

  await Future.wait(<Future<void>>[
    settle(ref.refresh(learnerAnalyticsControllerProvider.future)),
    settle(ref.refresh(notificationControllerProvider.future)),
  ]);
}
