import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:rikipath_mobile/features/onboarding/domain/jlpt_exam_session.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/widgets/sakura_animated_step_progress.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/widgets/sakura_learning_plan_preview.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.origin = OnboardingOrigin.auth,
    this.returnTo,
  });

  final OnboardingOrigin origin;
  final String? returnTo;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  OnboardingStep? _lastStep;
  bool _isForward = true;

  void _syncRouteContext() {
    ref
        .read(onboardingControllerProvider.notifier)
        .syncRouteContext(origin: widget.origin, returnTo: widget.returnTo);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncRouteContext();
      }
    });
  }

  @override
  void didUpdateWidget(covariant OnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin != widget.origin ||
        oldWidget.returnTo != widget.returnTo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncRouteContext();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final catalog = ref.watch(jlptCatalogControllerProvider);
    final l10n = context.l10n;
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);

    if (_lastStep != state.currentStep) {
      if (_lastStep != null) {
        _isForward = state.currentStep.index >= _lastStep!.index;
      }
      _lastStep = state.currentStep;
    }

    final effectiveOrigin = state.isEditing
        ? (widget.origin != OnboardingOrigin.auth
              ? widget.origin
              : (state.origin != OnboardingOrigin.auth
                    ? state.origin
                    : OnboardingOrigin.profileGoal))
        : (widget.origin != OnboardingOrigin.auth
              ? widget.origin
              : state.origin);
    final effectiveReturnTo = widget.returnTo ?? state.returnTo;
    final String cancelFallback = switch (effectiveOrigin) {
      OnboardingOrigin.profileGoal =>
        effectiveReturnTo ?? AppRoutes.profileJlptGoal,
      OnboardingOrigin.profile => effectiveReturnTo ?? AppRoutes.profile,
      OnboardingOrigin.roadmap => effectiveReturnTo ?? AppRoutes.learnRoadmap,
      OnboardingOrigin.auth => AppRoutes.home,
    };

    void exitToCaller({bool? result}) {
      final router = GoRouter.maybeOf(context);
      final canPop = router?.canPop() ?? Navigator.of(context).canPop();
      controller.resetForExit();
      if (canPop) {
        popOrGo(context, cancelFallback, result: result);
      } else {
        context.go(cancelFallback);
      }
    }

    Future<void> confirmAndExitCreateFromCaller() async {
      if (!state.hasUnsavedChanges) {
        exitToCaller();
        return;
      }
      final discard = await confirmDiscardChanges(
        context,
        title: 'Rời thiết lập mục tiêu?',
        message: 'Bạn có lựa chọn chưa lưu. Bạn muốn ở lại hay quay lại?',
        stayLabel: 'Ở lại',
        discardLabel: 'Rời đi',
      );
      if (discard && context.mounted) {
        exitToCaller();
      }
    }

    Future<void> skipSetup() async {
      if (state.isEditing) {
        if (!state.hasUnsavedChanges) {
          exitToCaller();
          return;
        }
        final discard = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Hủy chỉnh sửa mục tiêu?'),
            content: const Text('Các thay đổi chưa lưu sẽ không được áp dụng.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Tiếp tục chỉnh sửa'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Hủy chỉnh sửa'),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          exitToCaller();
        }
        return;
      }
      if (effectiveOrigin == OnboardingOrigin.auth) {
        controller.resetForExit();
        context.go(AppRoutes.home);
        return;
      }
      await confirmAndExitCreateFromCaller();
    }

    Future<void> handleAuthStep1AndroidBack() async {
      if (!state.hasUnsavedChanges) {
        return;
      }
      final leave = await confirmDiscardChanges(
        context,
        title: 'Tạm dừng thiết lập mục tiêu?',
        message:
            'Bạn có muốn rời màn hình thiết lập và chuyển sang Trang chủ không?',
        stayLabel: 'Ở lại',
        discardLabel: 'Về Trang chủ',
      );
      if (leave && context.mounted) {
        controller.resetForExit();
        context.go(AppRoutes.home);
      }
    }

    Widget buildWizardStepBody() {
      return switch (state.currentStep) {
        OnboardingStep.currentLevel => _StudyLevelsStep(
          state: state,
          catalog: catalog,
          showCurrent: true,
          onSelectCurrent: controller.selectCurrentStudyLevel,
          onSelectTarget: controller.selectJlptLevel,
          onSetHasCertificate: controller.setHasJlptCertificate,
          onSelectCertifiedLevel: controller.selectCertifiedJlptLevel,
          onRetry: ref.read(jlptCatalogControllerProvider.notifier).retry,
          onTakePlacement: () => context.push(AppRoutes.placementTest),
        ),
        OnboardingStep.targetLevel => _StudyLevelsStep(
          state: state,
          catalog: catalog,
          showCurrent: false,
          onSelectCurrent: controller.selectCurrentStudyLevel,
          onSelectTarget: controller.selectJlptLevel,
          onSetHasCertificate: controller.setHasJlptCertificate,
          onSelectCertifiedLevel: controller.selectCertifiedJlptLevel,
          onRetry: ref.read(jlptCatalogControllerProvider.notifier).retry,
          onTakePlacement: () => context.push(AppRoutes.placementTest),
        ),
        OnboardingStep.studyTime => _StudyTimeStep(
          state: state,
          onSelect: controller.selectStudyTime,
          onSelectCustomOption: controller.selectCustomTimeOption,
          onCustom: controller.selectCustomStudyMinutes,
        ),
        OnboardingStep.examPlan => _ExamPlanStep(
          state: state,
          onSelectExamDate: () =>
              _selectExamSession(context, controller, state.targetExamDate),
        ),
        OnboardingStep.complete => const SizedBox.shrink(),
      };
    }

    Widget buildWizardAction() {
      return switch (state.currentStep) {
        OnboardingStep.currentLevel => RikiPrimaryButton(
          key: const ValueKey<String>('onboarding_continue_button'),
          label: l10n.continueLabel,
          trailingIcon: Icons.arrow_forward,
          onPressed: state.canContinueCurrentLevel
              ? controller.continueToTargetLevel
              : null,
        ),
        OnboardingStep.targetLevel => RikiPrimaryButton(
          key: const ValueKey<String>('onboarding_continue_button'),
          label: l10n.continueLabel,
          trailingIcon: Icons.arrow_forward,
          onPressed: state.canContinueTargetLevel
              ? controller.continueToStudyTime
              : null,
        ),
        OnboardingStep.studyTime => RikiPrimaryButton(
          key: const ValueKey<String>('onboarding_study_continue_button'),
          label: l10n.continueLabel,
          trailingIcon: Icons.arrow_forward,
          onPressed: state.canComplete ? controller.continueToExamPlan : null,
        ),
        OnboardingStep.examPlan => RikiPrimaryButton(
          key: const ValueKey<String>('onboarding_complete_button'),
          label: state.isEditing ? l10n.saveChanges : l10n.finishSetup,
          trailingIcon: Icons.check,
          isLoading: state.isSubmitting,
          loadingLabel: l10n.loading,
          onPressed: state.canComplete && !state.isSubmitting
              ? () => _completeSetup(context, ref, controller)
              : null,
        ),
        OnboardingStep.complete => const SizedBox.shrink(),
      };
    }

    final int wizardStepNumber = switch (state.currentStep) {
      OnboardingStep.currentLevel => 1,
      OnboardingStep.targetLevel => 2,
      OnboardingStep.studyTime => 3,
      OnboardingStep.examPlan => 4,
      OnboardingStep.complete => 4,
    };

    final String backSemanticLabel = switch (state.currentStep) {
      OnboardingStep.currentLevel => l10n.leaveSetup,
      OnboardingStep.targetLevel => l10n.back,
      OnboardingStep.studyTime => l10n.backToGoalSelection,
      OnboardingStep.examPlan || OnboardingStep.complete => l10n.back,
    };

    final bool showStepBackButton =
        state.isEditing ||
        effectiveOrigin != OnboardingOrigin.auth ||
        state.currentStep != OnboardingStep.currentLevel;
    final bool allowAuthRootSystemBack =
        !state.isSubmitting &&
        !state.isEditing &&
        effectiveOrigin == OnboardingOrigin.auth &&
        state.currentStep == OnboardingStep.currentLevel &&
        !state.hasUnsavedChanges;

    final VoidCallback handleStepBack =
        state.currentStep == OnboardingStep.currentLevel
        ? (state.isEditing
              ? skipSetup
              : (effectiveOrigin == OnboardingOrigin.auth
                    ? () {}
                    : confirmAndExitCreateFromCaller))
        : controller.goBack;

    return PopScope(
      canPop: allowAuthRootSystemBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || state.isSubmitting) {
          return;
        }
        if (state.currentStep == OnboardingStep.currentLevel) {
          if (state.isEditing) {
            skipSetup();
          } else if (effectiveOrigin == OnboardingOrigin.auth) {
            handleAuthStep1AndroidBack();
          } else {
            confirmAndExitCreateFromCaller();
          }
        } else {
          controller.goBack();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            body: SafeArea(
              child: state.currentStep == OnboardingStep.complete
                  ? _CompletionStep(
                      state: state,
                      onStart: () {
                        controller.resetForExit();
                        if (effectiveOrigin == OnboardingOrigin.roadmap) {
                          popOrGo(
                            context,
                            effectiveReturnTo ?? AppRoutes.learnRoadmap,
                            result: true,
                          );
                        } else {
                          context.go(AppRoutes.learnRoadmap);
                        }
                      },
                    )
                  : _OnboardingWizardShell(
                      header: _StepHeader(
                        step: wizardStepNumber,
                        isForward: _isForward,
                        reduceMotion: reduceMotion,
                        showBackButton: showStepBackButton,
                        onBack: handleStepBack,
                        backSemanticLabel: backSemanticLabel,
                        onSkip: skipSetup,
                        isEditing: state.isEditing,
                      ),
                      currentStep: state.currentStep,
                      isForward: _isForward,
                      reduceMotion: reduceMotion,
                      stepBody: buildWizardStepBody(),
                      action: buildWizardAction(),
                    ),
            ),
          ),
          AppLoadingOverlay(
            visible: state.isSubmitting,
            title: state.isEditing
                ? context.l10n.loadingOverlaySavingTitle
                : context.l10n.loadingOverlayOnboardingSavingTitle,
            subtitle: context.l10n.loadingOverlayUpdatingSubtitle,
          ),
        ],
      ),
    );
  }

  Future<void> _completeSetup(
    BuildContext context,
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
    var savedGoalInThisAttempt = false;
    int? savedGoalVersion;
    try {
      if (!state.goalSavedPendingPlacementSync) {
        final repository = ref.read(userProfileRepositoryProvider);
        if (repository is! AtomicLearningGoalProfileRepository) {
          throw UnsupportedError('Atomic learning goal is unavailable.');
        }
        final expectedVersion = state.isEditing
            ? state.expectedGoalVersion
            : (await repository.loadProfile()).learningGoalVersion;
        if (expectedVersion == null) {
          throw StateError('Missing learning goal version.');
        }
        final UserProfile savedProfile =
            await (repository as AtomicLearningGoalProfileRepository)
                .saveLearningGoal(
                  currentStudyLevelId: currentLevel.id,
                  targetJlptLevelId: level.id,
                  dailyStudyMinutes: dailyMinutes,
                  targetExamDate: targetExamDate,
                  certifiedJlptLevelId: state.hasJlptCertificate
                      ? state.certifiedJlptLevel?.id
                      : null,
                  expectedVersion: expectedVersion,
                );
        if (savedProfile.currentStudyLevelId != currentLevel.id ||
            savedProfile.targetJlptLevelId != level.id ||
            savedProfile.dailyStudyMinutes != dailyMinutes ||
            (state.examDateClearRequested &&
                savedProfile.targetExamDate != null) ||
            (targetExamDate != null &&
                !DateUtils.isSameDay(
                  savedProfile.targetExamDate,
                  targetExamDate,
                )) ||
            savedProfile.certifiedJlptLevelId !=
                (state.hasJlptCertificate
                    ? state.certifiedJlptLevel?.id
                    : null)) {
          throw StateError(
            'Profile save response does not match the learning goal.',
          );
        }
        savedGoalVersion = savedProfile.learningGoalVersion;
        savedGoalInThisAttempt = true;
        if (!context.mounted) return;
        await ref
            .read(learnerJourneyControllerProvider.notifier)
            .setCatalogPreferences(
              item: currentLevel,
              dailyStudyMinutes: dailyMinutes,
            );
        if (!context.mounted) return;
        ref.invalidate(userProfileControllerProvider);
        ref.invalidate(placementTestControllerProvider);
        ref.invalidate(standardRoadmapProvider);
      }
    } catch (_) {
      if (context.mounted) {
        controller.failSubmission();
      }
      return;
    }

    final effectiveOrigin = state.isEditing
        ? (widget.origin != OnboardingOrigin.auth
              ? widget.origin
              : (state.origin != OnboardingOrigin.auth
                    ? state.origin
                    : OnboardingOrigin.profileGoal))
        : (widget.origin != OnboardingOrigin.auth
              ? widget.origin
              : state.origin);
    final effectiveReturnTo = widget.returnTo ?? state.returnTo;

    if (state.isEditing) {
      controller.completeEdit();
      if (context.mounted) {
        ref
            .read(rikiToastServiceProvider.notifier)
            .success(title: context.l10n.toastJlptGoalUpdateSuccessTitle);
        final fallback = effectiveReturnTo ?? AppRoutes.profileJlptGoal;
        controller.resetForExit();
        popOrGo(context, fallback, result: true);
      }
      return;
    }

    void completeNonEditingFlow() {
      if (effectiveOrigin == OnboardingOrigin.profile ||
          effectiveOrigin == OnboardingOrigin.profileGoal) {
        controller.resetForExit();
        if (context.mounted) {
          ref
              .read(rikiToastServiceProvider.notifier)
              .success(title: context.l10n.toastJlptGoalUpdateSuccessTitle);
          popOrGo(context, AppRoutes.profileJlptGoal, result: true);
        }
        return;
      }
      controller.completeLocally();
    }

    if (!state.placementDecisionRecorded) {
      try {
        final placementRepository = ref.read(placementTestRepositoryProvider);
        final status = await placementRepository.loadStatus();
        if (!status.hasCompletedPlacementTest &&
            status.placementDecision != PlacementDecision.skipped &&
            status.placementDecision != PlacementDecision.completed) {
          if (placementRepository is! PlacementSkipRepository) {
            throw UnsupportedError('Placement skip is not supported.');
          }
          await (placementRepository as PlacementSkipRepository).skip();
        }
        if (!context.mounted) return;
        ref.invalidate(placementTestControllerProvider);
        controller.recordPlacementDecision();
        completeNonEditingFlow();
      } catch (_) {
        if (!context.mounted) return;
        if (savedGoalInThisAttempt && savedGoalVersion != null) {
          controller.markGoalSavedPendingPlacementSync(
            updatedGoalVersion: savedGoalVersion,
          );
        }
        controller.failPlacementSync();
      }
      return;
    }

    completeNonEditingFlow();
  }

  Future<void> _selectExamSession(
    BuildContext context,
    OnboardingController controller,
    DateTime? current,
  ) async {
    final result = await showModalBottomSheet<_ExamSelectionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ExamSessionSheet(current: current),
    );
    if (result == null) return;
    if (result.clear) {
      controller.clearTargetExamDate();
    } else if (result.date != null) {
      controller.selectTargetExamDate(result.date!);
    }
  }
}

