import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final catalog = ref.watch(jlptCatalogControllerProvider);

    return PopScope(
      canPop: state.currentStep == OnboardingStep.studyLevels,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) controller.goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (state.currentStep) {
            OnboardingStep.studyLevels => _StudyLevelsStep(
              state: state,
              catalog: catalog,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              onSelectCurrent: controller.selectCurrentStudyLevel,
              onSelectTarget: controller.selectJlptLevel,
              onRetry: ref.read(jlptCatalogControllerProvider.notifier).retry,
              onTakePlacement: () => context.push(AppRoutes.placementTest),
              onContinue: () => _continueToStudyTime(ref, controller),
            ),
            OnboardingStep.studyTime => _StudyTimeStep(
              state: state,
              onBack: controller.goBack,
              onSelect: controller.selectStudyTime,
              onCustom: controller.selectCustomStudyMinutes,
              onSelectExamDate: () =>
                  _selectExamDate(context, controller, state.targetExamDate),
              onComplete: () => _completeSetup(ref, controller),
            ),
            OnboardingStep.complete => _CompletionStep(
              state: state,
              onStart: () => context.go(AppRoutes.learnRoadmap),
            ),
          },
        ),
      ),
    );
  }

  Future<void> _completeSetup(
    WidgetRef ref,
    OnboardingController controller,
  ) async {
    final state = ref.read(onboardingControllerProvider);
    final currentLevel = state.selectedCurrentStudyLevel;
    final level = state.selectedJlptLevel;
    final targetExamDate = state.targetExamDate;
    final dailyMinutes =
        state.selectedStudyTime?.minutes ?? state.dailyStudyMinutes ?? 30;
    if (currentLevel == null || level == null || state.isSubmitting) {
      return;
    }

    controller.startSubmission();
    try {
      final repository = ref.read(userProfileRepositoryProvider);
      if (repository is! StudyLevelProfileRepository) {
        throw UnsupportedError('Current study level cannot be persisted.');
      }
      await (repository as StudyLevelProfileRepository).switchStudyLevel(
        currentStudyLevelId: currentLevel.id,
      );
      final UserProfile savedProfile;
      if (targetExamDate != null) {
        if (repository is! TargetExamDateProfileRepository) {
          throw UnsupportedError('Target exam date cannot be persisted.');
        }
        savedProfile = await (repository as TargetExamDateProfileRepository)
            .setJlptGoalWithExamDate(
              targetJlptLevelId: level.id,
              dailyStudyMinutes: dailyMinutes,
              targetExamDate: targetExamDate,
            );
      } else {
        savedProfile = await repository.setJlptGoal(
          targetJlptLevelId: level.id,
          dailyStudyMinutes: dailyMinutes,
        );
      }
      if (savedProfile.currentStudyLevelId != currentLevel.id ||
          savedProfile.targetJlptLevelId != level.id ||
          savedProfile.dailyStudyMinutes != dailyMinutes ||
          (targetExamDate != null &&
              !DateUtils.isSameDay(
                savedProfile.targetExamDate,
                targetExamDate,
              ))) {
        throw StateError(
          'Profile save response does not match the learning goal.',
        );
      }
      await ref
          .read(learnerJourneyControllerProvider.notifier)
          .setCatalogPreferences(
            item: currentLevel,
            dailyStudyMinutes: dailyMinutes,
          );
      ref.invalidate(userProfileControllerProvider);
      ref.invalidate(placementTestControllerProvider);
      ref.invalidate(standardRoadmapProvider);
      controller.completeLocally();
    } catch (_) {
      controller.failSubmission();
    }
  }

  Future<void> _continueToStudyTime(
    WidgetRef ref,
    OnboardingController controller,
  ) async {
    final state = ref.read(onboardingControllerProvider);
    if (!state.canContinue || state.isSubmitting) return;
    if (state.placementDecisionRecorded) {
      controller.continueToStudyTime();
      return;
    }
    controller.startPlacementSkip();
    try {
      final repository = ref.read(placementTestRepositoryProvider);
      final status = await repository.loadStatus();
      if (!status.hasCompletedPlacementTest &&
          status.placementDecision != PlacementDecision.skipped) {
        if (repository is! PlacementSkipRepository) {
          throw UnsupportedError('Placement skip is not supported.');
        }
        await (repository as PlacementSkipRepository).skip();
      }
      ref.invalidate(placementTestControllerProvider);
      controller.recordPlacementDecision();
      controller.continueToStudyTime();
    } catch (_) {
      controller.failSubmission();
      controller.placementSkipFailed();
    }
  }

  Future<void> _selectExamDate(
    BuildContext context,
    OnboardingController controller,
    DateTime? current,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = today.add(const Duration(days: 1));
    final selected = await showDatePicker(
      context: context,
      initialDate: current == null || current.isBefore(firstDate)
          ? firstDate.add(const Duration(days: 179))
          : current,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (selected != null) controller.selectTargetExamDate(selected);
  }
}

