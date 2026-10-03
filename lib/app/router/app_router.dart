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
import 'package:rikipath_mobile/features/mentor/presentation/mentor_availability_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_home_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_meeting_detail_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_meetings_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/daily_review_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_result_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/mock_test_screen.dart';
import 'package:rikipath_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_screen.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_entry_detail_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/jlpt_goal_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/notification_settings_screen.dart';
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
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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

  return switch (authState) {
    AuthSessionState.unknown => isSplash ? null : AppRoutes.splash,
    AuthSessionState.unauthenticated =>
      isPublicAuthRoute ? null : AppRoutes.login,
    AuthSessionState.authenticated => _authenticatedRoleRedirect(
      role: role,
      matchedLocation: matchedLocation,
      isSplash: isSplash,
      isAuthRoute: isPublicAuthRoute,
    ),
  };
}

String? _authenticatedRoleRedirect({
  required BackendUserRole? role,
  required String matchedLocation,
  required bool isSplash,
  required bool isAuthRoute,
}) {
  final isMentorRoute =
      matchedLocation == AppRoutes.mentor ||
      matchedLocation.startsWith('${AppRoutes.mentor}/');

  if (role == BackendUserRole.learner) {
    if (isSplash ||
        isAuthRoute ||
        isMentorRoute ||
        matchedLocation == AppRoutes.unsupportedRole) {
      return AppRoutes.home;
    }
    return null;
  }

  if (role == BackendUserRole.mentor) {
    return isMentorRoute ? null : AppRoutes.mentor;
  }

  return matchedLocation == AppRoutes.unsupportedRole
      ? null
      : AppRoutes.unsupportedRole;
}
