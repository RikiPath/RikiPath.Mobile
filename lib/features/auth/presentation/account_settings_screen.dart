import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/core/widgets/sakura_language_bottom_sheet.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({this.forMentor = false, super.key});

  const AccountSettingsScreen.mentor({super.key}) : forMentor = true;

  final bool forMentor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);
    final isJa = locale.languageCode == 'ja';

    final String? currentEmail;
    final Widget bodyContent;

    if (forMentor) {
      final mentorState = ref.watch(mentorProfileControllerProvider);
      currentEmail = mentorState.value?.email;
      bodyContent = mentorState.when(
        loading: () => const ProfileDetailSkeleton(
          key: ValueKey<String>('account_settings_loading_view'),
          groupCount: 2,
          rowsPerGroup: 2,
        ),
        error: (error, _) => _SettingsErrorBody(
          title: l10n.profileLoadFailedTitle,
          message: appErrorMessage(
            error,
            l10n,
            fallback: l10n.mentorProfileErrorLoad,
          ),
          retryLabel: l10n.retry,
          onRetry: () =>
              ref.read(mentorProfileControllerProvider.notifier).retry(),
        ),
        data: (_) => _AccountSettingsContent(
          isJa: isJa,
          currentEmail: currentEmail,
          changePasswordRoute: AppRoutes.mentorChangePassword,
          changeEmailRoute: AppRoutes.mentorChangeEmail,
          notificationsRoute: AppRoutes.mentorNotifications,
        ),
      );
    } else {
      final profileValue = ref.watch(userProfileControllerProvider);
      currentEmail = profileValue.value?.profile.email;
      bodyContent = profileValue.when(
        loading: () => const ProfileDetailSkeleton(
          key: ValueKey<String>('account_settings_loading_view'),
          groupCount: 2,
          rowsPerGroup: 2,
        ),
        error: (error, _) => _SettingsErrorBody(
          title: l10n.profileLoadFailedTitle,
          message: userProfileErrorMessage(error, l10n),
          retryLabel: l10n.retry,
          onRetry: () =>
              ref.read(userProfileControllerProvider.notifier).retry(),
        ),
        data: (_) => _AccountSettingsContent(
          isJa: isJa,
          currentEmail: currentEmail,
          changePasswordRoute: AppRoutes.profileChangePassword,
          changeEmailRoute: AppRoutes.profileChangeEmail,
          notificationsRoute: AppRoutes.profileNotifications,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      appBar: ProfileDetailHeader(
        title: forMentor ? l10n.settings : l10n.account,
        fallbackRoute:
            forMentor ? AppRoutes.mentorProfile : AppRoutes.profile,
      ),
      body: bodyContent,
    );
  }
}

class _SettingsErrorBody extends StatelessWidget {
  const _SettingsErrorBody({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RikiErrorBanner(title: title, message: message),
            const SizedBox(height: AppSpacing.space4),
            RikiSecondaryButton(label: retryLabel, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _AccountSettingsContent extends StatelessWidget {
  const _AccountSettingsContent({
    required this.isJa,
    required this.currentEmail,
    required this.changePasswordRoute,
    required this.changeEmailRoute,
    required this.notificationsRoute,
  });

  final bool isJa;
  final String? currentEmail;
  final String changePasswordRoute;
  final String? changeEmailRoute;
  final String notificationsRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProfileAnimatedEntrance(
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
            colorfulIcon: SakuraColorfulIconType.security,
            title: l10n.accountSecurity,
            description: l10n.accountSecuritySubtitle,
          ),
          const SizedBox(height: AppSpacing.space6),
          ProfileSettingsGroup(
            label: l10n.accountSecuritySection,
            children: [
              ProfileSettingsTile(
                key: const ValueKey<String>('account_change_password_action'),
                icon: Icons.lock_outline_rounded,
                colorfulIcon: SakuraColorfulIconType.password,
                title: l10n.changePassword,
                subtitle: l10n.changePasswordSubtitle,
                onTap: () => context.push(changePasswordRoute),
              ),
              if (changeEmailRoute != null)
                ProfileSettingsTile(
                  key: const ValueKey<String>('account_change_email_action'),
                  icon: Icons.alternate_email_rounded,
                  colorfulIcon: SakuraColorfulIconType.email,
                  title: l10n.changeEmail,
                  subtitle: (currentEmail != null && currentEmail!.isNotEmpty)
                      ? currentEmail!
                      : l10n.changeEmailSubtitle,
                  onTap: () => context.push(changeEmailRoute!),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          ProfileSettingsGroup(
            label: l10n.accountOptionsSection,
            children: [
              ProfileSettingsTile(
                key: const ValueKey<String>('account_language_settings_action'),
                icon: Icons.language_rounded,
                colorfulIcon: SakuraColorfulIconType.language,
                title: l10n.appLanguageTitle,
                subtitleWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 14,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: SvgPicture.asset(
                        isJa ? 'assets/flags/ja.svg' : 'assets/flags/vi.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      isJa ? l10n.languageJapanese : l10n.languageVietnamese,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.learnerTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                onTap: () => showSakuraLanguageBottomSheet(context),
              ),
              ProfileSettingsTile(
                key: const ValueKey<String>(
                  'account_notification_settings_action',
                ),
                icon: Icons.notifications_none_rounded,
                colorfulIcon: SakuraColorfulIconType.notifications,
                title: l10n.notificationSettingsTitle,
                subtitle: l10n.notificationSettingsSubtitle,
                onTap: () => context.push(notificationsRoute),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