class _StudyLevelsStep extends StatelessWidget {
  const _StudyLevelsStep({
    required this.state,
    required this.catalog,
    required this.showCurrent,
    required this.onSelectCurrent,
    required this.onSelectTarget,
    required this.onSetHasCertificate,
    required this.onSelectCertifiedLevel,
    required this.onRetry,
    required this.onTakePlacement,
  });

  final OnboardingState state;
  final AsyncValue<List<JlptLevelCatalogItem>> catalog;
  final bool showCurrent;
  final ValueChanged<JlptLevelCatalogItem> onSelectCurrent;
  final ValueChanged<JlptLevelCatalogItem> onSelectTarget;
  final ValueChanged<bool> onSetHasCertificate;
  final ValueChanged<JlptLevelCatalogItem> onSelectCertifiedLevel;
  final VoidCallback onRetry;
  final VoidCallback onTakePlacement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _OnboardingStepScrollBody(
      title: showCurrent
          ? l10n.onboardingCurrentLevelStepTitle
          : l10n.onboardingTargetLevelStepTitle,
      description: showCurrent
          ? l10n.onboardingCurrentLevelStepDescription
          : l10n.onboardingTargetLevelStepDescription,
      content: catalog.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.space5),
          child: Center(child: SakuraLoadingIndicator()),
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
                  if (showCurrent) ...[
                    ...levels
                        .where(
                          (item) =>
                              item.level != JlptLevel.n1 &&
                              item.level != JlptLevel.n2,
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
                    const SizedBox(height: 14),
                    _PlacementGuidanceSection(
                      state: state,
                      onTakePlacement: onTakePlacement,
                    ),
                  ],
                  if (!showCurrent) ...[
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
                    const SizedBox(height: AppSpacing.space2),
                    Material(
                      color: AppColors.cardWarmWhite,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          color: AppColors.borderSubtlePink,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                      child: CheckboxListTile(
                        key: const ValueKey<String>(
                          'onboarding_has_certificate',
                        ),
                        value: state.hasJlptCertificate,
                        onChanged: (value) =>
                            onSetHasCertificate(value ?? false),
                        secondary: const SakuraColorfulIcon(
                          type: SakuraColorfulIconType.certificateMedal,
                          size: 28,
                        ),
                        title: Text(
                          'Bạn đã có chứng chỉ JLPT chưa?',
                          style: AppTypography.cardTitle,
                        ),
                        subtitle: Text(
                          'Thông tin tự khai báo, chưa được xác minh.',
                          style: AppTypography.metadata.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                      ),
                    ),
                    if (state.hasJlptCertificate) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.space3,
                          bottom: AppSpacing.space2,
                        ),
                        child: Text(
                          'Chứng chỉ JLPT đã đạt',
                          style: AppTypography.sectionTitle,
                        ),
                      ),
                      ...levels
                          .where((item) => item.level != JlptLevel.n1)
                          .map(
                            (item) => _levelCard(
                              item: item,
                              selected: state.certifiedJlptLevel?.id == item.id,
                              keyPrefix: 'certified_level',
                              onPressed: () => onSelectCertifiedLevel(item),
                              l10n: l10n,
                            ),
                          ),
                    ],
                  ],

                ],
              ),
      ),
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

