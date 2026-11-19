import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({this.forMentor = false, super.key});

  final bool forMentor;

  Future<void> _save(
    WidgetRef ref, {
    required bool email,
    required bool system,
  }) async {
    await ref
        .read(userProfileControllerProvider.notifier)
        .updateNotificationSettings(
          emailNotificationsEnabled: email,
          systemNotificationsEnabled: system,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (forMentor) {
      final mentorState = ref.watch(mentorProfileControllerProvider);
      return Scaffold(
        backgroundColor: AppColors.profileBackground,
        appBar: ProfileDetailHeader(
          title: l10n.notificationSettingsTitle,
          fallbackRoute: AppRoutes.mentorSettings,
        ),
        body: mentorState.when(
          loading: () => const ProfileDetailSkeleton(
            key: ValueKey<String>('notification_settings_loading_view'),
            groupCount: 1,
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
                    message: appErrorMessage(
                      error,
                      l10n,
                      fallback: l10n.mentorProfileErrorLoad,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  RikiSecondaryButton(
                    label: l10n.retry,
                    onPressed: () => ref
                        .read(mentorProfileControllerProvider.notifier)
                        .retry(),
                  ),
                ],
              ),
            ),
          ),
          data: (_) => ProfileAnimatedEntrance(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space3,
                AppSpacing.space4,
                AppSpacing.space8,
              ),
              children: [
                ProfileDetailIntro(
                  icon: Icons.notifications_none_rounded,
                  colorfulIcon: SakuraColorfulIconType.notifications,
                  title: l10n.notificationSettingsTitle,
                  description: l10n.notificationSettingsSubtitle,
                ),
                const SizedBox(height: AppSpacing.space6),
                RikiInfoBanner(
                  key: const ValueKey<String>(
                    'mentor_notification_channel_unsupported_notice',
                  ),
                  message: l10n.mentorNotificationChannelUnsupportedNotice,
                ),
                const SizedBox(height: AppSpacing.space5),
                ProfileSettingsGroup(
                  label: l10n.notificationPreferencesSection,
                  children: [
                    ProfileSettingsTile(
                      key: const ValueKey<String>(
                        'mentor_open_notifications_center_action',
                      ),
                      icon: Icons.notifications_active_outlined,
                      colorfulIcon: SakuraColorfulIconType.notifications,
                      title: l10n.mentorOpenNotificationCenter,
                      subtitle: l10n.mentorOpenNotificationCenterSubtitle,
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profileValue = ref.watch(userProfileControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      appBar: ProfileDetailHeader(
        title: context.l10n.notificationSettingsTitle,
        fallbackRoute: AppRoutes.profileAccount,
      ),
      body: profileValue.when(
        loading: () => const ProfileDetailSkeleton(
          key: ValueKey<String>('notification_settings_loading_view'),
          groupCount: 1,
          rowsPerGroup: 2,
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RikiErrorBanner(
                  title: context.l10n.profileLoadFailedTitle,
                  message: userProfileErrorMessage(error, context.l10n),
                ),
                const SizedBox(height: AppSpacing.space3),
                RikiSecondaryButton(
                  label: context.l10n.retry,
                  onPressed: () =>
                      ref.read(userProfileControllerProvider.notifier).retry(),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          final profile = state.profile;
          final isSaving =
              state.activeMutation == ProfileMutation.notifications;
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
                  icon: Icons.notifications_none_rounded,
                  colorfulIcon: SakuraColorfulIconType.notifications,
                  title: context.l10n.notificationSettingsTitle,
                  description: context.l10n.notificationSettingsSubtitle,
                ),
                const SizedBox(height: AppSpacing.space6),
                ProfileSettingsGroup(
                  label: context.l10n.notificationPreferencesSection,
                  children: [
                    ProfileSettingsTile(
                      key: const ValueKey<String>('email_notifications_switch'),
                      icon: Icons.email_outlined,
                      title: context.l10n.emailNotifications,
                      subtitle: context.l10n.emailNotificationsDescription,
                      onTap: isSaving
                          ? null
                          : () => _save(
                              ref,
                              email: !profile.emailNotificationsEnabled,
                              system: profile.systemNotificationsEnabled,
                            ),
                      trailing: Switch.adaptive(
                        value: profile.emailNotificationsEnabled,
                        onChanged: isSaving
                            ? null
                            : (value) => _save(
                                ref,
                                email: value,
                                system: profile.systemNotificationsEnabled,
                              ),
                      ),
                    ),
                    ProfileSettingsTile(
                      key: const ValueKey<String>(
                        'system_notifications_switch',
                      ),
                      icon: Icons.notifications_active_outlined,
                      title: context.l10n.systemNotifications,
                      subtitle: context.l10n.systemNotificationsDescription,
                      onTap: isSaving
                          ? null
                          : () => _save(
                              ref,
                              email: profile.emailNotificationsEnabled,
                              system: !profile.systemNotificationsEnabled,
                            ),
                      trailing: Switch.adaptive(
                        value: profile.systemNotificationsEnabled,
                        onChanged: isSaving
                            ? null
                            : (value) => _save(
                                ref,
                                email: profile.emailNotificationsEnabled,
                                system: value,
                              ),
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: isSaving
                      ? Padding(
                          key: const ValueKey<String>(
                            'notification_saving_indicator',
                          ),
                          padding: const EdgeInsets.only(
                            top: AppSpacing.space3,
                          ),
                          child: Center(
                            child: RikiInlineLoader(
                              semanticsLabel: context.l10n.processingSemantics,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
