import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:rikipath_mobile/features/auth/presentation/register_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/splash_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/update_email_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/verify_email_screen.dart';
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
import 'package:rikipath_mobile/features/notebook/presentation/notebook_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/jlpt_goal_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/notification_settings_screen.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/vocabulary_detail_screen.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/vocabulary_library_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authSession = ref.watch(authSessionControllerProvider);
  final router = createAppRouter(authSession: authSession);
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createAppRouter({
  required ValueListenable<AuthSessionState> authSession,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authSession,
    redirect: (context, state) => authRouteRedirect(
      authState: authSession.value,
      matchedLocation: state.matchedLocation,
    ),
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
        builder: (context, state) => VerifyEmailScreen(
          userId: state.extra is int ? state.extra! as int : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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
    AuthSessionState.authenticated =>
      isSplash || isEntryAuthRoute ? AppRoutes.home : null,
  };
}