class _PlacementGuidanceSection extends StatelessWidget {
  const _PlacementGuidanceSection({
    required this.state,
    required this.onTakePlacement,
  });

  final OnboardingState state;
  final VoidCallback onTakePlacement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      key: const ValueKey<String>('onboarding_placement_guidance_section'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWarmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtlePink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SakuraColorfulIcon(
                  type: SakuraColorfulIconType.placementTest,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboardingPlacementTitle,
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.onboardingPlacementDescription,
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RikiSecondaryButton(
            key: const ValueKey<String>('onboarding_placement_test_button'),
            label: l10n.onboardingPlacementAction,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: state.isSubmitting ? null : onTakePlacement,
          ),
        ],
      ),
    );
  }
}

class _StudyTimeStep extends StatelessWidget {
  const _StudyTimeStep({
    required this.state,
    required this.onSelect,
    required this.onSelectCustomOption,
    required this.onCustom,
  });

  final OnboardingState state;
  final ValueChanged<DailyStudyTime> onSelect;
  final VoidCallback onSelectCustomOption;
  final ValueChanged<int?> onCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCustomSelected =
        state.isCustomTimeSelected ||
        (state.selectedStudyTime == null && state.dailyStudyMinutes != null);
    final customMinutesText =
        state.selectedStudyTime == null && state.dailyStudyMinutes != null
        ? '${l10n.studyMinutesPerDay(state.dailyStudyMinutes!)} · ${l10n.onboardingCustomTimeCardSubtitle}'
        : l10n.onboardingCustomTimeCardSubtitle;

