import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
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
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_repository.dart';
import 'package:rikipath_mobile/features/mentor/presentation/mentor_home_screen.dart';
import 'package:rikipath_mobile/features/notebook/presentation/notebook_screen.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/jlpt_goal_screen.dart';
import 'package:rikipath_mobile/features/profile/presentation/notification_settings_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jwt.dart';

void main() {
  test('route constants expose the supported navigation paths', () {
    expect(AppRoutes.splash, '/splash');
    expect(AppRoutes.login, '/auth/login');
    expect(AppRoutes.register, '/auth/register');
    expect(AppRoutes.forgotPassword, '/auth/forgot-password');
    expect(AppRoutes.verifyEmail, '/auth/verify-email');
    expect(AppRoutes.unsupportedRole, '/auth/unsupported-role');
    expect(AppRoutes.onboarding, '/onboarding');
    expect(AppRoutes.mentor, '/mentor');
    expect(AppRoutes.mentorAvailability, '/mentor/availability');
    expect(AppRoutes.mentorMeetings, '/mentor/meetings');
    expect(AppRoutes.mentorMeetingDetail(17), '/mentor/meetings/17');
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
    expect(find.byType(JlptGoalScreen), findsOneWidget);

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

  testWidgets('account logout clears the session and returns to Login', (
    tester,
  ) async {
    final session = createTestAuthSession(userId: 42);
    final router = await _pumpRouter(
      tester,
      initialLocation: AppRoutes.profileAccount,
      authSession: session,
    );
    await tester.pumpAndSettle();

    final logout = find.byKey(const Key('account_logout_button'));
    await tester.scrollUntilVisible(
      logout,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(logout);
    await tester.pumpAndSettle();

    expect(session.value, AuthSessionState.authenticated);
    await tester.tap(find.byKey(const Key('account_logout_confirm_button')));
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

  testWidgets('authenticated auth route redirects once to learner home', (
    tester,
  ) async {
    await _pumpRouter(tester, initialLocation: AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated learner cannot remain on verify-email', (
    tester,
  ) async {
    await _pumpRouter(tester, initialLocation: AppRoutes.verifyEmail);
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
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
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
    expect(find.byType(RikiBottomNavigationBar), findsNothing);
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
        matchedLocation: AppRoutes.mentorMeetings,
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
        authState: AuthSessionState.unauthenticated,
        role: null,
        matchedLocation: AppRoutes.verifyEmail,
      ),
      isNull,
    );
    expect(
      authRouteRedirect(
        authState: AuthSessionState.authenticated,
        role: BackendUserRole.learner,
        matchedLocation: AppRoutes.verifyEmail,
      ),
      AppRoutes.home,
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
        userProfileRepositoryProvider.overrideWithValue(profileRepository),
        mentorRepositoryProvider.overrideWithValue(mentorRepository),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
  return router;
}

class _RouterMentorRepository implements MentorRepository {
  const _RouterMentorRepository();

  @override
  Future<List<MentorAvailabilitySlot>> loadAvailability() async => const [];

  @override
  Future<List<MentorMeetingSummary>> loadMeetings() async => const [];
}

class _RouterProfileRepository implements UserProfileRepository {
  const _RouterProfileRepository();

  UserProfile get _profile => const UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Minh Anh',
    lastName: 'Nguyễn',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: null,
    targetJlptLevelName: null,
    dailyStudyMinutes: 30,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> loadProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async => _profile;

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

class _UnauthorizedProfileRepository extends _RouterProfileRepository {
  const _UnauthorizedProfileRepository();

  @override
  Future<UserProfile> loadProfile() async => throw const UnauthorizedError();
}
