import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';
import 'package:rikipath_mobile/features/auth/data/auth_dtos.dart';
import 'package:rikipath_mobile/features/auth/data/auth_repository.dart';
import 'package:rikipath_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/login_screen.dart';
import 'package:rikipath_mobile/features/auth/presentation/register_screen.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders the approved major content', (tester) async {
      await _pumpAuthRoute(tester, AppRoutes.login, _FakeAuthRepository());

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('RikiPath'), findsOneWidget);
      expect(find.text('N4'), findsOneWidget);
      expect(find.text('Chào mừng trở lại! 👋'), findsOneWidget);
      expect(find.text('Email học viên'), findsOneWidget);
      expect(find.text('Mẹo đăng nhập'), findsOneWidget);
      expect(find.text('Bảo mật chuẩn mã hóa Riki Learning'), findsOneWidget);
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

    testWidgets('password visibility toggle changes obscuring', (tester) async {
      await _pumpAuthRoute(tester, AppRoutes.login, _FakeAuthRepository());

      expect(
        tester.widget<TextField>(_textField('login_password_field')).obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(
        tester.widget<TextField>(_textField('login_password_field')).obscureText,
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
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('forgot-password action opens the canonical route', (
      tester,
    ) async {
      await _pumpAuthRoute(tester, AppRoutes.login, _FakeAuthRepository());

      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('register action opens registration', (tester) async {
      await _pumpAuthRoute(tester, AppRoutes.login, _FakeAuthRepository());

      await _tapVisible(tester, find.text('Đăng ký'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
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
      expect(find.textContaining('Email hoặc mật khẩu không đúng'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('required transport fields validate before submission', (
      tester,
    ) async {
      final repository = _FakeAuthRepository();
      await _pumpAuthRoute(tester, AppRoutes.register, repository);

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

    testWidgets('loading state is represented and disables submit', (
      tester,
    ) async {
      final completer = Completer<RegisterResponseDto>();
      final repository = _FakeAuthRepository(registerCompleter: completer);
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
      await tester.pump();

      expect(find.text('Đang tạo tài khoản...'), findsOneWidget);
      expect(
        tester.widget<RikiPrimaryButton>(
          find.byKey(const Key('register_submit_button')),
        ).isLoading,
        isTrue,
      );
      expect(repository.registerCalls, 1);

      completer.complete(_registerResponse);
      await tester.pumpAndSettle();
      expect(find.text('Tạo tài khoản thành công'), findsOneWidget);
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

    testWidgets('missing production endpoint renders an explicit error', (
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
      expect(find.textContaining('chưa được kết nối với máy chủ'), findsOneWidget);
    });
  });
}

const _loginResponse = LoginResponseDto(
  accessToken: 'access-token',
  userId: 42,
  email: 'learner@example.com',
  fullName: 'Nguyễn Minh Anh',
  role: 'Learner',
);

const _registerResponse = RegisterResponseDto(
  fullName: 'Nguyễn Minh Anh',
  email: 'learner@example.com',
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
    if (registerError != null) return Future.error(registerError!);
    return registerCompleter?.future ?? Future.value(_registerResponse);
  }

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
  AuthRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = createAppRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return router;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}