    return _OnboardingStepScrollBody(
      title: l10n.onboardingDailyPlanStepTitle,
      description: l10n.onboardingStudyTimeDescription,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final studyTime in DailyStudyTime.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StudyDurationOptionCard(
                cardKey: ValueKey<String>('study_time_${studyTime.minutes}'),
                iconType: _studyIconType(studyTime),
                iconBackgroundColor: _studyIconBackground(studyTime),
                title: l10n.studyMinutesPerDay(studyTime.minutes),
                subtitle: _studyPaceDescription(studyTime, l10n),
                selected: state.selectedStudyTime == studyTime,
                onTap: () => onSelect(studyTime),
              ),
            ),
          _StudyDurationOptionCard(
            cardKey: const ValueKey<String>('study_time_custom'),
            iconType: SakuraColorfulIconType.studyCustomClock,
            iconBackgroundColor: const Color(0xFFFDEEF3),
            title: l10n.onboardingCustomTimeCardTitle,
            subtitle: customMinutesText,
            selected: isCustomSelected,
            onTap: onSelectCustomOption,
          ),
          if (isCustomSelected) ...[
            const SizedBox(height: 10),
            Container(
              key: const ValueKey<String>('onboarding_custom_minutes_panel'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardWarmWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtlePink),
              ),
              child: TextFormField(
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
                  hintText: '75',
                  suffixText: 'phút/ngày',
                  errorText:
                      state.customMinutesTouched &&
                          state.selectedStudyTime == null &&
                          state.dailyStudyMinutes == null
                      ? l10n.onboardingCustomMinutesError
                      : null,
                  prefixIcon: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.brandPrimary,
                  ),
                ),
                onChanged: (value) => onCustom(int.tryParse(value)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  SakuraColorfulIconType _studyIconType(DailyStudyTime studyTime) {
    return switch (studyTime) {
      DailyStudyTime.fifteen => SakuraColorfulIconType.studySprout,
      DailyStudyTime.thirty => SakuraColorfulIconType.studyBalance,
      DailyStudyTime.fortyFive => SakuraColorfulIconType.studyFlame,
      DailyStudyTime.sixty => SakuraColorfulIconType.studyBook,
      DailyStudyTime.ninety => SakuraColorfulIconType.studyLightning,
    };
  }

  Color _studyIconBackground(DailyStudyTime studyTime) {
    return switch (studyTime) {
      DailyStudyTime.fifteen => const Color(0xFFECF9F2),
      DailyStudyTime.thirty => const Color(0xFFEEF5FE),
      DailyStudyTime.fortyFive => const Color(0xFFFFF3EB),
      DailyStudyTime.sixty => const Color(0xFFF3EFFC),
      DailyStudyTime.ninety => const Color(0xFFFFF8E6),
    };
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
      DailyStudyTime.ninety => l10n.studyPaceFocused,
    };
  }
}

