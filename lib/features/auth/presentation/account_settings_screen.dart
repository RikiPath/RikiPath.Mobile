import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/core/widgets/sakura_language_bottom_sheet.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);
    final isJa = locale.languageCode == 'ja';
    final profileValue = ref.watch(userProfileControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      appBar: ProfileDetailHeader(title: l10n.account),
      body: profileValue.when(
        loading: () => const ProfileDetailSkeleton(
          key: ValueKey<String>('account_settings_loading_view'),
          groupCount: 2,
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
                colorfulIcon: SakuraColorfulIconType.security,
                title: l10n.accountSecurity,
                description: l10n.accountSecuritySubtitle,
              ),

              const SizedBox(height: AppSpacing.space6),
              ProfileSettingsGroup(
                label: l10n.accountSecuritySection,
                children: [
                  ProfileSettingsTile(
                    key: const ValueKey<String>(
                      'account_change_password_action',
                    ),
                    icon: Icons.lock_outline_rounded,
                    colorfulIcon: SakuraColorfulIconType.password,
                    title: l10n.changePassword,
                    subtitle: l10n.changePasswordSubtitle,
                    onTap: () => context.push(AppRoutes.profileChangePassword),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space6),
              ProfileSettingsGroup(
                label: l10n.accountOptionsSection,
                children: [
                  ProfileSettingsTile(
                    key: const ValueKey<String>(
                      'account_language_settings_action',
                    ),
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
                            isJa
                                ? 'assets/flags/ja.svg'
                                : 'assets/flags/vi.svg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Text(
                          isJa
                              ? l10n.languageJapanese
                              : l10n.languageVietnamese,
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
                    onTap: () => context.push(AppRoutes.profileNotifications),
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
