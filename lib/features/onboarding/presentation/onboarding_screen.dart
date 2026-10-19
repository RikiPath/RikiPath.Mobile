import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final catalog = ref.watch(jlptCatalogControllerProvider);

    return PopScope(
      canPop: state.currentStep == OnboardingStep.jlptTarget,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) controller.goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: switch (state.currentStep) {
            OnboardingStep.jlptTarget => _JlptTargetStep(
              state: state,
              catalog: catalog,
              onBack: () => _leaveOnboarding(context),
              onSelect: controller.selectJlptLevel,
              onRetry: ref.read(jlptCatalogControllerProvider.notifier).retry,
              onContinue: controller.continueToStudyTime,
            ),
            OnboardingStep.studyTime => _StudyTimeStep(
              state: state,
              onBack: controller.goBack,
              onSelect: controller.selectStudyTime,
              onComplete: () => _completeSetup(ref, controller),
            ),
            OnboardingStep.complete => _CompletionStep(
              state: state,
              onStart: () => context.go(AppRoutes.home),
            ),
          },
        ),
      ),
    );
  }

  void _leaveOnboarding(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.login);
  }

  Future<void> _completeSetup(
    WidgetRef ref,
    OnboardingController controller,
  ) async {
    final state = ref.read(onboardingControllerProvider);
    final level = state.selectedJlptLevel;
    final studyTime = state.selectedStudyTime;
    if (level == null || studyTime == null || state.isSubmitting) return;

    controller.startSubmission();
    try {
      await ref
          .read(userProfileRepositoryProvider)
          .setJlptGoal(
            targetJlptLevelId: level.id,
            dailyStudyMinutes: studyTime.minutes,
          );
      await ref
          .read(learnerJourneyControllerProvider.notifier)
          .setCatalogPreferences(
            item: level,
            dailyStudyMinutes: studyTime.minutes,
          );
      ref.invalidate(userProfileControllerProvider);
      controller.completeLocally();
    } catch (_) {
      controller.failSubmission();
    }
  }
}

class _JlptTargetStep extends StatelessWidget {
  const _JlptTargetStep({
    required this.state,
    required this.catalog,
    required this.onBack,
    required this.onSelect,
    required this.onRetry,
    required this.onContinue,
  });

  final OnboardingState state;
  final AsyncValue<List<JlptLevelCatalogItem>> catalog;
  final VoidCallback onBack;
  final ValueChanged<JlptLevelCatalogItem> onSelect;
  final VoidCallback onRetry;
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
      title: l10n.onboardingJlptTitle,
      description: l10n.onboardingJlptDescription,
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
                children: levels.map((item) {
                  final level = item.level;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: RikiSelectionCard(
                      key: ValueKey<String>('jlpt_${level.name}'),
                      title: item.code,
                      description:
                          item.description ?? _descriptionFor(level, l10n),
                      badge: level == JlptLevel.n3 ? l10n.popular : null,
                      leading: _JlptLevelTile(
                        level: level,
                        selected: state.selectedJlptLevel?.id == item.id,
                      ),
                      selected: state.selectedJlptLevel?.id == item.id,
                      onPressed: () => onSelect(item),
                    ),
                  );
                }).toList(),
              ),
      ),
      action: RikiPrimaryButton(
        key: const ValueKey<String>('onboarding_continue_button'),
        label: l10n.continueLabel,
        trailingIcon: Icons.arrow_forward,
        onPressed: state.canContinue ? onContinue : null,
      ),
      helperText: l10n.onboardingJlptHelper,
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
    required this.onComplete,
  });

  final OnboardingState state;
  final VoidCallback onBack;
  final ValueChanged<DailyStudyTime> onSelect;
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
        children: DailyStudyTime.values.map((studyTime) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: RikiSelectionCard(
              key: ValueKey<String>('study_time_${studyTime.minutes}'),
              title: l10n.studyMinutesPerDay(studyTime.minutes),
              description: _studyPaceDescription(studyTime, l10n),
              badge: studyTime == DailyStudyTime.thirty
                  ? l10n.mostPopular
                  : null,
              leading: _StudyTimeTile(
                studyTime: studyTime,
                selected: state.selectedStudyTime == studyTime,
              ),
              selected: state.selectedStudyTime == studyTime,
              onPressed: () => onSelect(studyTime),
            ),
          );
        }).toList(),
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
    final studyTime = state.selectedStudyTime!;

    return _OnboardingPage(
      header: RikiAuthHeader(statusLabel: l10n.setupCompleteStatus),
      centered: true,
      title: l10n.readyToStart,
      description: l10n.learningPlanReady,
      beforeTitle: const _OnboardingSuccessIllustration(),
      content: RikiCard(
        backgroundColor: AppColors.successBackground,
        borderColor: AppColors.successBorder,
        boxShadow: const <BoxShadow>[],
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
                      studyTime.minutes,
                      _studyPaceDescription(studyTime, l10n),
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textBody,
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
    this.helperText,
    this.centered = false,
  });

  final Widget header;
  final String title;
  final String description;
  final Widget content;
  final Widget action;
  final Widget? beforeTitle;
  final String? helperText;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360
            ? AppSpacing.screenHorizontalCompact
            : AppSpacing.screenHorizontal;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.space3,
            horizontalPadding,
            AppSpacing.bottomActionPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      AppSpacing.space3 -
                      AppSpacing.bottomActionPadding,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      if (beforeTitle != null) ...[
                        const SizedBox(height: AppSpacing.space8),
                        beforeTitle!,
                      ] else
                        const SizedBox(height: AppSpacing.space8),
                      Text(
                        title,
                        textAlign: centered ? TextAlign.center : TextAlign.left,
                        style: AppTypography.pageTitle,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        description,
                        textAlign: centered ? TextAlign.center : TextAlign.left,
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.space7),
                      content,
                      const Spacer(),
                      const SizedBox(height: AppSpacing.space6),
                      action,
                      if (helperText != null) ...[
                        const SizedBox(height: AppSpacing.space3),
                        Text(
                          helperText!,
                          textAlign: TextAlign.center,
                          style: AppTypography.metadata,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
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
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            borderRadius: BorderRadius.circular(AppRadius.input),
            boxShadow: AppShadows.cardSoft,
          ),
          child: const Text(
            '文',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
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

class _StudyTimeTile extends StatelessWidget {
  const _StudyTimeTile({required this.studyTime, required this.selected});

  final DailyStudyTime studyTime;
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
      child: Icon(
        _iconFor(studyTime),
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
    );
  }

  IconData _iconFor(DailyStudyTime value) {
    return switch (value) {
      DailyStudyTime.fifteen => Icons.eco_outlined,
      DailyStudyTime.thirty => Icons.balance_outlined,
      DailyStudyTime.fortyFive => Icons.local_fire_department_outlined,
      DailyStudyTime.sixty => Icons.workspace_premium_outlined,
    };
  }
}

class _OnboardingSuccessIllustration extends StatelessWidget {
  const _OnboardingSuccessIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: context.l10n.setupCompleteSemantics,
        child: SizedBox.square(
          dimension: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  color: AppColors.successBackgroundSoft,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const Positioned(
                right: 8,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.successAccent,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
