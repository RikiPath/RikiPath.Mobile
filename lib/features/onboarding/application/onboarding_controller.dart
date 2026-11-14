import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

enum OnboardingStep { currentLevel, targetLevel, studyTime, examPlan, complete }

enum DailyStudyTime {
  fifteen(minutes: 15, description: 'Nhẹ nhàng'),
  thirty(minutes: 30, description: 'Cân bằng'),
  fortyFive(minutes: 45, description: 'Tích cực'),
  sixty(minutes: 60, description: 'Chuyên sâu'),
  ninety(minutes: 90, description: 'Chuyên tâm');

  const DailyStudyTime({required this.minutes, required this.description});

  final int minutes;
  final String description;

  String get label => '$minutes phút/ngày';
}

class OnboardingState {
  const OnboardingState({
    this.currentStep = OnboardingStep.currentLevel,
    this.selectedCurrentStudyLevel,
    this.selectedJlptLevel,
    this.selectedStudyTime,
    this.targetExamDate,
    this.examDateClearRequested = false,
    this.dailyStudyMinutes,
    this.isCustomTimeSelected = false,
    this.customMinutesTouched = false,
    this.placementSkipFailed = false,
    this.placementDecisionRecorded = false,
    this.goalSavedPendingPlacementSync = false,
    this.isSubmitting = false,
    this.submissionFailed = false,
    this.isEditing = false,
    this.origin = OnboardingOrigin.auth,
    this.returnTo,
    this.hasJlptCertificate = false,
    this.certifiedJlptLevel,
    this.expectedGoalVersion,
    this.initialCurrentStudyLevelId,
    this.initialJlptLevelId,
    this.initialDailyStudyMinutes,
    this.initialTargetExamDate,
    this.initialCertifiedJlptLevelId,
  });

  final OnboardingStep currentStep;
  final JlptLevelCatalogItem? selectedCurrentStudyLevel;
  final JlptLevelCatalogItem? selectedJlptLevel;
  final DailyStudyTime? selectedStudyTime;
  final DateTime? targetExamDate;
  final bool examDateClearRequested;
  final int? dailyStudyMinutes;
  final bool isCustomTimeSelected;
  final bool customMinutesTouched;
  final bool placementSkipFailed;
  final bool placementDecisionRecorded;
  final bool goalSavedPendingPlacementSync;
  final bool isSubmitting;
  final bool submissionFailed;
  final bool isEditing;
  final OnboardingOrigin origin;
  final String? returnTo;
  final bool hasJlptCertificate;
  final JlptLevelCatalogItem? certifiedJlptLevel;
  final int? expectedGoalVersion;
  final int? initialCurrentStudyLevelId;
  final int? initialJlptLevelId;
  final int? initialDailyStudyMinutes;
  final DateTime? initialTargetExamDate;
  final int? initialCertifiedJlptLevelId;

  int? get effectiveDailyMinutes =>
      selectedStudyTime?.minutes ?? dailyStudyMinutes;

  bool get canContinueCurrentLevel =>
      selectedCurrentStudyLevel != null &&
      selectedCurrentStudyLevel!.level != JlptLevel.n2 &&
      selectedCurrentStudyLevel!.level != JlptLevel.n1;
  bool get canContinueTargetLevel =>
      canContinueCurrentLevel &&
      selectedJlptLevel != null &&
      (!hasJlptCertificate || certifiedJlptLevel != null);
  bool get canContinue => canContinueTargetLevel;
  bool get canComplete =>
      canContinue && (selectedStudyTime != null || dailyStudyMinutes != null);

