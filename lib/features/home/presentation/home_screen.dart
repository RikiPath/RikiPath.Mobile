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
import 'package:rikipath_mobile/features/meeting/application/upcoming_meeting_provider.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(homeControllerProvider);
    final journeyState = ref.watch(learnerJourneyControllerProvider);
    final learningState = ref.watch(learningControllerProvider);
    final analyticsState = ref.watch(learnerAnalyticsControllerProvider);
    final practiceState = ref.watch(demoPracticeControllerProvider);
    final dailyReviewState = ref.watch(dailyReviewControllerProvider);
    final notificationState = ref.watch(notificationControllerProvider);
    final upcomingMeetingState = ref.watch(upcomingMeetingProvider);
    final analytics = analyticsState.value;
    final liveStreak = analytics?.isAvailable(AnalyticsSection.streak) == true
        ? analytics?.streakDays
        : null;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: HomeHeader(
        streakDays: liveStreak,
        isStreakLoading: analyticsState.isLoading,
        unreadNotificationCount: notificationState.value?.unreadCount,
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
          dailyReviewState: dailyReviewState,
          upcomingMeetingState: upcomingMeetingState,
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
            context.go(AppRoutes.practice);
          },
          onOpenReview: () => context.go(AppRoutes.dailyReview),
          onOpenAnalytics: () => context.push(AppRoutes.analytics),
          onOpenMeeting: () => context.push(AppRoutes.meetingJoin),
          onOpenMeetingDetail: (bookingId) =>
              context.push(AppRoutes.learnerMentorBookingDetail(bookingId)),
          onJoinMeeting: (uri) => _openMeeting(ref, context, uri),
          onOpenVocabulary: () => context.go(AppRoutes.vocabulary),
          onOpenGrammar: () => context.go(AppRoutes.grammar),
          onOpenWriting: () => context.go(AppRoutes.writing),
        ),
      ),
    );
  }
}

Future<void> _openMeeting(WidgetRef ref, BuildContext context, Uri uri) async {
  final room = MeetingRoomReference.resolve(webUri: uri);
  if (MeetingNativeRollout.isEnabled) {
    if (room == null) {
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: context.l10n.meetingOpenFailedTitle,
            description: context.l10n.meetingLinkInvalid,
          );
      return;
    }
    await context.push(AppRoutes.meetingRoom(room.roomId), extra: room);
    return;
  }
  final opened = await ref.read(mentorMeetingLinkLauncherProvider).open(uri);
  if (opened || !context.mounted) return;
  ref
      .read(rikiToastServiceProvider.notifier)
      .error(
        title: context.l10n.meetingOpenFailedTitle,
        description: context.l10n.meetingOpenFailedDescription,
      );
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
    settle(ref.refresh(learnerMentorBookingsControllerProvider.future)),
    settle(ref.refresh(dailyReviewControllerProvider.future)),
  ]);
}
