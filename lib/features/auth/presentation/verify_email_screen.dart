import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/verify_email_controller.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_page.dart';
import 'package:rikipath_mobile/features/auth/presentation/widgets/auth_success_illustration.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({this.userId, super.key});

  final int? userId;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(verifyEmailControllerProvider.notifier)
        .submit(userId: widget.userId, verificationCode: _codeController.text);
  }

  void _finish() {
    ref.read(verifyEmailControllerProvider.notifier).reset();
    final session = ref.read(authSessionControllerProvider);
    context.go(
      session.value == AuthSessionState.authenticated
          ? AppRoutes.profileAccount
          : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailControllerProvider);
    if (state.succeeded) {
      return AuthPage(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const RikiAuthHeader(statusLabel: 'Email đã xác thực'),
                const SizedBox(height: AppSpacing.space10),
                const Center(
                  child: AuthSuccessIllustration(
                    icon: Icons.mark_email_read_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                const Text(
                  'Xác thực email thành công',
                  textAlign: TextAlign.center,
                  style: AppTypography.heroTitle,
                ),
                const SizedBox(height: AppSpacing.space4),
                const RikiSuccessBanner(
                  message: 'Email của bạn đã được xác thực trên RikiPath.',
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space8),
              child: RikiPrimaryButton(
                key: const Key('verify_email_finish_button'),
                label: 'Tiếp tục',
                trailingIcon: Icons.arrow_forward,
                onPressed: _finish,
              ),
            ),
          ],
        ),
      );
    }

    final isBlocked = widget.userId == null;
    return AuthPage(
      compact: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RikiAuthHeader(statusLabel: 'Xác thực email'),
              const SizedBox(height: AppSpacing.space8),
              const Text('Nhập mã xác thực', style: AppTypography.pageTitle),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Nhập mã được gửi tới email của bạn để hoàn tất xác thực.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              if (isBlocked) ...[
                const RikiWarningBanner(
                  title: 'Chưa thể tiếp tục từ đăng ký',
                  message:
                      'Phản hồi đăng ký hiện chưa trả về mã tài khoản mà API '
                      'xác thực yêu cầu. RikiPath không tự đoán mã này.',
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
              RikiTextField(
                key: const Key('verify_email_code_field'),
                label: 'Mã xác thực',
                hintText: 'Nhập mã trong email',
                controller: _codeController,
                prefixIcon: Icons.password_outlined,
                errorText: state.codeError,
                enabled: !isBlocked && !state.isLoading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => ref
                    .read(verifyEmailControllerProvider.notifier)
                    .clearFeedback(),
                onSubmitted: (_) {
                  if (!isBlocked && !state.isLoading) _submit();
                },
              ),
              if (state.serverError != null) ...[
                const SizedBox(height: AppSpacing.space4),
                RikiErrorBanner(
                  title: 'Không thể xác thực email',
                  message: state.serverError!,
                ),
              ],
              const SizedBox(height: AppSpacing.space5),
              RikiPrimaryButton(
                key: const Key('verify_email_submit_button'),
                label: 'Xác thực email',
                loadingLabel: 'Đang xác thực...',
                isLoading: state.isLoading,
                onPressed: isBlocked ? null : _submit,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: AuthNavigationPrompt(
              message: 'Đã xác thực?',
              actionLabel: 'Đăng nhập',
              onPressed: state.isLoading
                  ? null
                  : () => context.go(AppRoutes.login),
            ),
          ),
        ],
      ),
    );
  }
}
