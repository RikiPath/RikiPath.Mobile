import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/application/change_password_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final succeeded = await ref
        .read(changePasswordControllerProvider.notifier)
        .submit(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
    if (!mounted || !succeeded) return;
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordControllerProvider);
    final userId = ref.watch(authSessionControllerProvider).currentUserId;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space5,
          AppSpacing.space4,
          AppSpacing.space5,
          AppSpacing.space8,
        ),
        children: [
          const Text('Bảo vệ tài khoản', style: AppTypography.pageTitle),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Mật khẩu mới phải có ít nhất 6 ký tự theo hợp đồng hiện tại.',
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
          RikiPasswordField(
            key: const Key('change_password_current_field'),
            label: 'Mật khẩu hiện tại',
            hintText: 'Nhập mật khẩu hiện tại',
            controller: _currentPasswordController,
            errorText: state.currentPasswordError,
            enabled: userId != null && !state.isLoading,
            textInputAction: TextInputAction.next,
            onChanged: (_) => ref
                .read(changePasswordControllerProvider.notifier)
                .clearFeedback(),
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          RikiPasswordField(
            key: const Key('change_password_new_field'),
            label: 'Mật khẩu mới',
            hintText: 'Nhập mật khẩu mới',
            controller: _newPasswordController,
            errorText: state.newPasswordError,
            enabled: userId != null && !state.isLoading,
            textInputAction: TextInputAction.next,
            onChanged: (_) => ref
                .read(changePasswordControllerProvider.notifier)
                .clearFeedback(),
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          RikiPasswordField(
            key: const Key('change_password_confirm_field'),
            label: 'Xác nhận mật khẩu mới',
            hintText: 'Nhập lại mật khẩu mới',
            controller: _confirmPasswordController,
            errorText: state.confirmPasswordError,
            enabled: userId != null && !state.isLoading,
            textInputAction: TextInputAction.done,
            onChanged: (_) => ref
                .read(changePasswordControllerProvider.notifier)
                .clearFeedback(),
            onSubmitted: (_) {
              if (userId != null && !state.isLoading) _submit();
            },
          ),
          if (state.serverError != null) ...[
            const SizedBox(height: AppSpacing.space4),
            RikiErrorBanner(
              title: 'Không thể đổi mật khẩu',
              message: state.serverError!,
            ),
          ],
          if (state.succeeded) ...[
            const SizedBox(height: AppSpacing.space4),
            const RikiSuccessBanner(
              message:
                  'Mật khẩu đã được cập nhật. Phiên đăng nhập hiện tại vẫn được giữ.',
            ),
          ],
          const SizedBox(height: AppSpacing.space5),
          RikiPrimaryButton(
            key: const Key('change_password_submit_button'),
            label: 'Đổi mật khẩu',
            loadingLabel: 'Đang cập nhật...',
            isLoading: state.isLoading,
            onPressed: userId == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}
