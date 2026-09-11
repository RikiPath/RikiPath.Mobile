import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/forgot_password_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_success_illustration.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    if (state.succeeded) {
      return _ForgotPasswordSuccess(
        email: state.submittedEmail!,
        onReturnToLogin: () {
          ref.read(forgotPasswordControllerProvider.notifier).reset();
          context.go(AppRoutes.login);
        },
      );
    }

    return AuthPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RikiAuthHeader(
                onBack: () => context.go(AppRoutes.login),
                backSemanticLabel: 'Quay lại đăng nhập',
              ),
              const SizedBox(height: AppSpacing.space10),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    border: Border.all(color: AppColors.brandBorder),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 36,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              const Text(
                'Quên mật khẩu?',
                textAlign: TextAlign.center,
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Nhập email đã đăng ký để nhận hướng dẫn đặt lại mật khẩu.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space10),
              RikiTextField(
                key: const Key('forgot_email_field'),
                label: 'EMAIL ĐÃ ĐĂNG KÝ',
                hintText: 'nhap.email@example.com',
                controller: _emailController,
                prefixIcon: Icons.mail_outline,
                errorText: state.emailError,
                enabled: !state.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                onChanged: (_) => ref
                    .read(forgotPasswordControllerProvider.notifier)
                    .clearFeedback(),
                onSubmitted: (_) {
                  if (!state.isLoading) _submit();
                },
              ),
              if (state.serverError != null) ...[
                const SizedBox(height: AppSpacing.space4),
                RikiErrorBanner(
                  title: 'Chưa thể gửi yêu cầu',
                  message: state.serverError!,
                ),
              ],
              const SizedBox(height: AppSpacing.space6),
              RikiPrimaryButton(
                key: const Key('forgot_submit_button'),
                label: 'Gửi yêu cầu',
                loadingLabel: 'Đang gửi yêu cầu...',
                trailingIcon: Icons.arrow_forward,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.space3),
              RikiSecondaryButton(
                label: 'Quay lại đăng nhập',
                leadingIcon: Icons.arrow_back,
                onPressed: state.isLoading
                    ? null
                    : () => context.go(AppRoutes.login),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.space8),
            child: AuthHelpFooter(),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordSuccess extends StatelessWidget {
  const _ForgotPasswordSuccess({
    required this.email,
    required this.onReturnToLogin,
  });

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
              const RikiAuthHeader(statusLabel: 'Đã gửi email'),
              const SizedBox(height: AppSpacing.space10),
              const Center(
                child: AuthSuccessIllustration(icon: Icons.mail_outline),
              ),
              const SizedBox(height: AppSpacing.space6),
              const Text(
                'Yêu cầu đã được gửi',
                textAlign: TextAlign.center,
                style: AppTypography.heroTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Chúng tôi đã gửi hướng dẫn lấy lại mật khẩu tới $email.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              const RikiSuccessBanner(
                message: 'Vui lòng kiểm tra email để tiếp tục đặt lại mật khẩu.',
              ),
              const SizedBox(height: AppSpacing.space4),
              const RikiWarningBanner(
                icon: Icons.info_outline,
                message: 'Nếu không thấy email trong Hộp thư đến, vui lòng '
                    'kiểm tra Thư rác hoặc Spam.',
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(
                'Không nhận được thư? Gửi lại (58s)',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                const AuthHelpFooter(
                  prefix: 'Cần hỗ trợ về tài khoản?',
                  actionLabel: 'Trung tâm trợ giúp',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
