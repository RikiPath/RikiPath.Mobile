import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';
import 'package:rikipath_mobile/features/profile/presentation/widgets/profile_detail_components.dart';

class JlptGoalScreen extends ConsumerStatefulWidget {
  const JlptGoalScreen({super.key});

  @override
  ConsumerState<JlptGoalScreen> createState() => _JlptGoalScreenState();
}

class _JlptGoalScreenState extends ConsumerState<JlptGoalScreen> {
  JlptLevelCatalogItem? _selectedLevel;
  int? _selectedMinutes;
  bool _initialized = false;

  void _initialize(JlptLevelCatalogItem level, int minutes) {
    if (_initialized) return;
    _selectedLevel = level;
    _selectedMinutes = minutes > 0 ? minutes : null;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileValue = ref.watch(userProfileControllerProvider);
    final localJourneyValue = ref.watch(learnerJourneyControllerProvider);
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
            child: RikiErrorBanner(
              title: context.l10n.profileLoadFailedTitle,
              message: userProfileErrorMessage(error, context.l10n),
            ),
          ),
        ),
        data: (profileState) {
          final localJourney = localJourneyValue.value;
          if (localJourney == null) {
            return const ProfileDetailSkeleton(
              key: ValueKey<String>('profile_jlpt_local_loading_view'),
              groupCount: 3,
              rowsPerGroup: 1,
            );
          }
          final levels = catalogValue.value;
          if (levels != null && levels.isNotEmpty) {
            final profile = profileState.profile;
            final selected = levels
                .where(
                  (item) =>
                      item.id == profile.targetJlptLevelId ||
                      (profile.targetJlptLevelId == null &&
                          item.id == localJourney.selectedLevelId) ||
                      (profile.targetJlptLevelId == null &&
                          localJourney.selectedLevelId == null &&
                          item.level == localJourney.selectedLevel),
                )
                .firstOrNull;
            if (selected != null) {
              _initialize(selected, localJourney.dailyStudyMinutes);
            }
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
                      subtitle: localJourney.hasSelectedLevel
                          ? localJourney.selectedLevel.label
                          : context.l10n.notConfigured,
                      onTap: null,
                      trailing: localJourney.hasSelectedLevel
                          ? JlptBadge(localJourney.selectedLevel)
                          : null,
                    ),
                    ProfileSettingsTile(
                      icon: Icons.schedule_outlined,
                      title: context.l10n.currentDailyStudyTime,
                      subtitle: context.l10n.studyMinutesPerDay(
                        localJourney.dailyStudyMinutes,
                      ),
                      onTap: null,
                      trailing: Text(
                        context.l10n.studyMinutesPerDay(
                          localJourney.dailyStudyMinutes,
                        ),
                        style: AppTypography.cardTitle,
                      ),
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
                      ...catalogValue.when(
                        loading: () => <Widget>[
                          const CircularProgressIndicator(strokeWidth: 2),
                        ],
                        error: (_, _) => <Widget>[
                          Text(
                            context.l10n.jlptCatalogLoadFailed,
                            style: AppTypography.validationText,
                          ),
                          TextButton(
                            onPressed: ref
                                .read(jlptCatalogControllerProvider.notifier)
                                .retry,
                            child: Text(context.l10n.retry),
                          ),
                        ],
                        data: (levels) => levels.isEmpty
                            ? <Widget>[Text(context.l10n.jlptCatalogEmpty)]
                            : <Widget>[
                                for (final item in levels)
                                  ChoiceChip(
                                    key: ValueKey<String>(
                                      'jlpt_goal_choice_${item.code}',
                                    ),
                                    label: Text(item.code),
                                    selected: _selectedLevel?.id == item.id,
                                    onSelected: (_) =>
                                        setState(() => _selectedLevel = item),
                                  ),
                              ],
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
                RikiPrimaryButton(
                  key: const ValueKey<String>('jlpt_goal_save_button'),
                  label: context.l10n.saveChanges,
                  onPressed: _selectedLevel == null || _selectedMinutes == null
                      ? null
                      : () async {
                          final updated = await ref
                              .read(userProfileControllerProvider.notifier)
                              .setJlptGoal(
                                targetJlptLevelId: _selectedLevel!.id,
                                dailyStudyMinutes: _selectedMinutes!,
                              );
                          if (!updated) return;
                          await ref
                              .read(learnerJourneyControllerProvider.notifier)
                              .setCatalogPreferences(
                                item: _selectedLevel!,
                                dailyStudyMinutes: _selectedMinutes!,
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
