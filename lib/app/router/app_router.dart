import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/main_shell.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/account_settings_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/change_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/mobile_role_landing_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/register_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/splash_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/update_email_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/verify_email_screen.dart';
import 'package:rikipath_mobile/features/auth/domain/verify_email_arguments.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/grammar/presentation/grammar_detail_screen.dart';
import 'package:rikipath_mobile/features/grammar/presentation/grammar_library_screen.dart';
import 'package:rikipath_mobile/features/kanji/presentation/kanji_detail_screen.dart';
import 'package:rikipath_mobile/features/kanji/presentation/kanji_library_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/jlpt_progress_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_roadmap_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/lesson_screen.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_join_screen.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_landing_screen.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_room_screen.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_availability_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_home_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_availability_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_booking_detail_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_bookings_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_discovery_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_meetings_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_profile_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_mentor_purchase_status_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/learner_session_completed_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_meeting_detail_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_meetings_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/daily_review_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_result_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_screen.dart';
import 'package:rikipath_mobile/features/speech/presentation/speech_to_text_screen.dart';
import 'package:rikipath_mobile/features/text_scan/presentation/text_scan_screen.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';
import 'package:rikipath_mobile/features/writing_practice/presentation/writing_practice_detail_screen.dart';
import 'package:rikipath_mobile/features/writing_practice/presentation/writing_practice_screen.dart';
import 'package:rikipath_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_screen.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_entry_detail_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/learner_startup_screen.dart';
import 'package:rikipath_mobile/features/placement_test/presentation/placement_test_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/jlpt_goal_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/notification_settings_screen.dart';
import 'package:rikipath_mobile/features/shared_bank/presentation/shared_bank_screen.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/vocabulary_detail_screen.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/vocabulary_library_screen.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/analytics/presentation/learner_analytics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authSession = ref.watch(authSessionControllerProvider);
  final router = createAppRouter(authSession: authSession);
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createAppRouter({
  required AuthSessionController authSession,
  String initialLocation = AppRoutes.splash,
}) {
  String? pendingLocation;
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authSession,
    redirect: (context, state) {
      final authState = authSession.value;
      if (authState == AuthSessionState.unknown) {
        if (state.matchedLocation != AppRoutes.splash) {
          pendingLocation ??= state.uri.toString();
        }
        return authRouteRedirect(
          authState: authState,
          role: authSession.currentRole,
          matchedLocation: state.matchedLocation,
        );
      }

      if (authState == AuthSessionState.authenticated &&
          pendingLocation != null) {
        final intendedLocation = pendingLocation!;
        pendingLocation = null;
        final intendedPath = Uri.parse(intendedLocation).path;
        return authRouteRedirect(
              authState: authState,
              role: authSession.currentRole,
              matchedLocation: intendedPath,
            ) ??
            intendedLocation;
      }

      return authRouteRedirect(
        authState: authState,
        role: authSession.currentRole,
        matchedLocation: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final arguments = state.extra;
          return VerifyEmailScreen(
            userId: switch (arguments) {
              VerifyEmailArguments(:final userId) => userId,
              int userId => userId,
              _ => null,
            },
            email: arguments is VerifyEmailArguments ? arguments.email : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.unsupportedRole,
        builder: (context, state) => UnsupportedRoleScreen(
          role: authSession.currentRole?.apiValue ?? 'Unknown',
        ),
      ),
      GoRoute(
        path: AppRoutes.meeting,
        builder: (context, state) => const MeetingLandingScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.meetingJoinSegment,
            builder: (context, state) => const MeetingJoinScreen(),
          ),
          GoRoute(
            path: AppRoutes.meetingRoomSegment,
            builder: (context, state) {
              final roomId = state.pathParameters['roomId'];
              final extra = state.extra;
              final room = extra is MeetingRoomReference
                  ? extra
                  : MeetingRoomReference.resolve(roomId: roomId);
              if (room == null) return const MeetingJoinScreen();
              return MeetingRoomScreen(room: room);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.mentor,
        builder: (context, state) => const MentorHomeScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.mentorAvailabilitySegment,
            builder: (context, state) => const MentorAvailabilityScreen(),
          ),
          GoRoute(
            path: AppRoutes.mentorMeetingsSegment,
            builder: (context, state) => const MentorMeetingsScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.mentorMeetingDetailSegment,
                builder: (context, state) => MentorMeetingDetailScreen(
                  meetingId: int.tryParse(
                    state.pathParameters['meetingId'] ?? '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.learnerMentorMeetings,
        builder: (context, state) => const LearnerMentorMeetingsScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.learnerMentorDiscoverySegment,
            builder: (context, state) => LearnerMentorDiscoveryScreen(
              planId: int.tryParse(state.pathParameters['planId'] ?? '') ?? 1,
            ),
          ),
          GoRoute(
            path: AppRoutes.learnerMentorProfileSegment,
            builder: (context, state) => LearnerMentorProfileScreen(
              planId: int.tryParse(state.pathParameters['planId'] ?? '') ?? 1,
              mentorId:
                  int.tryParse(state.pathParameters['mentorId'] ?? '') ?? 1,
            ),
          ),
          GoRoute(
            path: AppRoutes.learnerMentorAvailabilitySegment,
            builder: (context, state) => LearnerMentorAvailabilityScreen(
              planId: int.tryParse(state.pathParameters['planId'] ?? ''),
              subscriptionId: int.tryParse(
                state.uri.queryParameters['subscriptionId'] ?? '',
              ),
              mentorId:
                  int.tryParse(state.uri.queryParameters['mentorId'] ?? ''),
            ),
          ),
          GoRoute(
            path: AppRoutes.learnerSessionCompletedSegment,
            builder: (context, state) => LearnerSessionCompletedScreen(
              bookingId:
                  int.tryParse(state.pathParameters['bookingId'] ?? '') ?? 1,
            ),
          ),
          GoRoute(
            path: AppRoutes.learnerMentorBookingsSegment,
            builder: (context, state) => const LearnerMentorBookingsScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.learnerMentorBookingDetailSegment,
                builder: (context, state) => LearnerMentorBookingDetailScreen(
                  bookingId: int.tryParse(
                    state.pathParameters['bookingId'] ?? '',
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.learnerMentorPurchaseStatusSegment,
            builder: (context, state) => LearnerMentorPurchaseStatusScreen(
              subscriptionId: int.tryParse(
                state.pathParameters['subscriptionId'] ?? '',
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.learnerStartup,
        builder: (context, state) => const LearnerStartupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.placementTest,
        builder: (context, state) => const PlacementTestScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const LearnerAnalyticsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.learn,
                builder: (context, state) => const LearnScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.learnRoadmapSegment,
                    builder: (context, state) => const LearningRoadmapScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.learnProgressSegment,
                    builder: (context, state) => const JlptProgressScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.sharedBankSegment,
                    builder: (context, state) => const SharedBankScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.vocabularySegment,
                    builder: (context, state) =>
                        const VocabularyLibraryScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.vocabularyDetailSegment,
                    builder: (context, state) => VocabularyDetailScreen(
                      routeKey: state.pathParameters['entryKey']!,
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.kanjiSegment,
                    builder: (context, state) => const KanjiLibraryScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.kanjiDetailSegment,
                    builder: (context, state) => KanjiDetailScreen(
                      routeKey: state.pathParameters['entryKey']!,
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.grammarSegment,
                    builder: (context, state) => const GrammarLibraryScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.grammarDetailSegment,
                    builder: (context, state) => GrammarDetailScreen(
                      routeKey: state.pathParameters['entryKey']!,
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.lessonSegment,
                    builder: (context, state) => LessonScreen(
                      lessonId: state.pathParameters['lessonId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.practice,
                builder: (context, state) => const PracticeScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.reviewSegment,
                    builder: (context, state) => const DailyReviewScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.writingSegment,
                    redirect: (context, state) =>
                        state.uri.path == AppRoutes.writing
                        ? AppRoutes.writingHiragana
                        : null,
                    routes: [
                      _writingRoute(
                        segment: AppRoutes.writingHiraganaSegment,
                        script: WritingScript.hiragana,
                      ),
                      _writingRoute(
                        segment: AppRoutes.writingKatakanaSegment,
                        script: WritingScript.katakana,
                      ),
                      _writingRoute(
                        segment: AppRoutes.writingKanjiSegment,
                        script: WritingScript.kanji,
                      ),
                    ],
                  ),
                  GoRoute(
                    path: AppRoutes.speechSegment,
                    builder: (context, state) => const SpeechToTextScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.textScanSegment,
                    builder: (context, state) => const TextScanScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.mockTestSegment,
                    builder: (context, state) =>
                        MockTestScreen(testId: state.pathParameters['testId']!),
                    routes: [
                      GoRoute(
                        path: AppRoutes.mockResultSegment,
                        builder: (context, state) => MockTestResultScreen(
                          testId: state.pathParameters['testId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: AppRoutes.mockDetailedReviewSegment,
                            builder: (context, state) =>
                                MockTestDetailedReviewScreen(
                                  testId: state.pathParameters['testId']!,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notebook,
                builder: (context, state) => const NotebookScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.notebookCollectionSegment,
                    builder: (context, state) => NotebookCollectionScreen(
                      collectionKey: state.pathParameters['collectionKey']!,
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.notebookVocabularyDetailSegment,
                    builder: (context, state) => VocabularyDetailScreen(
                      routeKey: state.pathParameters['entryKey']!,
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.notebookEntryDetailSegment,
                    builder: (context, state) => NotebookEntryDetailScreen(
                      entryKey: state.pathParameters['entryKey']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.profileAccountSegment,
                    pageBuilder: (context, state) => _profileDetailPage(
                      state: state,
                      child: const AccountSettingsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.profileEditSegment,
                    pageBuilder: (context, state) => _profileDetailPage(
                      state: state,
                      child: const EditProfileScreen(),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.profileJlptGoalSegment,
                    pageBuilder: (context, state) => _profileDetailPage(
                      state: state,
                      child: const JlptGoalScreen(),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.profileNotificationsSegment,
                    pageBuilder: (context, state) => _profileDetailPage(
                      state: state,
                      child: const NotificationSettingsScreen(),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.profileChangeEmailSegment,
                    pageBuilder: (context, state) => _profileDetailPage(
                      state: state,
                      child: const UpdateEmailScreen(),
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.profileChangePasswordSegment,
                    pageBuilder: (context, state) => _profileDetailPage(
                      state: state,
                      child: const ChangePasswordScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text(context.l10n.pageNotFound('${state.uri}'))),
    ),
  );
}

GoRoute _writingRoute({
  required String segment,
  required WritingScript script,
}) {
  return GoRoute(
    path: segment,
    builder: (context, state) => WritingPracticeScreen(script: script),
    routes: [
      GoRoute(
        path: ':characterId',
        builder: (context, state) => WritingPracticeDetailScreen(
          script: script,
          characterId: int.tryParse(state.pathParameters['characterId'] ?? ''),
        ),
      ),
    ],
  );
}

CustomTransitionPage<void> _profileDetailPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final mediaQuery = MediaQuery.maybeOf(context);
      final reduceMotion =
          (mediaQuery?.disableAnimations ?? false) ||
          (mediaQuery?.accessibleNavigation ?? false);
      if (reduceMotion) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.035, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

String? authRouteRedirect({
  required AuthSessionState authState,
  required BackendUserRole? role,
  required String matchedLocation,
}) {
  final isSplash = matchedLocation == AppRoutes.splash;
  final isEntryAuthRoute =
      matchedLocation == AppRoutes.login ||
      matchedLocation == AppRoutes.register ||
      matchedLocation == AppRoutes.forgotPassword;
  final isPublicAuthRoute =
      isEntryAuthRoute || matchedLocation == AppRoutes.verifyEmail;
  final isPublicMeetingRoute =
      matchedLocation == AppRoutes.meeting ||
      matchedLocation.startsWith('${AppRoutes.meeting}/');

  return switch (authState) {
    AuthSessionState.unknown => isSplash ? null : AppRoutes.splash,
    AuthSessionState.unauthenticated =>
      isPublicAuthRoute || isPublicMeetingRoute ? null : AppRoutes.login,
    AuthSessionState.authenticated => _authenticatedRoleRedirect(
      role: role,
      matchedLocation: matchedLocation,
      isSplash: isSplash,
      isAuthRoute: isPublicAuthRoute,
      isMeetingRoute: isPublicMeetingRoute,
    ),
  };
}

String? _authenticatedRoleRedirect({
  required BackendUserRole? role,
  required String matchedLocation,
  required bool isSplash,
  required bool isAuthRoute,
  required bool isMeetingRoute,
}) {
  final isMentorRoute =
      matchedLocation == AppRoutes.mentor ||
      matchedLocation.startsWith('${AppRoutes.mentor}/');

  if (role == BackendUserRole.learner) {
    if (isSplash ||
        isAuthRoute ||
        isMentorRoute ||
        matchedLocation == AppRoutes.unsupportedRole) {
      return AppRoutes.learnerStartup;
    }
    return null;
  }

  if (role == BackendUserRole.mentor) {
    return isMentorRoute || isMeetingRoute ? null : AppRoutes.mentor;
  }

  return matchedLocation == AppRoutes.unsupportedRole
      ? null
      : AppRoutes.unsupportedRole;
}
