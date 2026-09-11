import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/register_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/splash_screen.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';

void main() {
  test('route constants expose the supported navigation paths', () {
    expect(AppRoutes.splash, '/splash');
    expect(AppRoutes.login, '/auth/login');
    expect(AppRoutes.register, '/auth/register');
    expect(AppRoutes.forgotPassword, '/auth/forgot-password');
    expect(AppRoutes.onboarding, '/onboarding');
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.learn, '/learn');
    expect(AppRoutes.practice, '/practice');
    expect(AppRoutes.notebook, '/notebook');
    expect(AppRoutes.profile, '/profile');
  });

  testWidgets('splash is outside the tab shell and continues to login', (
    tester,
  ) async {
    await _pumpRouter(tester, initialLocation: AppRoutes.splash);

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('auth and onboarding routes never show bottom navigation', (
    tester,
  ) async {
    final router = await _pumpRouter(
      tester,
      initialLocation: AppRoutes.login,
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);

    router.go(AppRoutes.register);
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);

    router.go(AppRoutes.forgotPassword);
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);

    router.go(AppRoutes.onboarding);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('each main destination renders inside the indexed tab shell', (
    tester,
  ) async {
    final router = await _pumpRouter(
      tester,
      initialLocation: AppRoutes.home,
    );
    const destinations = <({String path, Type screen, int index})>[
      (path: AppRoutes.home, screen: HomeScreen, index: 0),
      (path: AppRoutes.learn, screen: LearnScreen, index: 1),
      (path: AppRoutes.practice, screen: PracticeScreen, index: 2),
      (path: AppRoutes.notebook, screen: NotebookScreen, index: 3),
      (path: AppRoutes.profile, screen: ProfileScreen, index: 4),
    ];

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('Luyện tập'), findsOneWidget);
    expect(find.text('Sổ từ'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);

    for (final destination in destinations) {
      router.go(destination.path);
      await tester.pumpAndSettle();

      expect(find.byType(destination.screen), findsOneWidget);
      expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
      final navigationBar = tester.widget<RikiBottomNavigationBar>(
        find.byType(RikiBottomNavigationBar),
      );
      expect(navigationBar.selectedIndex, destination.index);
    }
  });

  testWidgets('switching tabs preserves the branch widget state tree', (
    tester,
  ) async {
    await _pumpRouter(tester, initialLocation: AppRoutes.home);
    final originalHomeElement = tester.element(find.byType(HomeScreen));

    await tester.tap(find.text('Học tập'));
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    final offstageHomeElement = tester.element(
      find.byType(HomeScreen, skipOffstage: false),
    );
    expect(identical(offstageHomeElement, originalHomeElement), isTrue);

    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();

    expect(tester.element(find.byType(HomeScreen)), same(originalHomeElement));
  });
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  required String initialLocation,
}) async {
  final router = createAppRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return router;
}