class _StudyDurationOptionCard extends StatelessWidget {
  const _StudyDurationOptionCard({
    required this.cardKey,
    required this.iconType,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Key cardKey;
  final SakuraColorfulIconType iconType;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);

    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.brandTint : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.brandPrimary : AppColors.borderSubtlePink,
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        key: cardKey,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: SakuraColorfulIcon(type: iconType, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
}

class _ExamPlanStep extends StatelessWidget {
  const _ExamPlanStep({required this.state, required this.onSelectExamDate});

  final OnboardingState state;
  final VoidCallback onSelectExamDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = state.targetExamDate;
    final session = JlptExamCalendar.fromStoredDate(date);
    final selectedMinutes = state.effectiveDailyMinutes;
    return _OnboardingStepScrollBody(
      title: l10n.onboardingExamPlanStepTitle,
      description: l10n.onboardingExamPlanStepDescription,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: date != null
                    ? AppColors.brandPrimary.withValues(alpha: 0.45)
                    : AppColors.borderSubtlePink,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              key: const ValueKey<String>('onboarding_exam_date_button'),
              onTap: onSelectExamDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              leading: const SakuraColorfulIcon(
                type: SakuraColorfulIconType.examDate,
                size: 28,
              ),
              title: Text(
                l10n.onboardingExamSessionCardTitle,
                style: AppTypography.cardTitle,
              ),
              subtitle: Text(
                date == null
                    ? l10n.notConfigured
                    : session == null
                    ? l10n.onboardingSavedExamDate(_formatExamDate(date))
                    : '${_sessionLabel(session.month, l10n)}, ${session.year} · ${l10n.onboardingEstimatedDate(_formatExamDate(date))}',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onboardingExamDisclaimer,
            style: AppTypography.metadata.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (state.submissionFailed) ...[
            const SizedBox(height: AppSpacing.space3),
            RikiErrorBanner(
              key: const ValueKey<String>('onboarding_save_error_banner'),
              title: l10n.toastActionFailedTitle,
              message: l10n.checkConnectionRetry,
            ),
          ],
          if (state.placementSkipFailed) ...[
            const SizedBox(height: AppSpacing.space3),
            RikiErrorBanner(
              key: const ValueKey<String>(
                'onboarding_placement_skip_error_banner',
              ),
              title: l10n.toastActionFailedTitle,
              message: l10n.onboardingPlacementSyncErrorMessage,
            ),
          ],
          const SizedBox(height: 22),
          SakuraLearningPlanPreview(
            currentLevelCode: state.selectedCurrentStudyLevel?.code,
            targetLevelCode: state.selectedJlptLevel?.code,
            dailyMinutes: selectedMinutes,
            hasCertificate: state.hasJlptCertificate,
            certifiedLevelCode: state.certifiedJlptLevel?.code,
            targetExamDate: date,
            examSession: session,
          ),
        ],
      ),
    );
  }
}

