import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:rikipath_mobile/features/onboarding/domain/jlpt_exam_session.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

/// Goal summary. Create and Edit both use the four-step onboarding wizard.
class JlptGoalScreen extends ConsumerStatefulWidget {
  const JlptGoalScreen({super.key});

  @override
  ConsumerState<JlptGoalScreen> createState() => _JlptGoalScreenState();
}

class _JlptGoalScreenState extends ConsumerState<JlptGoalScreen> {
  bool _didAutoOpenOnboarding = false;

  void _openCreateGoalOnboarding() {
    ref
        .read(onboardingControllerProvider.notifier)
        .startCreateFromProfile(
          origin: OnboardingOrigin.profile,
          returnTo: AppRoutes.profileJlptGoal,
        );
    context.push(
      AppRoutes.onboardingWithOrigin(
        OnboardingOrigin.profile,
        returnTo: AppRoutes.profileJlptGoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileValue = ref.watch(userProfileControllerProvider);
    final catalogValue = ref.watch(jlptCatalogControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.profileBackground,
      appBar: ProfileDetailHeader(title: context.l10n.jlptGoalSettings),
      body: profileValue.when(
        loading: () => const ProfileDetailSkeleton(
          key: ValueKey<String>('profile_jlpt_loading_view'),
          groupCount: 3,
          rowsPerGroup: 1,
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
                TextButton(
                  onPressed: ref
                      .read(userProfileControllerProvider.notifier)
                      .retry,
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (profileState) {
          final profile = profileState.profile;
          if (profile.targetJlptLevelId == null ||
              profile.currentStudyLevelId == null ||
              profile.dailyStudyMinutes <= 0) {
            if (!_didAutoOpenOnboarding) {
              _didAutoOpenOnboarding = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                _openCreateGoalOnboarding();
              });
              return const ProfileDetailSkeleton(
                key: ValueKey<String>('profile_jlpt_create_redirect'),
                groupCount: 1,
                rowsPerGroup: 1,
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const RikiEmptyState(
                      icon: Icons.flag_outlined,
                      title: 'Chưa có mục tiêu JLPT',
                      message:
                          'Thiết lập trình độ hiện tại, mục tiêu JLPT và thời gian học mỗi ngày để tạo lộ trình cá nhân hóa.',
                    ),
                    const SizedBox(height: AppSpacing.space5),
                    RikiPrimaryButton(
                      key: const ValueKey<String>(
                        'jlpt_goal_setup_button',
                      ),
                      label: 'Thiết lập mục tiêu JLPT',
                      onPressed: _openCreateGoalOnboarding,
                    ),
                  ],
                ),
              ),
            );
          }

          final levels = catalogValue.value;
          if (levels == null) {
            return Center(
              child: catalogValue.isLoading
                  ? SakuraSectionLoading(
                      title: context.l10n.loadingOverlayDataTitle,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.l10n.jlptCatalogLoadFailed),
                        TextButton(
                          onPressed: ref
                              .read(jlptCatalogControllerProvider.notifier)
                              .retry,
                          child: Text(context.l10n.retry),
                        ),
                      ],
                    ),
            );
          }

          JlptLevelCatalogItem? byId(int? id) =>
              levels.where((item) => item.id == id).firstOrNull;
          final current = byId(profile.currentStudyLevelId);
          final target = byId(profile.targetJlptLevelId);
          final certified = byId(profile.certifiedJlptLevelId);
          final examSession = JlptExamCalendar.fromStoredDate(
            profile.targetExamDate,
          );
          if (current == null ||
              target == null ||
              (profile.hasJlptCertificate && certified == null)) {
            return Center(
              child: RikiErrorBanner(
                title: 'Chưa thể chỉnh sửa mục tiêu',
                message:
                    'Cấp độ đã lưu không còn trong danh mục. Vui lòng tải lại hoặc liên hệ hỗ trợ.',
              ),
            );
          }

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
                  icon: Icons.track_changes_outlined,
                  colorfulIcon: SakuraColorfulIconType.learningGoal,
                  title: context.l10n.jlptGoalSettings,
                  description: context.l10n.jlptGoalSettingsSubtitle,
                ),
                const SizedBox(height: AppSpacing.space6),
                ProfileSettingsGroup(
                  label: context.l10n.learningProfile,
                  children: [
                    ProfileSettingsTile(
                      icon: Icons.school_outlined,
                      title: context.l10n.onboardingCurrentStudyLevelTitle,
                      subtitle: current.code,
                      onTap: null,
                    ),
                    ProfileSettingsTile(
                      icon: Icons.flag_outlined,
                      title: context.l10n.currentJlptGoal,
                      subtitle: target.code,
                      onTap: null,
                    ),
                    ProfileSettingsTile(
                      icon: Icons.schedule_outlined,
                      title: context.l10n.currentDailyStudyTime,
                      subtitle: context.l10n.studyMinutesPerDay(
                        profile.dailyStudyMinutes,
                      ),
                      onTap: null,
                    ),
                    ProfileSettingsTile(
                      icon: Icons.event_outlined,
                      title: context.l10n.onboardingExamSessionCardTitle,
                      subtitle: profile.targetExamDate == null
                          ? context.l10n.notConfigured
                          : examSession == null
                          ? MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(profile.targetExamDate!)
                          : 'Tháng ${examSession.month}, ${examSession.year} · Dự kiến',
                      onTap: null,
                    ),
                    ProfileSettingsTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Chứng chỉ JLPT tự khai báo',
                      subtitle: certified?.code ?? 'Chưa có',
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space6),
                RikiPrimaryButton(
                  key: const ValueKey<String>('jlpt_goal_edit_button'),
                  label: 'Chỉnh sửa mục tiêu',
                  onPressed: () {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .startEditFromProfile(
                          currentStudyLevel: current,
                          targetLevel: target,
                          dailyMinutes: profile.dailyStudyMinutes,
                          targetExamDate: profile.targetExamDate,
                          certifiedJlptLevel: certified,
                          goalVersion: profile.learningGoalVersion,
                          origin: OnboardingOrigin.profileGoal,
                          returnTo: AppRoutes.profileJlptGoal,
                        );
                    context.push(
                      AppRoutes.onboardingWithOrigin(
                        OnboardingOrigin.profileGoal,
                        returnTo: AppRoutes.profileJlptGoal,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
