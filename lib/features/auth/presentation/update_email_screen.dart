import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/update_email_controller.dart';

class UpdateEmailScreen extends ConsumerStatefulWidget {
  const UpdateEmailScreen({super.key});

  @override
  ConsumerState<UpdateEmailScreen> createState() => _UpdateEmailScreenState();
}

class _UpdateEmailScreenState extends ConsumerState<UpdateEmailScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(updateEmailControllerProvider.notifier)
        .submit(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateEmailControllerProvider);
    final userId = ref.watch(authSessionControllerProvider).currentUserId;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: const Text('Đổi email')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space5,
          AppSpacing.space4,
          AppSpacing.space5,
          AppSpacing.space8,
        ),
        children: [
          const Text('Email đăng nhập mới', style: AppTypography.pageTitle),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Sau khi cập nhật, máy chủ sẽ gửi mã xác thực tới email mới.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space6),
          if (userId == null) ...[
            const RikiErrorBanner(
              title: 'Thiếu thông tin phiên',
              message:
                  'Phiên cũ chưa lưu mã tài khoản. Vui lòng đăng xuất rồi đăng nhập lại.',
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
          RikiTextField(
            key: const Key('update_email_field'),
            label: 'Email mới',
            hintText: 'emailmoi@example.com',
            controller: _emailController,
            prefixIcon: Icons.mail_outline,
            errorText: state.emailError,
            enabled: userId != null && !state.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onChanged: (_) => ref
                .read(updateEmailControllerProvider.notifier)
                .clearFeedback(),
            onSubmitted: (_) {
              if (userId != null && !state.isLoading) _submit();
            },
          ),
          if (state.serverError != null) ...[
            const SizedBox(height: AppSpacing.space4),
            RikiErrorBanner(
              title: 'Không thể đổi email',
              message: state.serverError!,
            ),
          ],
          if (state.succeeded) ...[
            const SizedBox(height: AppSpacing.space4),
            const RikiSuccessBanner(
              message:
                  'Email đã được cập nhật. Hãy nhập mã được gửi tới email mới.',
            ),
          ],
          const SizedBox(height: AppSpacing.space5),
          RikiPrimaryButton(
            key: const Key('update_email_submit_button'),
            label: 'Cập nhật email',
            loadingLabel: 'Đang cập nhật...',
            isLoading: state.isLoading,
            onPressed: userId == null ? null : _submit,
          ),
          if (state.succeeded && userId != null) ...[
            const SizedBox(height: AppSpacing.space3),
            RikiSecondaryButton(
              key: const Key('update_email_verify_action'),
              label: 'Nhập mã xác thực',
              trailingIcon: Icons.arrow_forward,
              onPressed: () =>
                  context.push(AppRoutes.verifyEmail, extra: userId),
            ),
          ],
        ],
      ),
    );
  }
}