class _ExamSelectionResult {
  const _ExamSelectionResult({this.date, this.clear = false});
  final DateTime? date;
  final bool clear;
}

class _ExamSessionSheet extends StatefulWidget {
  const _ExamSessionSheet({required this.current});
  final DateTime? current;

  @override
  State<_ExamSessionSheet> createState() => _ExamSessionSheetState();
}

class _ExamSessionSheetState extends State<_ExamSessionSheet> {
  late final DateTime _openedAtUtc = DateTime.now().toUtc();
  late final List<int> _years = JlptExamCalendar.availableYears(_openedAtUtc);
  late int _year;
  int? _month;

  @override
  void initState() {
    super.initState();
    final saved = JlptExamCalendar.fromStoredDate(widget.current);
    _year = saved != null && _years.contains(saved.year)
        ? saved.year
        : _years.first;
    if (saved != null &&
        JlptExamCalendar.futureSessions(
          _year,
          _openedAtUtc,
        ).any((session) => session.month == saved.month)) {
      _month = saved.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessions = JlptExamCalendar.futureSessions(_year, _openedAtUtc);
    final selected = sessions.where((item) => item.month == _month).firstOrNull;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtlePink,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                l10n.onboardingExamSessionCardTitle,
                style: AppTypography.pageTitle,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                l10n.onboardingExamPlanStepDescription,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.space4),
              DropdownButtonFormField<int>(
                key: const ValueKey<String>('onboarding_exam_year'),
                initialValue: _year,
                decoration: InputDecoration(labelText: l10n.onboardingExamYear),
                items: [
                  for (final year in _years)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (year) {
                  if (year == null) return;
                  setState(() {
                    _year = year;
                    if (!JlptExamCalendar.futureSessions(
                      year,
                      _openedAtUtc,
                    ).any((session) => session.month == _month)) {
                      _month = null;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                l10n.onboardingExamSessionLabel,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              for (final session in sessions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: Material(
                    color: _month == session.month
                        ? AppColors.brandTint
                        : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: _month == session.month
                            ? AppColors.brandPrimary
                            : AppColors.borderSubtlePink,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: InkWell(
                      key: ValueKey<String>('exam_session_${session.month}'),
                      onTap: () => setState(() => _month = session.month),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.space3),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.brandPrimary,
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _sessionLabel(session.month, l10n),
                                    style: AppTypography.cardTitle,
                                  ),
                                  Text(
                                    l10n.onboardingEstimatedDate(
                                      _formatExamDate(session.date),
                                    ),
                                    style: AppTypography.metadata,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _month == session.month
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: _month == session.month
                                  ? AppColors.brandPrimary
                                  : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (selected != null)
                Text(
                  l10n.onboardingEstimatedDate(_formatExamDate(selected.date)),
                  style: AppTypography.bodySmall,
                ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                l10n.onboardingExamDisclaimer,
                style: AppTypography.metadata,
              ),
              const SizedBox(height: AppSpacing.space4),
              RikiPrimaryButton(
                key: const ValueKey<String>('onboarding_confirm_exam_session'),
                label: l10n.onboardingConfirmExamSession,
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        _ExamSelectionResult(date: selected.date),
                      ),
              ),
              TextButton(
                key: const ValueKey<String>('onboarding_clear_exam_session'),
                onPressed: () => Navigator.pop(
                  context,
                  widget.current == null
                      ? null
                      : const _ExamSelectionResult(clear: true),
                ),
                child: Text(
                  widget.current == null
                      ? l10n.onboardingNoExamSession
                      : l10n.onboardingClearExamSession,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _sessionLabel(int month, AppLocalizations l10n) => month == DateTime.july
    ? l10n.onboardingJulySession
    : l10n.onboardingDecemberSession;

String _formatExamDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

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
      DailyStudyTime.ninety => l10n.studyPaceFocused,
    };
  }
}

class _OnboardingWizardShell extends StatelessWidget {
  const _OnboardingWizardShell({
    required this.header,
    required this.currentStep,
    required this.isForward,
    required this.reduceMotion,
    required this.stepBody,
    required this.action,
  });

  final Widget header;
  final OnboardingStep currentStep;
  final bool isForward;
  final bool reduceMotion;
  final Widget stepBody;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffoldFrame(
      header: header,
      body: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[...previousChildren, ?currentChild],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey<OnboardingStep>(currentStep);
          if (reduceMotion) {
            return incoming
                ? child
                : IgnorePointer(child: ExcludeSemantics(child: child));
          }
          final sign = isForward ? 1.0 : -1.0;
          final slideAnimation = Tween<Offset>(
            begin: Offset((incoming ? 0.05 : -0.05) * sign, 0),
            end: Offset.zero,
          ).animate(animation);
          final transitioned = FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
          return incoming
              ? transitioned
              : IgnorePointer(child: ExcludeSemantics(child: transitioned));
        },
        child: KeyedSubtree(
          key: ValueKey<OnboardingStep>(currentStep),
          child: stepBody,
        ),
      ),
      action: action,
    );
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
    this.centered = false,
  });

  final Widget header;
  final String title;
  final String description;
  final Widget content;
  final Widget action;
  final Widget? beforeTitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return _OnboardingScaffoldFrame(
      header: header,
      body: _OnboardingStepScrollBody(
        beforeTitle: beforeTitle,
        centered: centered,
        title: title,
        description: description,
        content: content,
      ),
      action: action,
    );
  }
}

class _OnboardingScaffoldFrame extends StatelessWidget {
  const _OnboardingScaffoldFrame({
    required this.header,
    required this.body,
    required this.action,
  });

  final Widget header;
  final Widget body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360
            ? AppSpacing.screenHorizontalCompact
            : AppSpacing.screenHorizontal;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.space2,
                horizontalPadding,
                AppSpacing.space1,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: header,
                ),
              ),
            ),
            Expanded(child: body),
            DecoratedBox(
              decoration: const BoxDecoration(
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
                      children: [action],
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

class _OnboardingStepScrollBody extends StatelessWidget {
  const _OnboardingStepScrollBody({
    required this.title,
    required this.description,
    required this.content,
    this.beforeTitle,
    this.centered = false,
  });

  final Widget? beforeTitle;
  final bool centered;
  final String title;
  final String description;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 360
            ? AppSpacing.screenHorizontalCompact
            : AppSpacing.screenHorizontal;

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.space3,
            horizontalPadding,
            AppSpacing.space4,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?beforeTitle,
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
                  const SizedBox(height: AppSpacing.space4),
                  content,
                ],
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
    required this.isForward,
    required this.reduceMotion,
    this.showBackButton = true,
    required this.onBack,
    required this.backSemanticLabel,
    this.onSkip,
    this.isEditing = false,
  });

