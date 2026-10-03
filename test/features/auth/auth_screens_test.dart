import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/verify_email_controller.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/register_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/verify_email_screen.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders the approved major content', (tester) async {
      await _pumpAuthRoute(tester, AppRoutes.login, _FakeAuthRepository());

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('RikiPath'), findsOneWidget);
      expect(find.text('N4'), findsNothing);
      expect(find.text('Chào mừng trở lại! 👋'), findsOneWidget);
      expect(find.text('Email học viên'), findsOneWidget);
      expect(find.text('Mẹo đăng nhập'), findsOneWidget);
      expect(find.text('Bảo mật chuẩn mã hóa Riki Learning'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(_textField('login_password_field'))
            .decoration
            ?.hintText,
        'Nhập mật khẩu',
      );

      final promptFinder = find.text('Chưa có tài khoản?');
      final actionFinder = find.text('Đăng ký');
      final promptBox = tester.renderObject<RenderBox>(promptFinder);
      final actionBox = tester.renderObject<RenderBox>(actionFinder);
      final promptBaseline =
          tester.getTopLeft(promptFinder).dy +
          promptBox.getDryBaseline(
            promptBox.constraints,
            TextBaseline.alphabetic,
          )!;
      final actionBaseline =
          tester.getTopLeft(actionFinder).dy +
          actionBox.getDryBaseline(
            actionBox.constraints,
            TextBaseline.alphabetic,
          )!;
      expect(
        (promptBaseline - actionBaseline).abs(),
        lessThanOrEqualTo(0.5),
        reason:
            'Prompt ${tester.getSize(find.text('Chưa có tài khoản?'))} and '
            'action ${tester.getSize(find.text('Đăng ký'))} should share a baseline.',
      );

      final forgotPasswordText = tester.getRect(find.text('Quên mật khẩu?'));
      final rememberText = tester.getRect(
        find.text('Ghi nhớ phiên đăng nhập trên thiết bị này'),
      );
      final checkbox = tester.getRect(find.byType(Checkbox));
      final submitButton = tester.getRect(
        find.byKey(const Key('login_submit_button')),
      );
      expect(
        rememberText.top - forgotPasswordText.bottom,
        lessThanOrEqualTo(AppSpacing.space6),
      );
      expect(
        submitButton.top - rememberText.bottom,
        lessThanOrEqualTo(AppSpacing.space6),
      );
      expect(
        rememberText.left - checkbox.right,
        lessThanOrEqualTo(AppSpacing.space1),
      );
      expect(
        checkbox.center.dy - rememberText.center.dy,
        1,
        reason: 'The label needs a slight optical lift beside the checkbox.',
      );
    });

    testWidgets('empty form prevents repository submission', (tester) async {
      final repository = _FakeAuthRepository();
      await _pumpAuthRoute(tester, AppRoutes.login, repository);

      await _tapVisible(tester, find.byKey(const Key('login_submit_button')));

      expect(repository.loginCalls, 0);
    });

    testWidgets('invalid email and empty password show field errors', (
      tester,
    ) async {
      await _pumpAuthRoute(tester, AppRoutes.login, _FakeAuthRepository());
      await tester.enterText(_textField('login_email_field'), 'minhanh@');

      await _tapVisible(tester, find.byKey(const Key('login_submit_button')));

      expect(
        find.text('Email không hợp lệ. Vui lòng kiểm tra lại định dạng.'),
        findsOneWidget,
      );
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    });

    testWidgets('language switch clears stale localized validation feedback', (
      tester,
    ) async {
      await _pumpAuthRoute(tester, AppRoutes.login, _FakeAuthRepository());

      await _tapVisible(tester, find.byKey(const Key('login_submit_button')));
      expect(find.text('Vui lòng nhập email.'), findsOneWidget);

      await _tapVisible(
        tester,
        find.byKey(const Key('language_switcher_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language_option_ja')));
      await tester.pumpAndSettle();

      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('Vui lòng nhập email.'), findsNothing);
      expect(find.text('Vui lòng nhập mật khẩu.'), findsNothing);
    });

    testWidgets('password visibility toggle changes obscuring', (tester) async {
      await _pumpAuthRoute(tester, AppRoutes.login, _FakeAuthRepository());

      expect(
        tester
            .widget<TextField>(_textField('login_password_field'))
            .obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(_textField('login_password_field'))
            .obscureText,
        isFalse,
      );
    });

    testWidgets('loading state prevents duplicate login submission', (
      tester,
    ) async {
      final completer = Completer<LoginResponseDto>();
      final repository = _FakeAuthRepository(loginCompleter: completer);
      await _pumpAuthRoute(tester, AppRoutes.login, repository);
      await tester.enterText(
        _textField('login_email_field'),
        'learner@example.com',
      );
      await tester.enterText(_textField('login_password_field'), 'secret');

      await _tapVisible(tester, find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('Đang đăng nhập...'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(repository.loginCalls, 1);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(repository.loginCalls, 1);

      completer.complete(_loginResponse);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Đăng nhập thành công'), findsOneWidget);
      expect(find.text('Chào mừng bạn trở lại với RikiPath.'), findsOneWidget);
    });

    testWidgets('forgot-password action opens the canonical route', (
      tester,
    ) async {
      final router = await _pumpAuthRoute(
        tester,
        AppRoutes.login,
        _FakeAuthRepository(),
      );

      final passwordBottom = tester
          .getBottomLeft(find.byKey(const Key('login_password_field')))
          .dy;
      final forgotPasswordTop = tester
          .getTopLeft(find.byKey(const Key('forgot_password_button')))
          .dy;
      expect(forgotPasswordTop, greaterThanOrEqualTo(passwordBottom));

      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(router.canPop(), isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('register action preserves Login for Android Back', (
      tester,
    ) async {
      final router = await _pumpAuthRoute(
        tester,
        AppRoutes.login,
        _FakeAuthRepository(),
      );

      await _tapVisible(tester, find.text('Đăng ký'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(router.canPop(), isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('invalid credentials render mapped server feedback', (
      tester,
    ) async {
      final repository = _FakeAuthRepository(
        loginError: const UnauthorizedError(),
      );
      await _pumpAuthRoute(tester, AppRoutes.login, repository);
      await tester.enterText(
        _textField('login_email_field'),
        'learner@example.com',
      );
      await tester.enterText(_textField('login_password_field'), 'secret');

      await _tapVisible(tester, find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Không thể đăng nhập'), findsOneWidget);
      expect(
        find.textContaining('Email hoặc mật khẩu không đúng'),
        findsOneWidget,
      );
    });
  });

  group('RegisterScreen', () {
    testWidgets('required transport fields validate before submission', (
      tester,
    ) async {
      final repository = _FakeAuthRepository();
      await _pumpAuthRoute(tester, AppRoutes.register, repository);

      expect(
        tester
            .widget<TextField>(_textField('register_full_name_field'))
            .decoration
            ?.hintText,
        'Nguyễn Minh Anh',
      );
      expect(
        tester
            .widget<TextField>(_textField('register_password_field'))
            .decoration
            ?.hintText,
        'Nhập mật khẩu',
      );
      expect(
        tester
            .widget<TextField>(_textField('register_confirm_password_field'))
            .decoration
            ?.hintText,
        'Nhập lại mật khẩu',
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('register_submit_button')),
      );

      expect(find.text('Vui lòng nhập email.'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
      expect(find.text('Vui lòng xác nhận mật khẩu.'), findsOneWidget);
      expect(repository.registerCalls, 0);
    });

    testWidgets('password confirmation mismatch is shown', (tester) async {
      await _pumpAuthRoute(tester, AppRoutes.register, _FakeAuthRepository());
      await tester.enterText(
        _textField('register_email_field'),
        'learner@example.com',
      );
      await tester.enterText(_textField('register_password_field'), 'secret');
      await tester.enterText(
        _textField('register_confirm_password_field'),
        'different',
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('register_submit_button')),
      );

      expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
    });

    testWidgets('language switch clears stale registration validation', (
      tester,
    ) async {
      await _pumpAuthRoute(tester, AppRoutes.register, _FakeAuthRepository());

      await _tapVisible(
        tester,
        find.byKey(const Key('register_submit_button')),
      );
      expect(find.text('Vui lòng nhập email.'), findsOneWidget);

      await _tapVisible(
        tester,
        find.byKey(const Key('language_switcher_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language_option_ja')));
      await tester.pumpAndSettle();

      expect(find.text('新規登録'), findsWidgets);
      expect(find.text('Vui lòng nhập email.'), findsNothing);
      expect(find.text('Vui lòng nhập mật khẩu.'), findsNothing);
    });

    testWidgets('loading state is represented and disables submit', (
      tester,
    ) async {
      final completer = Completer<RegisterResponseDto>();
      final repository = _FakeAuthRepository(registerCompleter: completer);
      await _pumpAuthRoute(tester, AppRoutes.register, repository);
      await tester.enterText(
        _textField('register_full_name_field'),
        '  Nguyễn   Minh Anh  ',
      );
      await tester.enterText(
        _textField('register_email_field'),
        'learner@example.com',
      );
      await tester.enterText(_textField('register_password_field'), 'secret');
      await tester.enterText(
        _textField('register_confirm_password_field'),
        'secret',
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('register_submit_button')),
      );
      await tester.pump();

      expect(find.text('Đang tạo tài khoản...'), findsOneWidget);
      expect(
        tester
            .widget<RikiPrimaryButton>(
              find.byKey(const Key('register_submit_button')),
            )
            .isLoading,
        isTrue,
      );
      expect(repository.registerCalls, 1);
      expect(repository.lastRegisterRequest?.lastName, 'Nguyễn');
      expect(repository.lastRegisterRequest?.firstName, 'Minh Anh');

      completer.complete(_registerResponse);
      await tester.pumpAndSettle();
      expect(find.text('Tạo tài khoản thành công'), findsNWidgets(2));
    });

    testWidgets(
      'success celebration runs once without layout shift and keeps navigation',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          var hapticCount = 0;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'HapticFeedback.vibrate') hapticCount += 1;
              return null;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(SystemChannels.platform, null),
          );

          await _pumpAuthRoute(
            tester,
            AppRoutes.register,
            _FakeAuthRepository(),
          );
          await _registerSuccessfully(tester);

          final celebration = find.byKey(
            const Key('register_success_celebration'),
          );
          expect(celebration, findsOneWidget);
          final initialRect = tester.getRect(celebration);

          await tester.pump(const Duration(milliseconds: 250));
          expect(tester.getRect(celebration), initialRect);
          expect(tester.takeException(), isNull);

          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
          expect(tester.getRect(celebration), initialRect);
          expect(hapticCount, 1);
          expect(tester.binding.hasScheduledFrame, isFalse);

          await _tapVisible(tester, find.text('Quay lại đăng nhập'));
          await tester.pumpAndSettle();
          expect(find.byType(LoginScreen), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('success celebration respects reduced motion at narrow width', (
      tester,
    ) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pumpAuthRoute(tester, AppRoutes.register, _FakeAuthRepository());
      await _registerSuccessfully(tester);
      tester.view.physicalSize = const Size(360, 844);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('register_success_celebration')),
        findsOneWidget,
      );
      expect(find.text('Tạo tài khoản thành công'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('successful register hands its userId to Verify Email', (
      tester,
    ) async {
      final clock = _MutableClock();
      final repository = _FakeAuthRepository();
      await _pumpAuthRoute(
        tester,
        AppRoutes.register,
        repository,
        now: clock.call,
      );
      await _registerSuccessfully(tester);
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('register_open_verify_email_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(_textField('verify_email_code_field')).enabled,
        isTrue,
      );
      expect(find.text('Chưa thể tiếp tục từ đăng ký'), findsNothing);
      expect(find.text('l***@example.com'), findsOneWidget);
      expect(find.text('Gửi lại mã sau 01:00'), findsOneWidget);

      clock.advance(const Duration(seconds: 60));
      final observer =
          tester.state(find.byType(VerifyEmailScreen))
              as WidgetsBindingObserver;
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();

      await _tapVisible(
        tester,
        find.byKey(const Key('verify_email_resend_button')),
      );
      expect(repository.resendVerificationCalls, 1);
      expect(repository.lastResendRequest?.email, 'learner@example.com');
    });

    testWidgets(
      'Verify Email to Login keeps one success toast across the route change',
      (tester) async {
        final router = await _pumpAuthRoute(
          tester,
          AppRoutes.register,
          _FakeAuthRepository(),
        );
        await _registerSuccessfully(tester);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('riki_toast_close_0')),
        );
        await tester.pumpAndSettle();
        await _tapVisible(
          tester,
          find.byKey(const Key('register_open_verify_email_button')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(_textField('verify_email_code_field'), '123456');
        await _tapVisible(
          tester,
          find.byKey(const Key('verify_email_submit_button')),
        );
        await tester.pumpAndSettle();

        await _tapVisible(
          tester,
          find.byKey(const Key('verify_email_finish_button')),
        );
        await tester.pump(const Duration(milliseconds: 220));

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Xác thực email thành công'), findsOneWidget);
        expect(find.text('Bạn có thể đăng nhập ngay bây giờ.'), findsOneWidget);

        router.go(AppRoutes.login);
        await tester.pump();
        expect(find.text('Xác thực email thành công'), findsOneWidget);
      },
    );

    testWidgets('duplicate email renders controlled backend feedback', (
      tester,
    ) async {
      final repository = _FakeAuthRepository(
        registerError: const ValidationError(
          message: 'Email này đã được đăng ký.',
        ),
      );
      await _pumpAuthRoute(tester, AppRoutes.register, repository);
      await tester.enterText(
        _textField('register_email_field'),
        'learner@example.com',
      );
      await tester.enterText(_textField('register_password_field'), 'secret');
      await tester.enterText(
        _textField('register_confirm_password_field'),
        'secret',
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('register_submit_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể tạo tài khoản'), findsOneWidget);
      expect(find.textContaining('email đã được sử dụng'), findsOneWidget);
    });

    testWidgets('login action returns to login', (tester) async {
      await _pumpAuthRoute(tester, AppRoutes.register, _FakeAuthRepository());

      await _tapVisible(tester, find.text('Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen', () {
    testWidgets('request form renders approved content', (tester) async {
      await _pumpAuthRoute(
        tester,
        AppRoutes.forgotPassword,
        _FakeAuthRepository(),
      );

      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('EMAIL ĐÃ ĐĂNG KÝ'), findsOneWidget);
      expect(find.text('Gửi yêu cầu'), findsOneWidget);
      expect(find.text('Quay lại đăng nhập'), findsOneWidget);
    });

    testWidgets('invalid email is rejected locally', (tester) async {
      final repository = _FakeAuthRepository();
      await _pumpAuthRoute(tester, AppRoutes.forgotPassword, repository);
      await tester.enterText(_textField('forgot_email_field'), 'invalid@');

      await _tapVisible(tester, find.byKey(const Key('forgot_submit_button')));

      expect(
        find.text('Email không hợp lệ. Vui lòng kiểm tra lại định dạng.'),
        findsOneWidget,
      );
      expect(repository.passwordResetCalls, 0);
    });

    testWidgets('successful repository result renders the success state', (
      tester,
    ) async {
      await _pumpAuthRoute(
        tester,
        AppRoutes.forgotPassword,
        _FakeAuthRepository(),
      );
      await tester.enterText(
        _textField('forgot_email_field'),
        'learner@example.com',
      );

      await _tapVisible(tester, find.byKey(const Key('forgot_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Yêu cầu đã được gửi'), findsOneWidget);
      expect(find.text('Đã gửi email'), findsOneWidget);
      expect(find.textContaining('Gửi lại (58s)'), findsOneWidget);
    });

    testWidgets('success action returns to Login', (tester) async {
      await _pumpAuthRoute(
        tester,
        AppRoutes.forgotPassword,
        _FakeAuthRepository(),
      );
      await tester.enterText(
        _textField('forgot_email_field'),
        'learner@example.com',
      );
      await _tapVisible(tester, find.byKey(const Key('forgot_submit_button')));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('Quay lại đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('unavailable password recovery renders a safe error', (
      tester,
    ) async {
      final repository = _FakeAuthRepository(
        passwordResetError: const PasswordRecoveryUnavailableException(),
      );
      await _pumpAuthRoute(tester, AppRoutes.forgotPassword, repository);
      await tester.enterText(
        _textField('forgot_email_field'),
        'learner@example.com',
      );

      await _tapVisible(tester, find.byKey(const Key('forgot_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Chưa thể gửi yêu cầu'), findsOneWidget);
      expect(
        find.textContaining('chưa khả dụng trong ứng dụng'),
        findsOneWidget,
      );
    });
  });

  group('Japanese localization', () {
    testWidgets('Login and Register render Japanese labels', (tester) async {
      final router = await _pumpAuthRoute(
        tester,
        AppRoutes.login,
        _FakeAuthRepository(),
        locale: const Locale('ja'),
      );

      expect(find.text('ログイン'), findsWidgets);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);

      router.go(AppRoutes.register);
      await tester.pumpAndSettle();
      expect(find.text('新規登録'), findsWidgets);
      expect(find.text('氏名'), findsOneWidget);
      expect(find.text('パスワードを再入力'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Register Success renders Japanese without overflow', (
      tester,
    ) async {
      await _pumpAuthRoute(
        tester,
        AppRoutes.register,
        _FakeAuthRepository(),
        locale: const Locale('ja'),
      );
      await _registerSuccessfully(tester);
      await tester.pumpAndSettle();

      expect(find.text('アカウントを作成しました'), findsWidgets);
      expect(
        find.byKey(const Key('register_success_celebration')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

const _loginResponse = LoginResponseDto(
  accessToken: 'access-token',
  userId: 42,
  email: 'learner@example.com',
  fullName: 'Nguyễn Minh Anh',
  role: BackendUserRole.learner,
);

const _registerResponse = RegisterResponseDto(
  fullName: 'Nguyễn Minh Anh',
  email: 'learner@example.com',
  userId: 42,
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.loginCompleter,
    this.registerCompleter,
    this.loginError,
    this.registerError,
    this.passwordResetError,
  });

  final Completer<LoginResponseDto>? loginCompleter;
  final Completer<RegisterResponseDto>? registerCompleter;
  final Object? loginError;
  final Object? registerError;
  final Object? passwordResetError;

  int loginCalls = 0;
  int registerCalls = 0;
  int passwordResetCalls = 0;
  int resendVerificationCalls = 0;
  RegisterRequestDto? lastRegisterRequest;
  ResendVerificationEmailRequestDto? lastResendRequest;

  @override
  Future<LoginResponseDto> login(
    LoginRequestDto request, {
    required bool persistSession,
  }) {
    loginCalls += 1;
    if (loginError != null) return Future.error(loginError!);
    return loginCompleter?.future ?? Future.value(_loginResponse);
  }

  @override
  Future<RegisterResponseDto> register(RegisterRequestDto request) {
    registerCalls += 1;
    lastRegisterRequest = request;
    if (registerError != null) return Future.error(registerError!);
    return registerCompleter?.future ?? Future.value(_registerResponse);
  }

  @override
  Future<void> verifyEmail(VerifyEmailRequestDto request) async {}

  @override
  Future<void> resendVerificationEmail(
    ResendVerificationEmailRequestDto request,
  ) async {
    resendVerificationCalls += 1;
    lastResendRequest = request;
  }

  @override
  Future<void> updateEmail(int userId, UpdateEmailRequestDto request) async {}

  @override
  Future<void> changePassword(
    int userId,
    ChangePasswordRequestDto request,
  ) async {}

  @override
  Future<void> requestPasswordReset(String email) {
    passwordResetCalls += 1;
    if (passwordResetError != null) return Future.error(passwordResetError!);
    return Future.value();
  }
}

Finder _textField(String key) {
  return find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
}

Future<GoRouter> _pumpAuthRoute(
  WidgetTester tester,
  String initialLocation,
  AuthRepository repository, {
  Locale locale = const Locale('vi'),
  DateTime Function()? now,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = createTestAuthSession(
    initialState: AuthSessionState.unauthenticated,
  );
  final router = createAppRouter(
    authSession: session,
    initialLocation: initialLocation,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        authSessionControllerProvider.overrideWithValue(session),
        if (now != null) verifyEmailClockProvider.overrideWithValue(now),
        localeControllerProvider.overrideWith(
          () => _TestLocaleController(locale),
        ),
      ],
      child: Consumer(
        builder: (context, ref, child) => MaterialApp.router(
          theme: AppTheme.light,
          locale: ref.watch(localeControllerProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) =>
              RikiToastHost(child: child ?? const SizedBox.shrink()),
        ),
      ),
    ),
  );
  await tester.pump();
  return router;
}

class _MutableClock {
  DateTime _now = DateTime.utc(2026, 10, 3, 8);

  DateTime call() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

class _TestLocaleController extends LocaleController {
  _TestLocaleController(this.initialLocale);

  final Locale initialLocale;

  @override
  Locale build() => initialLocale;

  @override
  Future<void> changeLocale(Locale locale) async => state = locale;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _registerSuccessfully(WidgetTester tester) async {
  await tester.enterText(
    _textField('register_full_name_field'),
    'Nguyễn Minh Anh',
  );
  await tester.enterText(
    _textField('register_email_field'),
    'learner@example.com',
  );
  await tester.enterText(_textField('register_password_field'), 'secret');
  await tester.enterText(
    _textField('register_confirm_password_field'),
    'secret',
  );
  await _tapVisible(tester, find.byKey(const Key('register_submit_button')));
  await tester.pump();
}
