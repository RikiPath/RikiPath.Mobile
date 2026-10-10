import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_join_intent_controller.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_join_target.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_join_screen.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';

import '../../support/test_auth_session.dart';

void main() {
  group('Meeting link contract', () {
    test('accepts only absolute HTTP and HTTPS links', () {
      expect(
        MeetingJoinTarget.parse('https://meet.example.com/room').target,
        isNotNull,
      );
      expect(
        MeetingJoinTarget.parse('http://meet.example.com/room').target,
        isNotNull,
      );
      for (final value in <String>[
        '',
        'javascript:alert(1)',
        'file:///tmp/room',
        'data:text/plain,room',
        '/relative-room',
        'not a link',
      ]) {
        expect(MeetingJoinTarget.parse(value).target, isNull, reason: value);
      }
    });

    test('logout clears an authenticated pending intent', () async {
      final session = createTestAuthSession();
      final container = ProviderContainer(
        overrides: [authSessionControllerProvider.overrideWithValue(session)],
      );
      addTearDown(container.dispose);
      addTearDown(session.dispose);
      container
          .read(meetingJoinIntentControllerProvider.notifier)
          .submit('https://meet.example.com/private-room');

      expect(
        container.read(meetingJoinIntentControllerProvider).hasPendingTarget,
        isTrue,
      );
      await session.signOut();
      expect(
        container.read(meetingJoinIntentControllerProvider).hasPendingTarget,
        isFalse,
      );
    });
  });

  group('Meeting join flow', () {
    testWidgets('logged-out Login exposes a secondary Meeting entry', (
      tester,
    ) async {
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.login,
        authState: AuthSessionState.unauthenticated,
      );
      addTearDown(harness.dispose);

      expect(
        find.byKey(const ValueKey<String>('login_meeting_join_button')),
        findsOneWidget,
      );
    });

    testWidgets('valid logged-out link asks for auth and keeps target', (
      tester,
    ) async {
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        authState: AuthSessionState.unauthenticated,
      );
      addTearDown(harness.dispose);

      await tester.enterText(
        _meetingLinkField,
        'https://meet.example.com/private-room',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_continue_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('meeting_auth_required')),
        findsOneWidget,
      );
      expect(
        harness.container
            .read(meetingJoinIntentControllerProvider)
            .target
            ?.uri
            .toString(),
        'https://meet.example.com/private-room',
      );
    });

    testWidgets('pending target survives login and returns to pre-join', (
      tester,
    ) async {
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        authState: AuthSessionState.unauthenticated,
      );
      addTearDown(harness.dispose);
      await tester.enterText(
        _meetingLinkField,
        'https://meet.example.com/private-room',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_continue_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_login_button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_textField('login_email_field'), 'a@b.com');
      await tester.enterText(_textField('login_password_field'), 'secret');
      final submit = find.byKey(const ValueKey<String>('login_submit_button'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.byType(MeetingJoinScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('meeting_prejoin_card')),
        findsOneWidget,
      );
      expect(
        harness.container
            .read(meetingJoinIntentControllerProvider)
            .target
            ?.uri
            .toString(),
        'https://meet.example.com/private-room',
      );
    });

    testWidgets('authenticated valid link opens externally once', (
      tester,
    ) async {
      final launcher = _RecordingLauncher();
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        launcher: launcher,
      );
      addTearDown(harness.dispose);
      await tester.enterText(
        _meetingLinkField,
        'https://meet.example.com/private-room',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_continue_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_open_button')),
      );
      await tester.pumpAndSettle();

      expect(launcher.opened, <String>[
        'https://meet.example.com/private-room',
      ]);
      expect(
        harness.container.read(meetingJoinIntentControllerProvider).target,
        isNull,
      );
    });

    testWidgets('invalid and empty links never navigate or launch', (
      tester,
    ) async {
      final launcher = _RecordingLauncher();
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        launcher: launcher,
      );
      addTearDown(harness.dispose);

      for (final value in <String>[
        '',
        'javascript:alert(1)',
        'file:///tmp/room',
        '/relative-room',
      ]) {
        await tester.enterText(_meetingLinkField, value);
        await tester.tap(
          find.byKey(const ValueKey<String>('meeting_continue_button')),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey<String>('meeting_open_button')),
          findsNothing,
        );
      }
      expect(launcher.opened, isEmpty);
    });

    testWidgets('cancel clears the pending target without booking UI', (
      tester,
    ) async {
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        authState: AuthSessionState.unauthenticated,
      );
      addTearDown(harness.dispose);
      await tester.enterText(
        _meetingLinkField,
        'https://meet.example.com/private-room',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_continue_button')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('booking'), findsNothing);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(
        harness.container.read(meetingJoinIntentControllerProvider).target,
        isNull,
      );
      expect(
        find.byKey(const ValueKey<String>('meeting_landing_screen')),
        findsOneWidget,
      );
    });
  });
}

Finder get _meetingLinkField => find.descendant(
  of: find.byKey(const ValueKey<String>('meeting_link_field')),
  matching: find.byType(TextField),
);

Finder _textField(String key) => find.descendant(
  of: find.byKey(ValueKey<String>(key)),
  matching: find.byType(TextField),
);

class _MeetingHarness {
  const _MeetingHarness(this.container, this.router, this.session);

  final ProviderContainer container;
  final GoRouter router;
  final AuthSessionController session;

  void dispose() {
    router.dispose();
    container.dispose();
    session.dispose();
  }
}

Future<_MeetingHarness> _pumpMeetingApp(
  WidgetTester tester, {
  required String initialLocation,
  AuthSessionState authState = AuthSessionState.authenticated,
  MentorMeetingLinkLauncher? launcher,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final session = createTestAuthSession(initialState: authState);
  final router = createAppRouter(
    authSession: session,
    initialLocation: initialLocation,
  );
  final container = ProviderContainer(
    overrides: [
      authSessionControllerProvider.overrideWithValue(session),
      authRepositoryProvider.overrideWithValue(
        const _SuccessfulAuthRepository(),
      ),
      mentorMeetingLinkLauncherProvider.overrideWithValue(
        launcher ?? _RecordingLauncher(),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) =>
            RikiToastHost(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _MeetingHarness(container, router, session);
}

class _RecordingLauncher implements MentorMeetingLinkLauncher {
  final List<String> opened = <String>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri.toString());
    return true;
  }
}

class _SuccessfulAuthRepository implements AuthRepository {
  const _SuccessfulAuthRepository();

  @override
  Future<LoginResponseDto> login(
    LoginRequestDto request, {
    required bool persistSession,
  }) async => const LoginResponseDto(
    accessToken: 'test-token',
    userId: 42,
    email: 'a@b.com',
    fullName: 'Learner',
    role: BackendUserRole.learner,
  );

  @override
  Future<void> changePassword(int userId, ChangePasswordRequestDto request) =>
      Future<void>.value();

  @override
  Future<void> requestPasswordReset(String email) => Future<void>.value();

  @override
  Future<RegisterResponseDto> register(RegisterRequestDto request) =>
      throw UnimplementedError();

  @override
  Future<void> resendVerificationEmail(
    ResendVerificationEmailRequestDto request,
  ) => Future<void>.value();

  @override
  Future<void> updateEmail(int userId, UpdateEmailRequestDto request) =>
      Future<void>.value();

  @override
  Future<void> verifyEmail(VerifyEmailRequestDto request) =>
      Future<void>.value();
}