class _StudyLevelsStep extends StatelessWidget {
  const _StudyLevelsStep({
    required this.state,
    required this.catalog,
    required this.onBack,
    required this.onSelectCurrent,
    required this.onSelectTarget,
    required this.onRetry,
    required this.onTakePlacement,
    required this.onContinue,
  });

  final OnboardingState state;
  final AsyncValue<List<JlptLevelCatalogItem>> catalog;
  final VoidCallback onBack;
  final ValueChanged<JlptLevelCatalogItem> onSelectCurrent;
  final ValueChanged<JlptLevelCatalogItem> onSelectTarget;
  final VoidCallback onRetry;
  final VoidCallback onTakePlacement;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _OnboardingPage(
      header: _StepHeader(
        step: 1,
        onBack: onBack,
        backSemanticLabel: l10n.leaveSetup,
      ),
      title: l10n.onboardingStudyLevelsTitle,
      description: l10n.onboardingStudyLevelsDescription,
      content: catalog.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.space5),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => RikiCard(
          key: const ValueKey<String>('onboarding_jlpt_catalog_error'),
          child: Column(
            children: [
              Text(
                l10n.jlptCatalogLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.validationText,
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
        data: (levels) => levels.isEmpty
            ? RikiCard(
                key: const ValueKey<String>('onboarding_jlpt_catalog_empty'),
                child: Text(
                  l10n.jlptCatalogEmpty,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.onboardingCurrentStudyLevelTitle,
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    l10n.onboardingCurrentStudyLevelDescription,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  ...levels
                      .where(
                        (item) => const <String>{
                          'N5',
                          'N4',
                          'N3',
                        }.contains(item.code.toUpperCase()),
                      )
                      .map(
                        (item) => _levelCard(
                          item: item,
                          selected:
                              state.selectedCurrentStudyLevel?.id == item.id,
                          keyPrefix: 'current_level',
                          onPressed: () => onSelectCurrent(item),
                          l10n: l10n,
                        ),
                      ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    l10n.onboardingTargetJlptTitle,
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    l10n.onboardingTargetJlptDescription,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  ...levels
                      .where((item) => item.level != JlptLevel.n1)
                      .map(
                        (item) => _levelCard(
                          item: item,
                          selected: state.selectedJlptLevel?.id == item.id,
                          keyPrefix: 'jlpt',
                          onPressed: state.selectedCurrentStudyLevel == null
                              ? null
                              : () => onSelectTarget(item),
                          l10n: l10n,
                        ),
                      ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.onboardingPlacementTitle,
                          style: AppTypography.cardTitle,
                        ),
                        Text(
                          l10n.onboardingPlacementDescription,
                          style: AppTypography.metadata,
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        RikiSecondaryButton(
                          key: const ValueKey<String>(
                            'onboarding_placement_test_button',
                          ),
                          label: l10n.onboardingPlacementAction,
                          leadingIcon: Icons.analytics_outlined,
                          onPressed: state.isSubmitting
                              ? null
                              : onTakePlacement,
                        ),
                        Text(
                          l10n.onboardingPlacementCanTakeLater,
                          style: AppTypography.metadata,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      action: RikiPrimaryButton(
        key: const ValueKey<String>('onboarding_continue_button'),
        label: l10n.continueLabel,
        trailingIcon: Icons.arrow_forward,
        isLoading: state.isSubmitting,
        loadingLabel: l10n.loading,
        onPressed: state.canContinue && !state.isSubmitting ? onContinue : null,
      ),
      helperText: state.placementSkipFailed
          ? l10n.checkConnectionRetry
          : l10n.onboardingJlptHelper,
    );
  }

  Widget _levelCard({
    required JlptLevelCatalogItem item,
    required bool selected,
    required String keyPrefix,
    required VoidCallback? onPressed,
    required AppLocalizations l10n,
  }) {
    final level = item.level;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Material(
        key: ValueKey<String>('${keyPrefix}_${level.name}'),
        color: selected ? AppColors.brandTint : AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected
                ? AppColors.brandPrimary
                : AppColors.borderSubtlePink,
          ),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            child: Row(
              children: [
                _JlptLevelTile(level: level, selected: selected),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    item.description ?? _descriptionFor(level, l10n),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.brandPrimary
                      : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(JlptLevel level, AppLocalizations l10n) {
    return switch (level) {
      JlptLevel.n5 => l10n.jlptN5Description,
      JlptLevel.n4 => l10n.jlptN4Description,
      JlptLevel.n3 => l10n.jlptN3Description,
      JlptLevel.n2 => l10n.jlptN2Description,
      JlptLevel.n1 => l10n.jlptN1Description,
    };
  }
}

class _StudyTimeStep extends StatelessWidget {
  const _StudyTimeStep({
    required this.state,
    required this.onBack,
    required this.onSelect,
    required this.onCustom,
    required this.onSelectExamDate,
    required this.onComplete,
  });

  final OnboardingState state;
  final VoidCallback onBack;
  final ValueChanged<DailyStudyTime> onSelect;
  final ValueChanged<int?> onCustom;
  final VoidCallback onSelectExamDate;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _OnboardingPage(
      header: _StepHeader(
        step: 2,
        onBack: onBack,
        backSemanticLabel: l10n.backToGoalSelection,
        selectedLevel: state.selectedJlptLevel?.level,
      ),
      title: l10n.onboardingStudyTimeTitle,
      description: l10n.onboardingStudyTimeDescription,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - AppSpacing.space2) / 2;
              return Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: [
                  for (final studyTime in DailyStudyTime.values)
                    SizedBox(
                      width: itemWidth,
                      child: Material(
                        key: ValueKey<String>(
                          'study_time_${studyTime.minutes}',
                        ),
                        color: state.selectedStudyTime == studyTime
                            ? AppColors.brandTint
                            : AppColors.surface,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: state.selectedStudyTime == studyTime
                                ? AppColors.brandPrimary
                                : AppColors.borderSubtlePink,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: InkWell(
                          onTap: () => onSelect(studyTime),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.space3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.studyMinutesPerDay(studyTime.minutes),
                                  style: AppTypography.cardTitle,
                                ),
                                Text(
                                  _studyPaceDescription(studyTime, l10n),
                                  style: AppTypography.metadata,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.space2),
          TextFormField(
            key: ValueKey<String>(
              'onboarding_custom_minutes_${state.selectedStudyTime?.minutes ?? 0}',
            ),
            initialValue: state.selectedStudyTime == null
                ? state.dailyStudyMinutes?.toString()
                : null,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              labelText: l10n.onboardingCustomMinutesLabel,
              helperText: l10n.onboardingCustomMinutesHelper,
              errorText:
                  state.customMinutesTouched &&
                      state.selectedStudyTime == null &&
                      state.dailyStudyMinutes == null
                  ? l10n.onboardingCustomMinutesError
                  : null,
              prefixIcon: const Icon(Icons.edit_calendar_outlined),
            ),
            onChanged: (value) => onCustom(int.tryParse(value)),
          ),
          const SizedBox(height: AppSpacing.space2),
          RikiCard(
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                key: const ValueKey<String>('onboarding_exam_date_button'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.event_outlined,
                  color: AppColors.brandPrimary,
                ),
                title: Text(
                  l10n.expectedExam(
                    state.targetExamDate == null
                        ? l10n.notConfigured
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(state.targetExamDate!),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSelectExamDate,
              ),
            ),
          ),
        ],
      ),
      action: RikiPrimaryButton(
        key: const ValueKey<String>('onboarding_complete_button'),
        label: l10n.finishSetup,
        trailingIcon: Icons.check,
        isLoading: state.isSubmitting,
        loadingLabel: l10n.loading,
        onPressed: state.canComplete && !state.isSubmitting ? onComplete : null,
      ),
      helperText: state.submissionFailed
          ? l10n.checkConnectionRetry
          : l10n.onboardingAdjustHelper,
      secondaryAction: TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back),
        label: Text(l10n.back),
      ),
    );
  }

  String _studyPaceDescription(
    DailyStudyTime studyTime,
    AppLocalizations l10n,
  ) {
    return switch (studyTime) {
      DailyStudyTime.fifteen => l10n.studyPaceGentle,
      DailyStudyTime.thirty => l10n.studyPaceBalanced,
      DailyStudyTime.fortyFive => l10n.studyPaceActive,
      DailyStudyTime.sixty => l10n.studyPaceIntensive,
      DailyStudyTime.ninety => l10n.studyPaceIntensive,
    };
  }
}

class _CompletionStep extends StatelessWidget {
  const _CompletionStep({required this.state, required this.onStart});

  final OnboardingState state;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final level = state.selectedJlptLevel!;
    final studyMinutes =
        state.selectedStudyTime?.minutes ?? state.dailyStudyMinutes ?? 30;
    final targetExamDate = state.targetExamDate;

    return _OnboardingPage(
      header: RikiAuthHeader(statusLabel: l10n.setupCompleteStatus),
      centered: true,
      title: l10n.readyToStart,
      description: l10n.learningPlanReady,
      beforeTitle: const _OnboardingSuccessIllustration(),
      content: RikiCard(
        backgroundColor: AppColors.cardWarmWhite,
        borderColor: AppColors.borderSubtlePink,
        boxShadow: AppShadows.sakuraSubtle,
        child: Row(
          children: [
            const Icon(
              Icons.route_outlined,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.jlptGoal(level.code),
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    l10n.studySummary(
                      studyMinutes,
                      state.selectedStudyTime == null
                          ? l10n.studyPaceBalanced
                          : _studyPaceDescription(
                              state.selectedStudyTime!,
                              l10n,
                            ),
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    l10n.expectedExam(
                      targetExamDate == null
                          ? l10n.notConfigured
                          : MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(targetExamDate),
                    ),
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      action: RikiPrimaryButton(
        key: const ValueKey<String>('onboarding_start_button'),
        label: l10n.startLearning,
        trailingIcon: Icons.arrow_forward,
        onPressed: onStart,
      ),
    );
  }

  String _studyPaceDescription(
    DailyStudyTime studyTime,
    AppLocalizations l10n,
  ) {
    return switch (studyTime) {
      DailyStudyTime.fifteen => l10n.studyPaceGentle,
      DailyStudyTime.thirty => l10n.studyPaceBalanced,
      DailyStudyTime.fortyFive => l10n.studyPaceActive,
      DailyStudyTime.sixty => l10n.studyPaceIntensive,
      DailyStudyTime.ninety => l10n.studyPaceIntensive,
    };
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.header,
    required this.title,
    required this.description,
    required this.content,
    required this.action,
    this.beforeTitle,
    this.secondaryAction,
    this.helperText,
    this.centered = false,
  });

  final Widget header;
  final String title;
  final String description;
  final Widget content;
  final Widget action;
  final Widget? beforeTitle;
  final Widget? secondaryAction;
  final String? helperText;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360
            ? AppSpacing.screenHorizontalCompact
            : AppSpacing.screenHorizontal;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.space3,
                  horizontalPadding,
                  AppSpacing.space3,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        SizedBox(
                          height: beforeTitle == null
                              ? AppSpacing.space5
                              : AppSpacing.space4,
                        ),
                        ?beforeTitle,
                        Text(
                          title,
                          textAlign: centered
                              ? TextAlign.center
                              : TextAlign.left,
                          style: AppTypography.pageTitle,
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          description,
                          textAlign: centered
                              ? TextAlign.center
                              : TextAlign.left,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.space5),
                        content,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtlePink),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.space2,
                  horizontalPadding,
                  AppSpacing.space2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        action,
                        ?secondaryAction,
                        if (helperText != null)
                          Text(
                            helperText!,
                            textAlign: TextAlign.center,
                            style: AppTypography.metadata,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.onBack,
    required this.backSemanticLabel,
    this.selectedLevel,
  });

  final int step;
  final VoidCallback onBack;
  final String backSemanticLabel;
  final JlptLevel? selectedLevel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 48,
          child: IconButton(
            onPressed: onBack,
            tooltip: backSemanticLabel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: [
                  if (selectedLevel != null) ...[
                    Text(
                      context.l10n.goalPrefix,
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    JlptBadge(selectedLevel!),
                  ],
                  Text(
                    context.l10n.stepOfTwo(step),
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              RikiProgressIndicator(
                value: step / 2,
                semanticsLabel: context.l10n.setupProgressSemantics(step),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        SizedBox(
          width: 48,
          height: 48,
          child: Image.asset(
            'assets/images/icons_3d/riki_brand_logo.webp',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ],
    );
  }
}

class _JlptLevelTile extends StatelessWidget {
  const _JlptLevelTile({required this.level, required this.selected});

  final JlptLevel level;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.brandPrimary : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Text(
        level.label,
        style: AppTypography.sectionTitle.copyWith(
          color: selected ? Colors.white : AppColors.textBody,
        ),
      ),
    );
  }
}

class _OnboardingSuccessIllustration extends StatelessWidget {
  const _OnboardingSuccessIllustration();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    return Center(
      child: Semantics(
        label: context.l10n.setupCompleteSemantics,
        child: TweenAnimationBuilder<double>(
          key: const ValueKey<String>('onboarding_completion_motion'),
          tween: Tween(begin: 0, end: 1),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 480),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: Transform.scale(
                scale: 0.92 + (0.08 * value),
                child: child,
              ),
            ),
          ),
          child: SizedBox(
            height: 238,
            child: Image.asset(
              'assets/images/auth/sakura_onboarding_complete.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