  bool get hasUnsavedChanges {
    if (!isEditing) {
      return selectedCurrentStudyLevel != null ||
          selectedJlptLevel != null ||
          effectiveDailyMinutes != null ||
          targetExamDate != null ||
          hasJlptCertificate ||
          certifiedJlptLevel != null;
    }
    final currentExam = targetExamDate == null
        ? null
        : DateUtils.dateOnly(targetExamDate!);
    final initialExam = initialTargetExamDate == null
        ? null
        : DateUtils.dateOnly(initialTargetExamDate!);
    final currentCertifiedId =
        hasJlptCertificate ? certifiedJlptLevel?.id : null;
    return selectedCurrentStudyLevel?.id != initialCurrentStudyLevelId ||
        selectedJlptLevel?.id != initialJlptLevelId ||
        effectiveDailyMinutes != initialDailyStudyMinutes ||
        currentExam != initialExam ||
        currentCertifiedId != initialCertifiedJlptLevelId;
  }

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    JlptLevelCatalogItem? selectedCurrentStudyLevel,
    JlptLevelCatalogItem? selectedJlptLevel,
    DailyStudyTime? selectedStudyTime,
    DateTime? targetExamDate,
    bool clearTargetExamDateValue = false,
    bool? examDateClearRequested,
    int? dailyStudyMinutes,
    bool clearSelectedStudyTime = false,
    bool clearDailyStudyMinutes = false,
    bool? isCustomTimeSelected,
    bool? customMinutesTouched,
    bool? placementSkipFailed,
    bool? placementDecisionRecorded,
    bool? goalSavedPendingPlacementSync,
    bool? isSubmitting,
    bool? submissionFailed,
    bool? isEditing,
    OnboardingOrigin? origin,
    String? returnTo,
    bool clearReturnTo = false,
    bool? hasJlptCertificate,
    JlptLevelCatalogItem? certifiedJlptLevel,
    bool clearCertifiedJlptLevel = false,
    int? expectedGoalVersion,
    int? initialCurrentStudyLevelId,
    int? initialJlptLevelId,
    int? initialDailyStudyMinutes,
    DateTime? initialTargetExamDate,
    int? initialCertifiedJlptLevelId,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedCurrentStudyLevel:
          selectedCurrentStudyLevel ?? this.selectedCurrentStudyLevel,
      selectedJlptLevel: selectedJlptLevel ?? this.selectedJlptLevel,
      selectedStudyTime: clearSelectedStudyTime
          ? null
          : selectedStudyTime ?? this.selectedStudyTime,
      targetExamDate: clearTargetExamDateValue
          ? null
          : targetExamDate ?? this.targetExamDate,
      examDateClearRequested:
          examDateClearRequested ?? this.examDateClearRequested,
      dailyStudyMinutes: clearDailyStudyMinutes
          ? null
          : dailyStudyMinutes ?? this.dailyStudyMinutes,
      isCustomTimeSelected: isCustomTimeSelected ?? this.isCustomTimeSelected,
      customMinutesTouched: customMinutesTouched ?? this.customMinutesTouched,
      placementSkipFailed: placementSkipFailed ?? this.placementSkipFailed,
      placementDecisionRecorded:
          placementDecisionRecorded ?? this.placementDecisionRecorded,
      goalSavedPendingPlacementSync:
          goalSavedPendingPlacementSync ?? this.goalSavedPendingPlacementSync,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionFailed: submissionFailed ?? this.submissionFailed,
      isEditing: isEditing ?? this.isEditing,
      origin: origin ?? this.origin,
      returnTo: clearReturnTo ? null : returnTo ?? this.returnTo,
      hasJlptCertificate: hasJlptCertificate ?? this.hasJlptCertificate,
      certifiedJlptLevel: clearCertifiedJlptLevel
          ? null
          : certifiedJlptLevel ?? this.certifiedJlptLevel,
      expectedGoalVersion: expectedGoalVersion ?? this.expectedGoalVersion,
      initialCurrentStudyLevelId:
          initialCurrentStudyLevelId ?? this.initialCurrentStudyLevelId,
      initialJlptLevelId: initialJlptLevelId ?? this.initialJlptLevelId,
      initialDailyStudyMinutes:
          initialDailyStudyMinutes ?? this.initialDailyStudyMinutes,
      initialTargetExamDate:
          initialTargetExamDate ?? this.initialTargetExamDate,
      initialCertifiedJlptLevelId:
          initialCertifiedJlptLevelId ?? this.initialCertifiedJlptLevelId,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final session = ref.watch(authSessionControllerProvider);
    final initialUserId = session.currentUserId;
    void handleIdentityChange() {
      if (session.currentUserId != initialUserId) {
        ref.invalidateSelf();
      }
    }

