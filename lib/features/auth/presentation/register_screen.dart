import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/register_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_success_illustration.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(registerControllerProvider.notifier)
        .submit(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          acceptedTerms: _acceptedTerms,
        );
  }

  void _clearFeedback() {
    ref.read(registerControllerProvider.notifier).clearFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);
    if (state.succeeded) {
      return _RegisterSuccess(
        email: state.registeredAccount!.email,
        onReturnToLogin: () {
          ref.read(registerControllerProvider.notifier).reset();
          context.go(AppRoutes.login);
        },
      );
    }

    return AuthPage(
      compact: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RikiAuthHeader(level: JlptLevel.n4),
              const SizedBox(height: AppSpacing.space6),
              const Align(
                alignment: Alignment.centerLeft,
                child: RikiPromotionalPill(
                  message: 'Học tiếng Nhật cá nhân hoá cùng AI',
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              const Text(
                'Tạo tài khoản RikiPath',
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                'Bắt đầu xây dựng lộ trình học JLPT của riêng bạn.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              RikiTextField(
                key: const Key('register_full_name_field'),
                label: 'Họ và tên',
                hintText: 'Nguyễn Minh Anh',
                controller: _fullNameController,
                prefixIcon: Icons.person_outline,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                onChanged: (_) => _clearFeedback(),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              RikiTextField(
                key: const Key('register_email_field'),
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
                onChanged: (_) => _clearFeedback(),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              RikiPasswordField(
                key: const Key('register_password_field'),
                label: 'Mật khẩu',
                hintText: 'Nhập mật khẩu',
                controller: _passwordController,
                errorText: state.passwordError,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearFeedback(),
              ),
              if (state.passwordError == null) ...[
                const SizedBox(height: AppSpacing.space2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Expanded(
                      child: Text(
                        'Tối thiểu 6 ký tự',
                        style: AppTypography.metadata,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.fieldGap),
              RikiPasswordField(
                key: const Key('register_confirm_password_field'),
                label: 'Xác nhận mật khẩu',
                hintText: 'Nhập lại mật khẩu',
                controller: _confirmPasswordController,
                errorText: state.confirmPasswordError,
                enabled: !state.isLoading,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _clearFeedback(),
                onSubmitted: (_) {
                  if (!state.isLoading) _submit();
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              RikiCheckboxRow(
                value: _acceptedTerms,
                compact: true,
                onChanged: state.isLoading
                    ? null
                    : (value) {
                        setState(() => _acceptedTerms = value ?? false);
                        _clearFeedback();
                      },
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Bằng việc đăng ký, bạn đồng ý với ',
                      ),
                      TextSpan(
                        text: 'Điều khoản dịch vụ',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Chính sách bảo mật',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' của RikiPath.'),
                    ],
                  ),
                ),
              ),
              if (state.agreementError != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.space6),
                  child: Text(
                    state.agreementError!,
                    style: AppTypography.validationText,
                  ),
                ),
              if (state.serverError != null) ...[
                const SizedBox(height: AppSpacing.space3),
                RikiErrorBanner(
                  title: 'Không thể tạo tài khoản',
                  message: state.serverError!,
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              RikiPrimaryButton(
                key: const Key('register_submit_button'),
                label: 'Đăng ký',
                loadingLabel: 'Đang tạo tài khoản...',
                trailingIcon: Icons.arrow_forward,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              if (state.isLoading) ...[
                const SizedBox(height: AppSpacing.space4),
                const RikiWarningBanner(
                  icon: Icons.hourglass_bottom,
                  message:
                      'Đang tạo tài khoản học viên và gửi email xác thực...',
                ),
                const SizedBox(height: AppSpacing.space3),
                const RikiProgressIndicator(
                  semanticsLabel: 'Đang tạo tài khoản',
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: Column(
              children: [
                AuthNavigationPrompt(
                  message: 'Đã có tài khoản?',
                  actionLabel: 'Đăng nhập',
                  onPressed: state.isLoading
                      ? null
                      : () => context.go(AppRoutes.login),
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

class _RegisterSuccess extends StatelessWidget {
  const _RegisterSuccess({required this.email, required this.onReturnToLogin});

  final String email;
  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RikiAuthHeader(statusLabel: 'Đã tạo tài khoản'),
              const SizedBox(height: AppSpacing.space10),
              const Center(
                child: AuthSuccessIllustration(icon: Icons.person_outline),
              ),
              const SizedBox(height: AppSpacing.space6),
              const Text(
                'Tạo tài khoản thành công',
                textAlign: TextAlign.center,
                style: AppTypography.heroTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'RikiPath đã gửi mã xác thực tới $email.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              const RikiSuccessBanner(
                message: 'Vui lòng kiểm tra email để xác thực tài khoản.',
              ),
              const SizedBox(height: AppSpacing.space4),
              const RikiWarningBanner(
                icon: Icons.mark_email_unread_outlined,
                message:
                    'Bạn cần xác thực email trước khi đăng nhập. Phản hồi đăng ký '
                    'hiện chưa trả về mã tài khoản để ứng dụng mở bước nhập mã tự động.',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RikiPrimaryButton(
                  label: 'Quay lại đăng nhập',
                  onPressed: onReturnToLogin,
                ),
                const SizedBox(height: AppSpacing.space4),
                const AuthSecurityFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
