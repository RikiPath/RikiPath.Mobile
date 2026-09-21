import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class JlptGoalScreen extends ConsumerStatefulWidget {
  const JlptGoalScreen({super.key});

  @override
  ConsumerState<JlptGoalScreen> createState() => _JlptGoalScreenState();
}

class _JlptGoalScreenState extends ConsumerState<JlptGoalScreen> {
  JlptLevel? _selectedLevel;
  int? _selectedMinutes;
  bool _initialized = false;

  void _initialize(JlptLevel? level, int minutes) {
    if (_initialized) return;
    _selectedLevel = level;
    _selectedMinutes = minutes > 0 ? minutes : null;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileValue = ref.watch(userProfileControllerProvider);
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
            child: RikiErrorBanner(
              title: context.l10n.profileLoadFailedTitle,
              message: userProfileErrorMessage(error, context.l10n),
            ),
          ),
        ),
        data: (state) {
          final profile = state.profile;
          _initialize(profile.supportedJlptLevel, profile.dailyStudyMinutes);
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
                  title: context.l10n.jlptGoalSettings,
                  description: context.l10n.jlptGoalSettingsSubtitle,
                ),
                const SizedBox(height: AppSpacing.space6),
                ProfileSettingsGroup(
                  label: context.l10n.learningProfile,
                  children: [
                    ProfileSettingsTile(
                      icon: Icons.flag_outlined,
                      title: context.l10n.currentJlptGoal,
                      subtitle:
                          profile.supportedJlptLevel?.label ??
                          context.l10n.notConfigured,
                      onTap: null,
                      trailing: profile.supportedJlptLevel == null
                          ? null
                          : JlptBadge(profile.supportedJlptLevel!),
                    ),
                    ProfileSettingsTile(
                      icon: Icons.schedule_outlined,
                      title: context.l10n.currentDailyStudyTime,
                      subtitle: profile.dailyStudyMinutes > 0
                          ? context.l10n.studyMinutesPerDay(
                              profile.dailyStudyMinutes,
                            )
                          : context.l10n.notConfigured,
                      onTap: null,
                      trailing: profile.dailyStudyMinutes > 0
                          ? Text(
                              context.l10n.studyMinutesPerDay(
                                profile.dailyStudyMinutes,
                              ),
                              style: AppTypography.cardTitle,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space6),
                ProfileFormSection(
                  title: context.l10n.jlptSelectionTitle,
                  child: Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: [
                      for (final level in JlptLevel.values)
                        ChoiceChip(
                          key: ValueKey<String>(
                            'jlpt_goal_choice_${level.label}',
                          ),
                          label: Text(level.label),
                          selected: _selectedLevel == level,
                          onSelected: (_) =>
                              setState(() => _selectedLevel = level),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                ProfileFormSection(
                  title: context.l10n.dailyStudySelectionTitle,
                  child: Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space2,
                    children: [
                      for (final minutes in const [15, 30, 45, 60])
                        ChoiceChip(
                          key: ValueKey<String>('daily_study_choice_$minutes'),
                          label: Text(context.l10n.studyMinutesPerDay(minutes)),
                          selected: _selectedMinutes == minutes,
                          onSelected: (_) =>
                              setState(() => _selectedMinutes = minutes),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                RikiErrorBanner(
                  key: const ValueKey<String>('jlpt_mapping_blocker'),
                  title: context.l10n.jlptGoalMappingUnavailableTitle,
                  message: context.l10n.jlptSelectionSafeHint,
                ),
                const SizedBox(height: AppSpacing.space4),
                RikiPrimaryButton(
                  key: const ValueKey<String>('jlpt_goal_save_button'),
                  label: context.l10n.saveChanges,
                  onPressed: null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