    session.addListener(handleIdentityChange);
    ref.onDispose(() => session.removeListener(handleIdentityChange));
    return const OnboardingState();
  }

  void _applySelection(OnboardingState updated) {
    state = updated.copyWith(
      placementSkipFailed: false,
      submissionFailed: false,
      goalSavedPendingPlacementSync: false,
    );
  }

  void selectCurrentStudyLevel(JlptLevelCatalogItem level) {
    _applySelection(state.copyWith(selectedCurrentStudyLevel: level));
  }

  void selectJlptLevel(JlptLevelCatalogItem level) {
    _applySelection(state.copyWith(selectedJlptLevel: level));
  }

  void setHasJlptCertificate(bool value) {
    _applySelection(
      state.copyWith(
        hasJlptCertificate: value,
        clearCertifiedJlptLevel: !value,
      ),
    );
  }

  void selectCertifiedJlptLevel(JlptLevelCatalogItem level) {
    _applySelection(
      state.copyWith(hasJlptCertificate: true, certifiedJlptLevel: level),
    );
  }

  void startCreateFromProfile({
    OnboardingOrigin origin = OnboardingOrigin.profile,
    String? returnTo,
  }) {
    state = OnboardingState(
      origin: origin,
      returnTo: returnTo,
    );
  }

  void syncRouteContext({
    required OnboardingOrigin origin,
    String? returnTo,
  }) {
    if (origin == OnboardingOrigin.auth) {
      return;
    }
    if (!state.isEditing && state.currentStep == OnboardingStep.complete) {
      state = OnboardingState(
        origin: origin,
        returnTo: returnTo,
      );
      return;
    }
    if (state.origin != origin || state.returnTo != returnTo) {
      state = state.copyWith(
        origin: origin,
        returnTo: returnTo,
        clearReturnTo: returnTo == null,
      );
    }
  }

  void startEditFromProfile({
    required JlptLevelCatalogItem currentStudyLevel,
    required JlptLevelCatalogItem targetLevel,
    required int dailyMinutes,
    required DateTime? targetExamDate,
    required JlptLevelCatalogItem? certifiedJlptLevel,
    required int goalVersion,
    OnboardingOrigin origin = OnboardingOrigin.profileGoal,
    String? returnTo,
  }) {
    final preset = DailyStudyTime.values
        .where((choice) => choice.minutes == dailyMinutes)
        .firstOrNull;
    final supportedCurrent =
        currentStudyLevel.level == JlptLevel.n2 ||
            currentStudyLevel.level == JlptLevel.n1
        ? null
        : currentStudyLevel;
    state = OnboardingState(
      isEditing: true,
      origin: origin,
      returnTo: returnTo,
      selectedCurrentStudyLevel: supportedCurrent,
      selectedJlptLevel: targetLevel,
      selectedStudyTime: preset,
      dailyStudyMinutes: dailyMinutes,
      isCustomTimeSelected: dailyMinutes > 0 && preset == null,
      targetExamDate: targetExamDate,
      hasJlptCertificate: certifiedJlptLevel != null,
      certifiedJlptLevel: certifiedJlptLevel,
      expectedGoalVersion: goalVersion,
      placementDecisionRecorded: true,
      initialCurrentStudyLevelId: supportedCurrent?.id,
      initialJlptLevelId: targetLevel.id,
      initialDailyStudyMinutes: dailyMinutes,
      initialTargetExamDate: targetExamDate,
      initialCertifiedJlptLevelId: certifiedJlptLevel?.id,
    );
  }

  void selectStudyTime(DailyStudyTime studyTime) {
    _applySelection(
      state.copyWith(
        selectedStudyTime: studyTime,
        dailyStudyMinutes: studyTime.minutes,
        isCustomTimeSelected: false,
        customMinutesTouched: false,
      ),
    );
  }

  void selectCustomTimeOption() {
    final hadPreset = state.selectedStudyTime != null;
    _applySelection(
      state.copyWith(
        clearSelectedStudyTime: true,
        clearDailyStudyMinutes: hadPreset,
        isCustomTimeSelected: true,
        customMinutesTouched: false,
      ),
    );
  }

  void selectCustomStudyMinutes(int? minutes) {
    _applySelection(
      state.copyWith(
        clearSelectedStudyTime: true,
        clearDailyStudyMinutes: minutes == null || minutes < 1 || minutes > 1440,
        dailyStudyMinutes: minutes != null && minutes >= 1 && minutes <= 1440
            ? minutes
            : null,
        isCustomTimeSelected: true,
        customMinutesTouched: true,
      ),
    );
  }

  void selectTargetExamDate(DateTime date) {
    _applySelection(
      state.copyWith(
        targetExamDate: DateUtils.dateOnly(date),
        examDateClearRequested: false,
      ),
    );
  }

  void clearTargetExamDate() {
    _applySelection(
      state.copyWith(
        clearTargetExamDateValue: true,
        examDateClearRequested: true,
      ),
    );
  }

  void continueToTargetLevel() {
    if (!state.canContinueCurrentLevel) return;
    state = state.copyWith(currentStep: OnboardingStep.targetLevel);
  }

  void continueToStudyTime() {
    if (!state.canContinue) return;
    state = state.copyWith(currentStep: OnboardingStep.studyTime);
  }

  void continueToExamPlan() {
    if (!state.canComplete) return;
    state = state.copyWith(currentStep: OnboardingStep.examPlan);
  }

  void recordPlacementDecision() {
    state = state.copyWith(
      placementDecisionRecorded: true,
      placementSkipFailed: false,
      goalSavedPendingPlacementSync: false,
      isSubmitting: false,
    );
  }

  void markGoalSavedPendingPlacementSync({required int updatedGoalVersion}) {
    state = state.copyWith(
      expectedGoalVersion: updatedGoalVersion,
      goalSavedPendingPlacementSync: true,
    );
  }

  void failPlacementSync() {
    state = state.copyWith(
      isSubmitting: false,
      submissionFailed: false,
      placementSkipFailed: true,
      goalSavedPendingPlacementSync: true,
    );
  }

  void hydrateFromProfile({
    required JlptLevelCatalogItem? currentStudyLevel,
    required JlptLevelCatalogItem? targetLevel,
    required int dailyMinutes,
    required DateTime? targetExamDate,
  }) {
    if (state.currentStep != OnboardingStep.currentLevel ||
        state.selectedCurrentStudyLevel != null ||
        state.selectedJlptLevel != null) {
      return;
    }
    final selectedMinutes = DailyStudyTime.values
        .where((choice) => choice.minutes == dailyMinutes)
        .firstOrNull;
    state = state.copyWith(
      currentStep: OnboardingStep.currentLevel,
      selectedCurrentStudyLevel: currentStudyLevel,
      selectedJlptLevel: targetLevel,
      selectedStudyTime: selectedMinutes,
      dailyStudyMinutes: dailyMinutes > 0 ? dailyMinutes : null,
      isCustomTimeSelected: dailyMinutes > 0 && selectedMinutes == null,
      targetExamDate: targetExamDate,
    );
  }

  void completeLocally() {
    if (!state.canComplete) return;
    state = state.copyWith(
      currentStep: OnboardingStep.complete,
      isSubmitting: false,
      submissionFailed: false,
      placementSkipFailed: false,
      goalSavedPendingPlacementSync: false,
    );
  }

  void completeEdit() {
    state = state.copyWith(
      isSubmitting: false,
      submissionFailed: false,
      placementSkipFailed: false,
      goalSavedPendingPlacementSync: false,
    );
  }

  void resetForExit() {
    state = const OnboardingState();
  }

  void startSubmission() {
    if (!state.canComplete || state.isSubmitting) return;
    state = state.copyWith(
      isSubmitting: true,
      submissionFailed: false,
      placementSkipFailed: false,
    );
  }

  void failSubmission() {
    state = state.copyWith(isSubmitting: false, submissionFailed: true);
  }

  void goBack() {
    switch (state.currentStep) {
      case OnboardingStep.currentLevel:
        return;
      case OnboardingStep.targetLevel:
        state = state.copyWith(
          currentStep: OnboardingStep.currentLevel,
          submissionFailed: false,
          placementSkipFailed: false,
        );
        return;
      case OnboardingStep.studyTime:
        state = state.copyWith(
          currentStep: OnboardingStep.targetLevel,
          submissionFailed: false,
          placementSkipFailed: false,
        );
        return;
      case OnboardingStep.examPlan:
        state = state.copyWith(
          currentStep: OnboardingStep.studyTime,
          submissionFailed: false,
          placementSkipFailed: false,
        );
        return;
      case OnboardingStep.complete:
        state = state.copyWith(
          currentStep: OnboardingStep.examPlan,
          submissionFailed: false,
          placementSkipFailed: false,
        );
        return;
    }
  }
}
