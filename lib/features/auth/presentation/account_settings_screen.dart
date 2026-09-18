import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: [
          const Text('Bảo mật tài khoản', style: AppTypography.pageTitle),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Quản lý email đăng nhập, mật khẩu và phiên hiện tại.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space6),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const Key('account_change_email_action'),
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('Đổi email'),
                  subtitle: const Text('Gửi mã xác thực tới email mới'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.profileChangeEmail),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('account_change_password_action'),
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Đổi mật khẩu'),
                  subtitle: const Text('Yêu cầu mật khẩu hiện tại'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.profileChangePassword),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          RikiSecondaryButton(
            key: const Key('account_logout_button'),
            label: 'Đăng xuất',
            leadingIcon: Icons.logout,
            onPressed: () => ref.read(authSessionControllerProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
