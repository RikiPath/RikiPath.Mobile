import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

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
    final profileValue = ref.watch(userProfileControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      appBar: ProfileDetailHeader(
        title: context.l10n.notificationSettingsTitle,
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
            child: RikiErrorBanner(
              title: context.l10n.profileLoadFailedTitle,
              message: userProfileErrorMessage(error, context.l10n),
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
