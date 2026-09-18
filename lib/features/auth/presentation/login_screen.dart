import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/login_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberSession = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final succeeded = await ref
        .read(loginControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          password: _passwordController.text,
          rememberSession: _rememberSession,
        );
    if (!mounted) return;
    if (succeeded) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final hasFeedback =
        state.emailError != null ||
        state.passwordError != null ||
        state.serverError != null;

    return AuthPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RikiAuthHeader(level: JlptLevel.n4),
              const SizedBox(height: AppSpacing.space8),
              const Align(
                alignment: Alignment.centerLeft,
                child: RikiPromotionalPill(
                  message: 'Học tiếng Nhật cá nhân hoá cùng AI',
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              const Text(
                'Chào mừng trở lại! 👋',
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Tiếp tục hành trình chinh phục JLPT cùng RikiPath.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              RikiTextField(
                key: const Key('login_email_field'),
                label: 'Email học viên',
                hintText: 'hocvien@example.com',
                controller: _emailController,
                prefixIcon: Icons.mail_outline,
                suffixIcon: state.isLoading
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
                errorText: state.emailError,
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                onChanged: (_) =>
                    ref.read(loginControllerProvider.notifier).clearFeedback(),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              RikiPasswordField(
                key: const Key('login_password_field'),
                label: 'Mật khẩu',
                hintText: 'Nhập mật khẩu',
                controller: _passwordController,
                errorText: state.passwordError,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.done,
                onChanged: (_) =>
                    ref.read(loginControllerProvider.notifier).clearFeedback(),
                onSubmitted: (_) {
                  if (!state.isLoading) _submit();
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: RikiTextButton(
                  key: const Key('forgot_password_button'),
                  label: 'Quên mật khẩu?',
                  onPressed: state.isLoading
                      ? null
                      : () => context.go(AppRoutes.forgotPassword),
                ),
              ),
              RikiCheckboxRow(
                value: _rememberSession,
                compact: true,
                centerChild: true,
                onChanged: state.isLoading
                    ? null
                    : (value) {
                        setState(() => _rememberSession = value ?? false);
                      },
                child: const Text('Ghi nhớ phiên đăng nhập trên thiết bị này'),
              ),
              if (state.serverError != null) ...[
                const SizedBox(height: AppSpacing.space3),
                RikiErrorBanner(
                  title: 'Không thể đăng nhập',
                  message: state.serverError!,
                ),
              ],
              const SizedBox(height: AppSpacing.space2),
              RikiPrimaryButton(
                key: const Key('login_submit_button'),
                label: 'Đăng nhập',
                loadingLabel: 'Đang đăng nhập...',
                trailingIcon: Icons.arrow_forward,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              if (state.isLoading) ...[
                const SizedBox(height: AppSpacing.space4),
                const RikiWarningBanner(
                  icon: Icons.hourglass_bottom,
                  message: 'Đang kết nối an toàn với tài khoản của bạn...',
                ),
                const SizedBox(height: AppSpacing.space3),
                const RikiProgressIndicator(semanticsLabel: 'Đang đăng nhập'),
              ] else if (!hasFeedback) ...[
                const SizedBox(height: AppSpacing.space5),
                const RikiWarningBanner(
                  title: 'Mẹo đăng nhập',
                  message:
                      'Sử dụng tài khoản đã đăng ký khóa học để đồng bộ '
                      'chuỗi streak và lộ trình AI.',
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: Column(
              children: [
                AuthNavigationPrompt(
                  message: 'Chưa có tài khoản?',
                  actionLabel: 'Đăng ký',
                  onPressed: state.isLoading
                      ? null
                      : () => context.go(AppRoutes.register),
                ),
                const AuthSecurityFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
