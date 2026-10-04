import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showProfileConfirmationSheet(
      context: context,
      icon: Icons.logout_rounded,
      title: l10n.logoutConfirmationTitle,
      message: l10n.logoutConfirmationMessage,
      confirmLabel: l10n.logout,
      cancelLabel: l10n.cancel,
      confirmKey: const ValueKey<String>('account_logout_confirm_button'),
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(authSessionControllerProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profileValue = ref.watch(userProfileControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      appBar: ProfileDetailHeader(title: l10n.account),
      body: profileValue.when(
        loading: () => const ProfileDetailSkeleton(
          key: ValueKey<String>('account_settings_loading_view'),
          groupCount: 3,
          rowsPerGroup: 2,
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RikiErrorBanner(
                  title: l10n.profileLoadFailedTitle,
                  message: userProfileErrorMessage(error, l10n),
                ),
                const SizedBox(height: AppSpacing.space4),
                RikiSecondaryButton(
                  label: l10n.retry,
                  onPressed: () =>
                      ref.read(userProfileControllerProvider.notifier).retry(),
                ),
              ],
            ),
          ),
        ),
        data: (state) => ProfileAnimatedEntrance(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space3,
              AppSpacing.space4,
              AppSpacing.space8,
            ),
            children: [
              ProfileDetailIntro(
                icon: Icons.shield_outlined,
                title: l10n.accountSecurity,
                description: l10n.accountSecuritySubtitle,
              ),
              const SizedBox(height: AppSpacing.space5),
              ProfileSecurityCard(
                email: state.profile.email,
                verified: state.profile.isEmailVerified,
                verifiedTitle: l10n.accountVerifiedTitle,
                unverifiedTitle: l10n.accountUnverifiedTitle,
              ),
              const SizedBox(height: AppSpacing.space6),
              ProfileSettingsGroup(
                label: l10n.accountOptionsSection,
                children: [
                  ProfileSettingsTile(
                    key: const ValueKey<String>(
                      'account_notification_settings_action',
                    ),
                    icon: Icons.notifications_none_rounded,
                    title: l10n.notificationSettingsTitle,
                    subtitle: l10n.notificationSettingsSubtitle,
                    onTap: () => context.push(AppRoutes.profileNotifications),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space6),
              ProfileSettingsGroup(
                label: l10n.accountSessionSection,
                children: [
                  ProfileSettingsTile(
                    key: const ValueKey<String>('account_logout_button'),
                    icon: Icons.logout_rounded,
                    title: l10n.logout,
                    subtitle: l10n.logoutConfirmationMessage,
                    destructive: true,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
