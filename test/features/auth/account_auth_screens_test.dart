import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/verify_email_controller.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';
import 'package:rikipath_mobile/features/auth/presentation/change_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/update_email_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/verify_email_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';

void main() {
  group('VerifyEmailScreen', () {
    testWidgets('missing registration userId renders the confirmed blocker', (
      tester,
    ) async {
      final repository = _AccountAuthRepository();
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(),
        repository: repository,
        session: createTestAuthSession(
          initialState: AuthSessionState.unauthenticated,
        ),
      );

      expect(find.text('Chưa thể tiếp tục từ đăng ký'), findsOneWidget);
      expect(
        tester.widget<TextField>(_textField('verify_email_code_field')).enabled,
        isFalse,
      );
      expect(repository.verifyEmailCalls, 0);
    });

    testWidgets('non-positive registration userId cannot verify email', (
      tester,
    ) async {
      final repository = _AccountAuthRepository();
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(userId: 0),
        repository: repository,
        session: createTestAuthSession(
          initialState: AuthSessionState.unauthenticated,
        ),
      );

      expect(
        tester.widget<TextField>(_textField('verify_email_code_field')).enabled,
        isFalse,
      );
      expect(
        tester
            .widget<RikiPrimaryButton>(
              find.byKey(const Key('verify_email_submit_button')),
            )
            .onPressed,
        isNull,
      );
      expect(repository.verifyEmailCalls, 0);
    });

    testWidgets('empty code validates before repository submission', (
      tester,
    ) async {
      final repository = _AccountAuthRepository();
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(userId: 42),
        repository: repository,
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('verify_email_submit_button')),
      );

      expect(find.text('Vui lòng nhập mã xác thực.'), findsOneWidget);
      expect(repository.verifyEmailCalls, 0);
    });

    testWidgets('incomplete code validates before repository submission', (
      tester,
    ) async {
      final repository = _AccountAuthRepository();
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(userId: 42),
        repository: repository,
      );
      await tester.enterText(_textField('verify_email_code_field'), '12345');

      await _tapVisible(
        tester,
        find.byKey(const Key('verify_email_submit_button')),
      );

      expect(find.text('Mã xác thực phải gồm đúng 6 chữ số.'), findsOneWidget);
      expect(repository.verifyEmailCalls, 0);
    });

    testWidgets('exact request, loading, and success are represented', (
      tester,
    ) async {
      final completer = Completer<void>();
      final repository = _AccountAuthRepository(verifyCompleter: completer);
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(userId: 42),
        repository: repository,
      );
      await tester.enterText(_textField('verify_email_code_field'), ' 123456 ');

      await _tapVisible(
        tester,
        find.byKey(const Key('verify_email_submit_button')),
      );
      await tester.tap(find.byKey(const Key('verify_email_submit_button')));
      await tester.pump();

      expect(find.text('Đang xác thực...'), findsOneWidget);
      expect(repository.verifyEmailCalls, 1);
      expect(repository.lastVerifyRequest?.userId, 42);
      expect(repository.lastVerifyRequest?.verificationCode, '123456');

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.text('Xác thực email thành công'), findsOneWidget);
    });

    testWidgets('code field keeps only the first six digits', (tester) async {
      final repository = _AccountAuthRepository();
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(userId: 42),
        repository: repository,
      );

      await tester.enterText(
        _textField('verify_email_code_field'),
        '12a3 4567',
      );

      expect(
        tester
            .widget<TextField>(_textField('verify_email_code_field'))
            .controller
            ?.text,
        '123456',
      );
    });

    testWidgets('invalid backend code renders controlled feedback', (
      tester,
    ) async {
      final repository = _AccountAuthRepository(
        verifyError: const ValidationError(
          message: 'Mã xác thực không hợp lệ hoặc đã được sử dụng.',
        ),
      );
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(userId: 42),
        repository: repository,
      );
      await tester.enterText(_textField('verify_email_code_field'), '000000');

      await _tapVisible(
        tester,
        find.byKey(const Key('verify_email_submit_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể xác thực email'), findsOneWidget);
      expect(find.textContaining('không hợp lệ'), findsOneWidget);
    });

    testWidgets('resend sends exact email and blocks duplicate taps', (
      tester,
    ) async {
      final clock = _MutableClock();
      final completer = Completer<void>();
      final repository = _AccountAuthRepository(resendCompleter: completer);
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(
          userId: 42,
          email: ' learner@example.com ',
        ),
        repository: repository,
        now: clock.call,
      );

      expect(find.text('Gửi lại mã sau 01:00'), findsOneWidget);
      clock.advance(const Duration(seconds: 60));
      _refreshVerifyEmailCooldown(tester);
      await tester.pump();

      final resendButton = find.byKey(const Key('verify_email_resend_button'));
      await tester.ensureVisible(resendButton);
      await tester.tap(resendButton);
      await tester.tap(resendButton);
      await tester.pump();

      expect(repository.resendVerificationCalls, 1);
      expect(repository.lastResendRequest?.email, 'learner@example.com');
      expect(find.byKey(const Key('verify_email_resend_button')), findsNothing);

      completer.complete();
      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('verify_email_resend_success')),
        findsOneWidget,
      );
      expect(find.text('Gửi lại mã sau 01:00'), findsOneWidget);
      expect(repository.verifyEmailCalls, 0);
    });

    testWidgets('resend error preserves the entered verification code', (
      tester,
    ) async {
      final clock = _MutableClock();
      final repository = _AccountAuthRepository(
        resendError: const ValidationError(message: 'Please try again.'),
      );
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(
          userId: 42,
          email: 'learner@example.com',
        ),
        repository: repository,
        now: clock.call,
      );
      await tester.enterText(_textField('verify_email_code_field'), '123456');
      clock.advance(const Duration(seconds: 60));
      _refreshVerifyEmailCooldown(tester);
      await tester.pump();

      await _tapVisible(
        tester,
        find.byKey(const Key('verify_email_resend_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('verify_email_resend_error')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(_textField('verify_email_code_field'))
            .controller
            ?.text,
        '123456',
      );
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(repository.verifyEmailCalls, 0);
    });

    testWidgets(
      'initial cooldown masks email and follows elapsed wall-clock time',
      (tester) async {
        final clock = _MutableClock();
        final repository = _AccountAuthRepository();
        await _pumpScreen(
          tester,
          screen: const VerifyEmailScreen(
            userId: 42,
            email: 'name@example.com',
          ),
          repository: repository,
          now: clock.call,
        );

        expect(find.text('n***@example.com'), findsOneWidget);
        expect(find.text('42'), findsNothing);
        expect(find.text('Gửi lại mã sau 01:00'), findsOneWidget);
        expect(
          tester
              .widget<RikiTextButton>(
                find.byKey(const Key('verify_email_resend_button')),
              )
              .onPressed,
          isNull,
        );

        await tester.pump();
        expect(find.text('Gửi lại mã sau 01:00'), findsOneWidget);

        clock.advance(const Duration(seconds: 30));
        _refreshVerifyEmailCooldown(tester);
        await tester.pump();
        expect(find.text('Gửi lại mã sau 00:30'), findsOneWidget);

        clock.advance(const Duration(seconds: 30));
        _refreshVerifyEmailCooldown(tester);
        await tester.pump();
        expect(find.text('Gửi lại mã'), findsOneWidget);
        expect(
          tester
              .widget<RikiTextButton>(
                find.byKey(const Key('verify_email_resend_button')),
              )
              .onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('network-ambiguous resend failure restarts safe cooldown', (
      tester,
    ) async {
      final clock = _MutableClock();
      final repository = _AccountAuthRepository(
        resendError: const NetworkError(),
      );
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(
          userId: 42,
          email: 'learner@example.com',
        ),
        repository: repository,
        now: clock.call,
      );
      clock.advance(const Duration(seconds: 60));
      _refreshVerifyEmailCooldown(tester);
      await tester.pump();

      await _tapVisible(
        tester,
        find.byKey(const Key('verify_email_resend_button')),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('verify_email_resend_error')),
        findsOneWidget,
      );
      expect(find.text('Gửi lại mã sau 01:00'), findsOneWidget);
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
    });

    testWidgets('hourly resend limit is shown with safe localized feedback', (
      tester,
    ) async {
      final clock = _MutableClock();
      final repository = _AccountAuthRepository(
        resendError: const ValidationError(
          message: 'Bạn đã vượt quá số lần gửi lại email trong 1 giờ.',
        ),
      );
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(
          userId: 42,
          email: 'learner@example.com',
        ),
        repository: repository,
        now: clock.call,
      );
      clock.advance(const Duration(seconds: 60));
      _refreshVerifyEmailCooldown(tester);
      await tester.pump();

      await _tapVisible(
        tester,
        find.byKey(const Key('verify_email_resend_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Bạn đã yêu cầu gửi lại mã quá nhiều lần. Vui lòng thử lại sau.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('1 giờ'), findsNothing);
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
    });

    testWidgets('Japanese resend UI is localized without layout errors', (
      tester,
    ) async {
      final clock = _MutableClock();
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(
          userId: 42,
          email: 'learner@example.com',
        ),
        repository: _AccountAuthRepository(),
        now: clock.call,
        locale: const Locale('ja'),
        physicalSize: const Size(320, 844),
      );

      expect(find.text('コードが届きませんか？'), findsOneWidget);
      expect(find.text('01:00後にコードを再送信'), findsOneWidget);
      expect(find.text('l***@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposing Verify Email cleans its cooldown ticker', (
      tester,
    ) async {
      final clock = _MutableClock();
      await _pumpScreen(
        tester,
        screen: const VerifyEmailScreen(
          userId: 42,
          email: 'learner@example.com',
        ),
        repository: _AccountAuthRepository(),
        now: clock.call,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      clock.advance(const Duration(minutes: 2));
      await tester.pump(const Duration(minutes: 2));

      expect(tester.takeException(), isNull);
    });
  });

  group('UpdateEmailScreen', () {
    testWidgets('uses session userId and exact newEmail request', (
      tester,
    ) async {
      final completer = Completer<void>();
      final repository = _AccountAuthRepository(updateCompleter: completer);
      await _pumpScreen(
        tester,
        screen: const UpdateEmailScreen(),
        repository: repository,
        session: createTestAuthSession(userId: 42),
      );
      expect(find.byKey(const Key('update_email_user_id_field')), findsNothing);
      await tester.enterText(
        _textField('update_email_field'),
        ' new@example.com ',
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('update_email_submit_button')),
      );

      expect(find.text('Đang cập nhật...'), findsOneWidget);
      expect(repository.updateEmailCalls, 1);
      expect(repository.lastUpdateUserId, 42);
      expect(repository.lastUpdateRequest?.newEmail, 'new@example.com');

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Email đã được cập nhật'), findsOneWidget);
      expect(
        find.byKey(const Key('update_email_verify_action')),
        findsOneWidget,
      );
    });

    testWidgets('backend failure is controlled and keeps the session', (
      tester,
    ) async {
      final session = createTestAuthSession(userId: 42);
      final repository = _AccountAuthRepository(
        updateError: const ValidationError(
          message: 'Email mới đã được sử dụng bởi tài khoản khác.',
        ),
      );
      await _pumpScreen(
        tester,
        screen: const UpdateEmailScreen(),
        repository: repository,
        session: session,
      );
      await tester.enterText(
        _textField('update_email_field'),
        'used@example.com',
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('update_email_submit_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể đổi email'), findsOneWidget);
      expect(session.value, AuthSessionState.authenticated);
      expect(session.currentUserId, 42);
    });
  });

  group('ChangePasswordScreen', () {
    testWidgets('validates all password fields locally', (tester) async {
      final repository = _AccountAuthRepository();
      await _pumpScreen(
        tester,
        screen: const ChangePasswordScreen(),
        repository: repository,
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('change_password_submit_button')),
      );

      expect(find.text('Vui lòng nhập mật khẩu.'), findsNWidgets(2));
      expect(find.text('Vui lòng xác nhận mật khẩu.'), findsOneWidget);
      expect(repository.changePasswordCalls, 0);
    });

    testWidgets('uses session userId, exact request, loading, and success', (
      tester,
    ) async {
      final completer = Completer<void>();
      final repository = _AccountAuthRepository(changeCompleter: completer);
      final session = createTestAuthSession(userId: 42);
      await _pumpScreen(
        tester,
        screen: const ChangePasswordScreen(),
        repository: repository,
        session: session,
      );
      await tester.enterText(
        _textField('change_password_current_field'),
        'current-secret',
      );
      await tester.enterText(
        _textField('change_password_new_field'),
        'new-secret',
      );
      await tester.enterText(
        _textField('change_password_confirm_field'),
        'new-secret',
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('change_password_submit_button')),
      );

      expect(find.text('Đang cập nhật...'), findsOneWidget);
      expect(repository.changePasswordCalls, 1);
      expect(repository.lastChangeUserId, 42);
      expect(repository.lastChangeRequest?.currentPassword, 'current-secret');
      expect(repository.lastChangeRequest?.newPassword, 'new-secret');
      expect(repository.lastChangeRequest?.confirmPassword, 'new-secret');

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Mật khẩu đã được cập nhật'), findsOneWidget);
      expect(session.value, AuthSessionState.authenticated);
      expect(session.currentUserId, 42);
      expect(
        tester
            .widget<TextField>(_textField('change_password_current_field'))
            .controller
            ?.text,
        isEmpty,
      );
    });

    testWidgets('backend failure is mapped without ending the session', (
      tester,
    ) async {
      final session = createTestAuthSession(userId: 42);
      final repository = _AccountAuthRepository(
        changeError: const ValidationError(
          message: 'Mật khẩu hiện tại không đúng.',
        ),
      );
      await _pumpScreen(
        tester,
        screen: const ChangePasswordScreen(),
        repository: repository,
        session: session,
      );
      await tester.enterText(
        _textField('change_password_current_field'),
        'wrong-secret',
      );
      await tester.enterText(
        _textField('change_password_new_field'),
        'new-secret',
      );
      await tester.enterText(
        _textField('change_password_confirm_field'),
        'new-secret',
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('change_password_submit_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể đổi mật khẩu'), findsOneWidget);
      expect(session.value, AuthSessionState.authenticated);
    });
  });
}

class _AccountAuthRepository implements AuthRepository {
  _AccountAuthRepository({
    this.verifyCompleter,
    this.resendCompleter,
    this.updateCompleter,
    this.changeCompleter,
    this.verifyError,
    this.resendError,
    this.updateError,
    this.changeError,
  });

  final Completer<void>? verifyCompleter;
  final Completer<void>? resendCompleter;
  final Completer<void>? updateCompleter;
  final Completer<void>? changeCompleter;
  final Object? verifyError;
  final Object? resendError;
  final Object? updateError;
  final Object? changeError;

  int verifyEmailCalls = 0;
  int resendVerificationCalls = 0;
  int updateEmailCalls = 0;
  int changePasswordCalls = 0;
  VerifyEmailRequestDto? lastVerifyRequest;
  ResendVerificationEmailRequestDto? lastResendRequest;
  int? lastUpdateUserId;
  UpdateEmailRequestDto? lastUpdateRequest;
  int? lastChangeUserId;
  ChangePasswordRequestDto? lastChangeRequest;

  @override
  Future<void> verifyEmail(VerifyEmailRequestDto request) {
    verifyEmailCalls += 1;
    lastVerifyRequest = request;
    if (verifyError != null) return Future.error(verifyError!);
    return verifyCompleter?.future ?? Future.value();
  }

  @override
  Future<void> resendVerificationEmail(
    ResendVerificationEmailRequestDto request,
  ) {
    resendVerificationCalls += 1;
    lastResendRequest = request;
    if (resendError != null) return Future.error(resendError!);
    return resendCompleter?.future ?? Future.value();
  }

  @override
  Future<void> updateEmail(int userId, UpdateEmailRequestDto request) {
    updateEmailCalls += 1;
    lastUpdateUserId = userId;
    lastUpdateRequest = request;
    if (updateError != null) return Future.error(updateError!);
    return updateCompleter?.future ?? Future.value();
  }

  @override
  Future<void> changePassword(int userId, ChangePasswordRequestDto request) {
    changePasswordCalls += 1;
    lastChangeUserId = userId;
    lastChangeRequest = request;
    if (changeError != null) return Future.error(changeError!);
    return changeCompleter?.future ?? Future.value();
  }

  @override
  Future<LoginResponseDto> login(
    LoginRequestDto request, {
    required bool persistSession,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RegisterResponseDto> register(RegisterRequestDto request) {
    throw UnimplementedError();
  }

  @override
  Future<void> requestPasswordReset(String email) {
    throw UnimplementedError();
  }
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required Widget screen,
  required AuthRepository repository,
  AuthSessionController? session,
  DateTime Function()? now,
  Locale locale = const Locale('vi'),
  Size physicalSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final authSession = session ?? createTestAuthSession(userId: 42);
  addTearDown(authSession.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authSessionControllerProvider.overrideWithValue(authSession),
        if (now != null) verifyEmailClockProvider.overrideWithValue(now),
        localeControllerProvider.overrideWith(
          () => _AccountTestLocaleController(locale),
        ),
        userProfileRepositoryProvider.overrideWithValue(
          const _AccountProfileRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

class _MutableClock {
  DateTime _now = DateTime.utc(2026, 10, 3, 8);

  DateTime call() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

class _AccountTestLocaleController extends LocaleController {
  _AccountTestLocaleController(this.initialLocale);

  final Locale initialLocale;

  @override
  Locale build() => initialLocale;

  @override
  Future<void> changeLocale(Locale locale) async => state = locale;
}

class _AccountProfileRepository implements UserProfileRepository {
  const _AccountProfileRepository();

  static const _profile = UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Minh Anh',
    lastName: 'Nguyễn',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: 73,
    targetJlptLevelName: 'N3',
    dailyStudyMinutes: 30,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: false,
  );

  @override
  Future<UserProfile> loadProfile() async => _profile;

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

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async => _profile;

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async =>
      _profile;
}

Finder _textField(String key) {
  return find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

void _refreshVerifyEmailCooldown(WidgetTester tester) {
  final observer =
      tester.state(find.byType(VerifyEmailScreen)) as WidgetsBindingObserver;
  observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
}
