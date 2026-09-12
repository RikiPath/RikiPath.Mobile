import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/main_shell.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/register_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/splash_screen.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/jlpt_progress_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_roadmap_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/lesson_screen.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';

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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Không tìm thấy trang: ${state.uri}')),
    ),
  );
}

String? authRouteRedirect({
  required AuthSessionState authState,
  required String matchedLocation,
}) {
  final isSplash = matchedLocation == AppRoutes.splash;
  final isAuthRoute =
      matchedLocation == AppRoutes.login ||
      matchedLocation == AppRoutes.register ||
      matchedLocation == AppRoutes.forgotPassword;

  return switch (authState) {
    AuthSessionState.unknown => isSplash ? null : AppRoutes.splash,
    AuthSessionState.unauthenticated => isAuthRoute ? null : AppRoutes.login,
    AuthSessionState.authenticated =>
      isSplash || isAuthRoute ? AppRoutes.home : null,
  };
}