  final int step;
  final bool isForward;
  final bool reduceMotion;
  final bool showBackButton;
  final VoidCallback onBack;
  final String backSemanticLabel;
  final VoidCallback? onSkip;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          SizedBox.square(
            dimension: 48,
            child: IconButton(
              key: const ValueKey<String>('onboarding_back_button'),
              onPressed: onBack,
              tooltip: backSemanticLabel,
              icon: const Icon(Icons.arrow_back),
            ),
          )
        else
          const SizedBox(width: 48, height: 48),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey<int>(step);
                  if (reduceMotion) {
                    return incoming
                        ? child
                        : IgnorePointer(child: ExcludeSemantics(child: child));
                  }
                  final sign = isForward ? 1.0 : -1.0;
                  final slideAnimation = Tween<Offset>(
                    begin: Offset(0, (incoming ? 0.25 : -0.25) * sign),
                    end: Offset.zero,
                  ).animate(animation);
                  final widget = FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                  return incoming
                      ? widget
                      : IgnorePointer(child: ExcludeSemantics(child: widget));
                },
                child: Text(
                  context.l10n.onboardingStepOfFour(step),
                  key: ValueKey<int>(step),
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              SakuraAnimatedStepProgress(
                key: const ValueKey<String>('onboarding_step_progress'),
                currentStep: step,
                totalSteps: 4,
                semanticsLabel: context.l10n.onboardingProgressOfFour(step),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        TextButton(
          key: const ValueKey<String>('onboarding_skip_button'),
          onPressed: onSkip,
          child: Text(isEditing ? 'Hủy chỉnh sửa' : context.l10n.onboardingDefer),
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
