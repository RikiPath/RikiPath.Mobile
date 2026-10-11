import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_join_intent_controller.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_join_target.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_join_screen.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';

import '../../support/test_auth_session.dart';

void main() {
  const roomId = '5d75c4cc-5404-4f9a-91e8-b8596f31d2a2';
  const trustedUrl = 'https://riki-path-web.vercel.app/meeting-room/$roomId';

  group('Meeting room input contract', () {
    test('accepts UUID and trusted URL as the same canonical room', () {
      final direct = MeetingJoinTarget.parse('  ${roomId.toUpperCase()}  ');
      final link = MeetingJoinTarget.parse('$trustedUrl/');

      expect(direct.target?.roomId, roomId);
      expect(link.target?.roomId, roomId);
      expect(direct.target?.roomId, link.target?.roomId);
      expect(direct.error, isNull);
      expect(link.error, isNull);
    });

    test('rejects unsafe, untrusted, and malformed inputs', () {
      for (final value in <String>[
        '',
        'not-a-room',
        '5d75c4cc-5404-4f9a-91e8-b8596f31d2',
        'javascript:alert(1)',
        'file:///tmp/$roomId',
        'data:text/plain,$roomId',
        'https://example.com/meeting-room/$roomId',
        'https://riki-path-web.vercel.app/meeting-room/',
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
          .submit(roomId);

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

    testWidgets('valid logged-out room asks for auth and keeps target', (
      tester,
    ) async {
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        authState: AuthSessionState.unauthenticated,
      );
      addTearDown(harness.dispose);

      await tester.enterText(_meetingLinkField, roomId);
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
            ?.roomId,
        roomId,
      );
    });

    testWidgets('pending target survives login and follows rollout policy', (
      tester,
    ) async {
      final launcher = _RecordingLauncher();
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        authState: AuthSessionState.unauthenticated,
        launcher: launcher,
      );
      addTearDown(harness.dispose);
      await tester.enterText(_meetingLinkField, roomId);
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
        harness.container
            .read(meetingJoinIntentControllerProvider)
            .target
            ?.roomId,
        roomId,
      );
      expect(
        tester.widget<TextField>(_meetingLinkField).controller?.text,
        roomId,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_continue_button')),
      );
      await tester.pump(const Duration(seconds: 1));

      if (MeetingNativeRollout.isEnabled) {
        expect(
          find.byKey(const ValueKey<String>('native_meeting_room_screen')),
          findsOneWidget,
        );
        expect(launcher.opened, isEmpty);
      } else {
        expect(
          find.byKey(const ValueKey<String>('native_meeting_room_screen')),
          findsNothing,
        );
        expect(launcher.opened, <String>[trustedUrl]);
      }
      expect(
        harness.container.read(meetingJoinIntentControllerProvider).target,
        isNull,
      );
    });

    testWidgets('untrusted room URL is rejected without launching', (
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
        'https://example.com/meeting-room/$roomId',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_continue_button')),
      );
      await tester.pumpAndSettle();
      expect(launcher.opened, isEmpty);
      expect(
        harness.container.read(meetingJoinIntentControllerProvider).target,
        isNull,
      );
      expect(
        find.text('Mã phòng không hợp lệ. Vui lòng kiểm tra lại.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'trusted room URL follows native default and browser override',
      (tester) async {
        final launcher = _RecordingLauncher();
        final harness = await _pumpMeetingApp(
          tester,
          initialLocation: AppRoutes.meetingJoin,
          launcher: launcher,
        );
        addTearDown(harness.dispose);
        await tester.enterText(_meetingLinkField, '$trustedUrl/');
        await tester.tap(
          find.byKey(const ValueKey<String>('meeting_continue_button')),
        );
        await tester.pump(const Duration(seconds: 1));

        if (!MeetingNativeRollout.isEnabled) {
          expect(
            find.byKey(const ValueKey<String>('native_meeting_room_screen')),
            findsNothing,
          );
          expect(launcher.opened, <String>[trustedUrl]);
          return;
        }

        expect(
          find.byKey(const ValueKey<String>('native_meeting_room_screen')),
          findsOneWidget,
        );
        final microphoneControl = find.byKey(
          const ValueKey<String>('meeting_microphone_control'),
        );
        final cameraControl = find.byKey(
          const ValueKey<String>('meeting_camera_control'),
        );
        expect(
          find.descendant(
            of: microphoneControl,
            matching: find.byIcon(Icons.mic_off_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cameraControl,
            matching: find.byIcon(Icons.videocam_off_rounded),
          ),
          findsOneWidget,
        );
        final microphoneSurface = tester.widget<Material>(
          find.descendant(
            of: microphoneControl,
            matching: find.byType(Material),
          ),
        );
        final cameraSurface = tester.widget<Material>(
          find.descendant(of: cameraControl, matching: find.byType(Material)),
        );
        final disabledMediaColor = const Color(
          0xFFE05A7A,
        ).withValues(alpha: 0.24);
        expect(microphoneSurface.color, disabledMediaColor);
        expect(cameraSurface.color, disabledMediaColor);

        await tester.tap(
          find.byKey(const ValueKey<String>('meeting_leave_control')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final stayFinder = find.byKey(
          const ValueKey<String>('meeting_stay_button'),
        );
        final confirmLeaveFinder = find.byKey(
          const ValueKey<String>('meeting_confirm_leave_button'),
        );
        final stayButton = tester.widget<FilledButton>(stayFinder);
        expect(
          stayButton.style?.backgroundColor?.resolve(<WidgetState>{}),
          Colors.white,
        );
        expect(tester.getSize(stayFinder), tester.getSize(confirmLeaveFinder));
        await tester.tap(stayFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.byKey(const ValueKey<String>('native_meeting_room_screen')),
          findsOneWidget,
        );
        expect(launcher.opened, isEmpty);
      },
    );

    testWidgets('room UUID follows native default and browser override', (
      tester,
    ) async {
      final launcher = _RecordingLauncher();
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        launcher: launcher,
      );
      addTearDown(harness.dispose);

      await tester.enterText(_meetingLinkField, roomId);
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_continue_button')),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byKey(const ValueKey<String>('native_meeting_room_screen')),
        MeetingNativeRollout.isEnabled ? findsOneWidget : findsNothing,
      );
      expect(
        launcher.opened,
        MeetingNativeRollout.isEnabled ? isEmpty : <String>[trustedUrl],
      );
    });

    testWidgets('clipboard is read only after the explicit paste action', (
      tester,
    ) async {
      var clipboardReads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            clipboardReads += 1;
            return <String, Object?>{'text': roomId};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final harness = await _pumpMeetingApp(
        tester,
        initialLocation: AppRoutes.meetingJoin,
        authState: AuthSessionState.unauthenticated,
      );
      addTearDown(harness.dispose);

      expect(tester.widget<TextField>(_meetingLinkField).controller?.text, '');
      expect(clipboardReads, 0);
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_paste_button')),
      );
      await tester.pump();

      expect(
        tester.widget<TextField>(_meetingLinkField).controller?.text,
        roomId,
      );
      expect(clipboardReads, 1);
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
        'data:text/plain,room',
        'https://example.com/meeting-room/$roomId',
        '/relative-room',
      ]) {
        await tester.enterText(_meetingLinkField, value);
        await tester.tap(
          find.byKey(const ValueKey<String>('meeting_continue_button')),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey<String>('native_meeting_room_screen')),
          findsNothing,
        );
        expect(
          harness.container.read(meetingJoinIntentControllerProvider).target,
          isNull,
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
      await tester.enterText(_meetingLinkField, roomId);
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_continue_button')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('booking'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('meeting_cancel_button')),
      );
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
      appConfigProvider.overrideWithValue(AppConfig.fromEnvironment()),
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
