import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/main_shell.dart';
import 'package:rikipath_mobile/app/router/navigation_configuration.dart';
import 'package:rikipath_mobile/app/router/riki_path_app_shell.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/presentation/account_settings_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/change_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/mobile_role_landing_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/register_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/splash_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/update_email_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/verify_email_screen.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_profile.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/mentor_cohorts_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_availability_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_home_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_profile_screen.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shell.dart';
import 'package:rikipath_mobile/features/calendar/presentation/mentor_calendar_screen.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/learner_startup_screen.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/notification_settings_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';
import '../../support/test_jwt.dart';

final _futureExamDate = DateTime.utc(2030, 12, 7);

void main() {
  test('route constants expose the supported navigation paths', () {
    expect(AppRoutes.splash, '/splash');
    expect(AppRoutes.login, '/auth/login');
    expect(AppRoutes.register, '/auth/register');
    expect(AppRoutes.forgotPassword, '/auth/forgot-password');
    expect(AppRoutes.verifyEmail, '/auth/verify-email');
    expect(AppRoutes.unsupportedRole, '/auth/unsupported-role');
    expect(AppRoutes.learnerStartup, '/learner-startup');
    expect(AppRoutes.onboarding, '/onboarding');
    expect(AppRoutes.meeting, '/meeting');
    expect(AppRoutes.meetingJoin, '/meeting/join');
    expect(AppRoutes.mentor, '/mentor');
    expect(AppRoutes.mentorAvailability, '/mentor/availability');
    expect(AppRoutes.mentorCohorts, '/mentor/cohorts');
    expect(AppRoutes.mentorCohortDetail(17), '/mentor/cohorts/17');
    expect(AppRoutes.home, '/home');
    expect(AppRoutes.learn, '/learn');
    expect(AppRoutes.practice, '/practice');
    expect(AppRoutes.notebook, '/notebook');
    expect(AppRoutes.profile, '/profile');
    expect(AppRoutes.profileAccount, '/profile/account');
    expect(AppRoutes.profileEdit, '/profile/edit');
    expect(AppRoutes.profileJlptGoal, '/profile/jlpt-goal');
    expect(AppRoutes.profileNotifications, '/profile/notifications');
    expect(AppRoutes.profileChangeEmail, '/profile/change-email');
    expect(AppRoutes.profileChangePassword, '/profile/change-password');
  });

  testWidgets('unknown session stays on splash until restoration completes', (
    tester,
  ) async {
    final session = createTestAuthSession(
      initialState: AuthSessionState.unknown,
    );
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.splash,
      authSession: session,
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);

    await session.restore();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('auth routes remain reachable while logged out', (tester) async {
    final session = createTestAuthSession(
      initialState: AuthSessionState.unauthenticated,
    );
    final router = await _pumpRouter(
      tester,
      initialLocation: AppRoutes.login,
      authSession: session,
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

    router.go(AppRoutes.verifyEmail);
    await tester.pumpAndSettle();
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.text('Chưa thể tiếp tục từ đăng ký'), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('restored first-time learner is sent to onboarding', (
    tester,
  ) async {
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.splash,
      authSession: createTestAuthSession(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('restored returning learner is sent to home', (tester) async {
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.splash,
      authSession: createTestAuthSession(),
      profileRepository: _RouterProfileRepository(
        targetJlptLevelId: 101,
        targetJlptLevelName: 'N5',
        targetExamDate: _futureExamDate,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
  });

  testWidgets('startup profile failure remains controlled and retryable', (
    tester,
  ) async {
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.splash,
      authSession: createTestAuthSession(),
      profileRepository: const _FailingStartupProfileRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LearnerStartupScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('learner_startup_error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('learner_startup_retry')),
      findsOneWidget,
    );
  });

  testWidgets('unauthenticated learner route redirects to login', (
    tester,
  ) async {
    final session = createTestAuthSession(
      initialState: AuthSessionState.unauthenticated,
    );

    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.home,
      authSession: session,
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('unauthenticated mentor route redirects to login', (
    tester,
  ) async {
    final session = createTestAuthSession(
      initialState: AuthSessionState.unauthenticated,
    );

    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.mentor,
      authSession: session,
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MentorHomeScreen), findsNothing);
  });

  testWidgets('unauthenticated account mutation route redirects to login', (
    tester,
  ) async {
    final session = createTestAuthSession(
      initialState: AuthSessionState.unauthenticated,
    );

    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.profileChangeEmail,
      authSession: session,
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(UpdateEmailScreen), findsNothing);
  });

  testWidgets('authenticated users can access learner and onboarding routes', (
    tester,
  ) async {
    final session = createTestAuthSession();
    final router = await _pumpRouter(
      tester,
      initialLocation: AppRoutes.home,
      authSession: session,
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);

    router.go(AppRoutes.onboarding);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('authenticated account routes are reachable from Profile', (
    tester,
  ) async {
    final router = await _pumpRouter(
      tester,
      initialLocation: AppRoutes.profile,
    );
    await tester.pumpAndSettle();

    final settingsAction = find.byKey(
      const ValueKey<String>('profile_settings_action'),
    );
    await tester.scrollUntilVisible(
      settingsAction,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(settingsAction);
    await tester.pumpAndSettle();
    expect(find.byType(AccountSettingsScreen), findsOneWidget);

    router.go(AppRoutes.profileEdit);
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);

    router.go(AppRoutes.profileJlptGoal);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    router.go(AppRoutes.profileNotifications);
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsScreen), findsOneWidget);

    router.go(AppRoutes.profileChangeEmail);
    await tester.pumpAndSettle();
    expect(find.byType(UpdateEmailScreen), findsOneWidget);

    router.go(AppRoutes.profileChangePassword);
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('profile logout clears the session and returns to Login', (
    tester,
  ) async {
    final session = createTestAuthSession(userId: 42);
    final router = await _pumpRouter(
      tester,
      initialLocation: AppRoutes.profile,
      authSession: session,
    );
    await tester.pumpAndSettle();

    final logout = find.byKey(const ValueKey<String>('profile_logout_action'));
    await tester.scrollUntilVisible(
      logout,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(session.value, AuthSessionState.authenticated);
    await tester.tap(
      find.byKey(const ValueKey<String>('profile_logout_confirm_button')),
    );
    await tester.pumpAndSettle();

    expect(session.value, AuthSessionState.unauthenticated);
    expect(session.currentUserId, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(router.canPop(), isFalse);

    router.go(AppRoutes.profileAccount);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AccountSettingsScreen), findsNothing);
  });

  testWidgets('expired profile session clears tokens and returns to Login', (
    tester,
  ) async {
    final secureStore = TestSecureKeyValueStore(
      accessToken: 'expired-token',
      userId: 42,
    );
    final session = createTestAuthSession(secureStore: secureStore, userId: 42);

    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.profile,
      authSession: session,
      profileRepository: const _UnauthorizedProfileRepository(),
    );
    await tester.pumpAndSettle();

    expect(session.value, AuthSessionState.unauthenticated);
    expect(session.currentUserId, isNull);
    expect(secureStore.values, isEmpty);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
  });

  testWidgets('authenticated auth route resolves returning learner home', (
    tester,
  ) async {
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.login,
      profileRepository: _RouterProfileRepository(
        targetJlptLevelId: 101,
        targetJlptLevelName: 'N5',
        targetExamDate: _futureExamDate,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated learner cannot remain on verify-email', (
    tester,
  ) async {
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.verifyEmail,
      profileRepository: _RouterProfileRepository(
        targetJlptLevelId: 101,
        targetJlptLevelName: 'N5',
        targetExamDate: _futureExamDate,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsNothing);
  });

  testWidgets('persisted learner session restores a nested learner route', (
    tester,
  ) async {
    final store = TestSecureKeyValueStore(
      accessToken: createTestJwt(userId: 42, role: 'Learner'),
      userId: 42,
      role: 'Learner',
    );
    final session = AuthSessionController(TokenStorage(store));
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.profileAccount,
      authSession: session,
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    await session.restore();
    await tester.pumpAndSettle();

    expect(find.byType(AccountSettingsScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('persisted Mentor session restores only the Mentor home', (
    tester,
  ) async {
    final store = TestSecureKeyValueStore(
      accessToken: createTestJwt(userId: 84, role: 'Mentor'),
      userId: 84,
      role: 'Mentor',
    );
    final session = AuthSessionController(TokenStorage(store));
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.mentor,
      authSession: session,
    );

    await session.restore();
    await tester.pumpAndSettle();

    expect(find.byType(MentorHomeScreen), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
    expect(find.byKey(const Key('mentor_bottom_navigation_bar')), findsOneWidget);
  });

  testWidgets('authenticated Mentor is isolated from the learner shell', (
    tester,
  ) async {
    final session = createTestAuthSession(role: BackendUserRole.mentor);

    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.home,
      authSession: session,
    );
    await tester.pumpAndSettle();

    expect(find.byType(MentorHomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(MainShell), findsNothing);
    expect(find.byKey(const Key('mentor_bottom_navigation_bar')), findsOneWidget);
  });

  test('authenticated Mentor can access notifications and security routes', () {
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.mentor,
        matchedLocation: AppRoutes.notifications,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.mentor,
        matchedLocation: AppRoutes.mentorChangePassword,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.mentor,
        matchedLocation: AppRoutes.mentorChangeEmail,
      ),
      isNull,
    );
  });

  testWidgets('Mentor profile navigation never loads Learner-only profile', (
    tester,
  ) async {
    final session = createTestAuthSession(role: BackendUserRole.mentor);
    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.profile,
      authSession: session,
      profileRepository: const _UnauthorizedProfileRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MentorHomeScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(session.value, AuthSessionState.authenticated);
  });

  testWidgets('unsupported backend role reaches only the safe logout screen', (
    tester,
  ) async {
    final session = createTestAuthSession(role: BackendUserRole.contentAuthor);

    await _pumpRouter(
      tester,
      initialLocation: AppRoutes.home,
      authSession: session,
    );
    await tester.pumpAndSettle();

    expect(find.byType(UnsupportedRoleScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(RikiBottomNavigationBar), findsNothing);

    await tester.tap(find.byKey(const Key('role_landing_logout_button')));
    await tester.pumpAndSettle();
    expect(session.value, AuthSessionState.unauthenticated);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  test('stable auth destinations do not redirect and cannot loop', () {
    expect(
      authRouteRedirect(
        authState: AuthSessionState.unknown,
        role: null,
        matchedLocation: AppRoutes.splash,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.mentor,
        matchedLocation: AppRoutes.mentorCohorts,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.unauthenticated,
        role: null,
        matchedLocation: AppRoutes.login,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.learner,
        matchedLocation: AppRoutes.home,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.learner,
        matchedLocation: AppRoutes.mentorApplication,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.learner,
        matchedLocation: AppRoutes.mentorProfile,
      ),
      AppRoutes.learnerStartup,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.mentor,
        matchedLocation: AppRoutes.mentorApplication,
      ),
      AppRoutes.mentorProfile,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.unauthenticated,
        role: null,
        matchedLocation: AppRoutes.verifyEmail,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.unauthenticated,
        role: null,
        matchedLocation: AppRoutes.meetingJoin,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.learner,
        matchedLocation: AppRoutes.verifyEmail,
      ),
      AppRoutes.learnerStartup,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.mentor,
        matchedLocation: AppRoutes.mentor,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.mentor,
        matchedLocation: AppRoutes.meetingJoin,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.contentAuthor,
        matchedLocation: AppRoutes.home,
      ),
      AppRoutes.unsupportedRole,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.admin,
        matchedLocation: AppRoutes.home,
      ),
      AppRoutes.unsupportedRole,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: null,
        matchedLocation: AppRoutes.home,
      ),
      AppRoutes.unsupportedRole,
    );
  });

  testWidgets('each main destination renders inside the indexed tab shell', (
    tester,
  ) async {
    final router = await _pumpRouter(tester, initialLocation: AppRoutes.home);
    const destinations = <({String path, Type screen, int index})>[
      (path: AppRoutes.home, screen: HomeScreen, index: 0),
      (path: AppRoutes.learn, screen: LearnScreen, index: 1),
      (path: AppRoutes.practice, screen: PracticeScreen, index: 2),
      (path: AppRoutes.notebook, screen: NotebookScreen, index: 3),
      (path: AppRoutes.profile, screen: ProfileScreen, index: 4),
    ];

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RikiBottomNavigationBar),
        matching: find.text('Học tập'),
      ),
      findsOneWidget,
    );
    expect(find.text('Luyện tập'), findsOneWidget);
    expect(find.text('Sổ từ'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);

    for (final destination in destinations) {
      router.go(destination.path);
      await tester.pumpAndSettle();

      expect(find.byType(destination.screen), findsOneWidget);
      expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
      expect(
        find.byType(HomeHeader),
        findsOneWidget,
      );
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

    await tester.tap(
      find.descendant(
        of: find.byType(RikiBottomNavigationBar),
        matching: find.text('Học tập'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    final offstageHomeElement = tester.element(
      find.byType(HomeScreen, skipOffstage: false),
    );
    expect(identical(offstageHomeElement, originalHomeElement), isTrue);

    await tester.tap(
      find.descendant(
        of: find.byType(RikiBottomNavigationBar),
        matching: find.text('Trang chủ'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.element(find.byType(HomeScreen)), same(originalHomeElement));
  });

  testWidgets(
    'each mentor destination renders inside shared RikiPathAppShell without duplicate bottom bars',
    (tester) async {
      final session = createTestAuthSession(role: BackendUserRole.mentor);
      final router = await _pumpRouter(
        tester,
        initialLocation: AppRoutes.mentor,
        authSession: session,
      );
      await tester.pumpAndSettle();

      const destinations = <({String path, Type screen, int index})>[
        (path: AppRoutes.mentor, screen: MentorHomeScreen, index: 0),
        (
          path: AppRoutes.mentorCalendar,
          screen: MentorCalendarScreen,
          index: 1,
        ),
        (
          path: AppRoutes.mentorCohorts,
          screen: MentorCohortsScreen,
          index: 2,
        ),
        (
          path: AppRoutes.mentorAvailability,
          screen: MentorAvailabilityScreen,
          index: 3,
        ),
        (
          path: AppRoutes.mentorProfile,
          screen: MentorProfileScreen,
          index: 4,
        ),
      ];

      expect(find.byType(MentorShell), findsOneWidget);
      expect(find.byType(RikiPathAppShell), findsOneWidget);
      expect(find.byType(SakuraShellBranchContainer), findsOneWidget);

      for (final label in const <String>[
        'Trang chủ',
        'Lịch dạy',
        'Lớp nhóm',
        'Lịch trống',
        'Cá nhân',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(const Key('mentor_bottom_navigation_bar')),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }

      for (final destination in destinations) {
        router.go(destination.path);
        await tester.pumpAndSettle();

        expect(find.byType(destination.screen), findsOneWidget);
        // Must always render ONE shared bottom bar across all Mentor tabs.
        expect(find.byType(SakuraBottomNavigation), findsOneWidget);
        final navigationBar = tester.widget<SakuraBottomNavigation>(
          find.byType(SakuraBottomNavigation),
        );
        expect(navigationBar.selectedIndex, destination.index);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'mentor tab taps animate shared indicator, preserve branch state, and keep header/FAB inside shell',
    (tester) async {
      final session = createTestAuthSession(role: BackendUserRole.mentor);
      await _pumpRouter(
        tester,
        initialLocation: AppRoutes.mentor,
        authSession: session,
      );
      await tester.pumpAndSettle();

      final originalMentorHome = tester.element(find.byType(MentorHomeScreen));

      // Tap tab 2 (Lớp nhóm) directly on shared SakuraBottomNavigation
      await tester.tap(
        find.descendant(
          of: find.byType(SakuraBottomNavigation),
          matching: find.text('Lớp nhóm'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Branch crossfade runs synchronously without errors during transition.
      expect(find.byType(SakuraBottomNavigation), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(MentorCohortsScreen), findsOneWidget);
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        2,
      );

      // Tapping Lịch dạy tab switches to MentorCalendar (tab 1) inside MentorShell.
      await tester.tap(
        find.descendant(
          of: find.byType(SakuraBottomNavigation),
          matching: find.text('Lịch dạy'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MentorCalendarScreen), findsOneWidget);
      expect(find.byType(SakuraBottomNavigation), findsOneWidget);
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        1,
      );

      // Verify Home branch Element identity was preserved across transitions.
      final offstageHome = tester.element(
        find.byType(MentorHomeScreen, skipOffstage: false),
      );
      expect(identical(offstageHome, originalMentorHome), isTrue);

      await tester.tap(
        find.descendant(
          of: find.byType(SakuraBottomNavigation),
          matching: find.text('Trang chủ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.element(find.byType(MentorHomeScreen)),
        same(originalMentorHome),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'deep linking directly to a secondary mentor tab selects the matching index',
    (tester) async {
      final session = createTestAuthSession(role: BackendUserRole.mentor);
      await _pumpRouter(
        tester,
        initialLocation: AppRoutes.mentorAvailability,
        authSession: session,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MentorAvailabilityScreen), findsOneWidget);
      expect(find.byType(SakuraBottomNavigation), findsOneWidget);
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        MentorNavigationConfiguration.tabRoutes.indexOf(
          AppRoutes.mentorAvailability,
        ),
      );
    },
  );

  testWidgets(
    'Android system back from non-zero tab returns cleanly to tab 0 on both roles',
    (tester) async {
      // Learner back from Cá nhân (tab 4) -> Trang chủ (tab 0)
      final learnerSession = createTestAuthSession(role: BackendUserRole.learner);
      await _pumpRouter(
        tester,
        initialLocation: AppRoutes.profile,
        authSession: learnerSession,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        4,
      );

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        0,
      );

      // Mentor back from Lịch trống (tab 3) -> Trang chủ (tab 0)
      final mentorSession = createTestAuthSession(role: BackendUserRole.mentor);
      await _pumpRouter(
        tester,
        initialLocation: AppRoutes.mentorAvailability,
        authSession: mentorSession,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        3,
      );

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'role switching between Mentor and Learner resets bottom navigation cleanly',
    (tester) async {
      final session = createTestAuthSession(role: BackendUserRole.mentor);
      final router = await _pumpRouter(
        tester,
        initialLocation: AppRoutes.mentorProfile,
        authSession: session,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mentor_bottom_navigation_bar')), findsOneWidget);

      await session.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(SakuraBottomNavigation), findsNothing);

      session.markAuthenticated(userId: 99, role: BackendUserRole.learner);
      await tester.pumpAndSettle();
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('learner_bottom_navigation_bar')), findsOneWidget);
      expect(find.byKey(const Key('mentor_bottom_navigation_bar')), findsNothing);
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        0,
      );

      // Navigate Learner to Cá nhân (tab 4), logout, then sign in as Mentor.
      router.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        4,
      );

      await session.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(SakuraBottomNavigation), findsNothing);

      session.markAuthenticated(userId: 77, role: BackendUserRole.mentor);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mentor_bottom_navigation_bar')), findsOneWidget);
      expect(find.byKey(const Key('learner_bottom_navigation_bar')), findsNothing);
      expect(
        tester
            .widget<SakuraBottomNavigation>(find.byType(SakuraBottomNavigation))
            .selectedIndex,
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );

  group('Payment Deep Link Resolution', () {
    test(
      'resolves custom scheme and HTTP payment return URIs by role and query',
      () {
        expect(
          resolvePaymentDeepLinkRoute(
            Uri.parse('rikipath://payment-success'),
            authState: AuthSessionState.authenticated,
            role: BackendUserRole.learner,
          ),
          AppRoutes.learnerMyCourses,
        );
        expect(
          resolvePaymentDeepLinkRoute(
            Uri.parse('rikipath://payment-cancel'),
            authState: AuthSessionState.authenticated,
            role: BackendUserRole.learner,
          ),
          AppRoutes.learnerMyCourses,
        );
        expect(
          resolvePaymentDeepLinkRoute(
            Uri.parse('/payment-success?purchaseId=5'),
            authState: AuthSessionState.authenticated,
            role: BackendUserRole.learner,
          ),
          AppRoutes.profileSubscriptions,
        );
        expect(
          resolvePaymentDeepLinkRoute(
            Uri.parse('https://app.rikipath.test/payment-success?courseId=12'),
            authState: AuthSessionState.authenticated,
            role: BackendUserRole.learner,
          ),
          AppRoutes.learnerCohortDetail(12),
        );
        expect(
          resolvePaymentDeepLinkRoute(
            Uri.parse('rikipath://payment-success?courseId=12'),
            authState: AuthSessionState.authenticated,
            role: BackendUserRole.mentor,
          ),
          AppRoutes.mentor,
        );
        expect(
          resolvePaymentDeepLinkRoute(
            Uri.parse('rikipath://payment-success'),
            authState: AuthSessionState.unauthenticated,
            role: null,
          ),
          AppRoutes.login,
        );
        expect(
          resolvePaymentDeepLinkRoute(
            Uri.parse('rikipath://payment-success'),
            authState: AuthSessionState.unknown,
            role: null,
          ),
          AppRoutes.splash,
        );
        expect(
          resolvePaymentDeepLinkRoute(
            Uri.parse('/cohorts'),
            authState: AuthSessionState.authenticated,
            role: BackendUserRole.learner,
          ),
          isNull,
        );
      },
    );
  });
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  required String initialLocation,
  AuthSessionController? authSession,
  UserProfileRepository profileRepository = const _RouterProfileRepository(),
  MentorRepository mentorRepository = const _RouterMentorRepository(),
}) async {
  final session = authSession ?? createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: initialLocation,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
        placementTestRepositoryProvider.overrideWithValue(
          const _RouterPlacementRepository(),
        ),
        mentorRepositoryProvider.overrideWithValue(mentorRepository),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
  return router;
}

class _RouterPlacementRepository implements PlacementTestRepository {
  const _RouterPlacementRepository();

  @override
  Future<PlacementTestStatus> loadStatus() async =>
      const PlacementTestStatus(hasCompletedPlacementTest: false);

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async => null;

  @override
  Future<PlacementTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();

  @override
  Future<PlacementTestAttempt> start() => throw UnimplementedError();

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) => throw UnimplementedError();
}

class _RouterMentorRepository implements MentorRepository {
  const _RouterMentorRepository();

  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() async => const [];

  @override
  Future<List<WeeklyAvailabilityItem>> loadWeeklySchedule(
    DateTime weekStart,
  ) async => const [];

  @override
  Future<MentorProfileData> loadProfile() async => const MentorProfileData(
        mentorId: 1,
        email: 'mentor@test.com',
      );

  @override
  Future<MentorProfileData> updateProfile({
    String? bio,
    String? expertise,
    String? jlptLevel,
    int? yearsOfExperience,
    String? workplace,
    String? verificationDocumentUrl,
    String? introductionVideoUrl,
  }) async =>
      const MentorProfileData(mentorId: 1, email: 'mentor@test.com');

  @override
  Future<MentorProfileData> submitVerification({
    String? verificationDocumentUrl,
    String? notes,
  }) async =>
      const MentorProfileData(mentorId: 1, email: 'mentor@test.com');

  @override
  Future<MentorProfileData> uploadVerificationDocument({
    required Uint8List bytes,
    required String fileName,
  }) async => const MentorProfileData(
    mentorId: 1, email: 'mentor@test.com', hasVerificationDocument: true);
}

class _RouterProfileRepository implements UserProfileRepository {
  const _RouterProfileRepository({
    this.targetJlptLevelId,
    this.targetJlptLevelName,
    this.targetExamDate,
  });

  final int? targetJlptLevelId;
  final String? targetJlptLevelName;
  final DateTime? targetExamDate;

  UserProfile get _profile => UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Minh Anh',
    lastName: 'Nguyễn',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    currentStudyLevelId: targetJlptLevelId == null ? null : 101,
    currentStudyLevelName: targetJlptLevelId == null ? null : 'N5',
    targetJlptLevelId: targetJlptLevelId,
    targetJlptLevelName: targetJlptLevelName,
    dailyStudyMinutes: 30,
    targetExamDate: targetExamDate,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> loadProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile({required String fullName}) async =>
      _profile;

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async =>
      _profile;

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async => _profile;

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async => _profile;
}

class _FailingStartupProfileRepository extends _RouterProfileRepository {
  const _FailingStartupProfileRepository();

  @override
  Future<UserProfile> loadProfile() async => throw const UnknownError();
}

class _UnauthorizedProfileRepository extends _RouterProfileRepository {
  const _UnauthorizedProfileRepository();

  @override
  Future<UserProfile> loadProfile() async => throw const UnauthorizedError();
}
