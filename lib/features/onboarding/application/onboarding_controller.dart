import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

enum OnboardingStep { studyLevels, studyTime, complete }

enum DailyStudyTime {
  fifteen(minutes: 15, description: 'Nhẹ nhàng'),
  thirty(minutes: 30, description: 'Cân bằng'),
  fortyFive(minutes: 45, description: 'Tích cực'),
  sixty(minutes: 60, description: 'Chuyên sâu'),
  ninety(minutes: 90, description: 'Tăng tốc');

  const DailyStudyTime({required this.minutes, required this.description});

  final int minutes;
  final String description;

  String get label => '$minutes phút/ngày';
}

class OnboardingState {
  const OnboardingState({
    this.currentStep = OnboardingStep.studyLevels,
    this.selectedCurrentStudyLevel,
    this.selectedJlptLevel,
    this.selectedStudyTime,
    this.targetExamDate,
    this.dailyStudyMinutes,
    this.customMinutesTouched = false,
    this.placementSkipFailed = false,
    this.placementDecisionRecorded = false,
    this.isSubmitting = false,
    this.submissionFailed = false,
  });

  final OnboardingStep currentStep;
  final JlptLevelCatalogItem? selectedCurrentStudyLevel;
  final JlptLevelCatalogItem? selectedJlptLevel;
  final DailyStudyTime? selectedStudyTime;
  final DateTime? targetExamDate;
  final int? dailyStudyMinutes;
  final bool customMinutesTouched;
  final bool placementSkipFailed;
  final bool placementDecisionRecorded;
  final bool isSubmitting;
  final bool submissionFailed;

  bool get canContinue =>
      selectedCurrentStudyLevel != null && selectedJlptLevel != null;
  bool get canComplete =>
      canContinue && (selectedStudyTime != null || dailyStudyMinutes != null);

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    JlptLevelCatalogItem? selectedCurrentStudyLevel,
    JlptLevelCatalogItem? selectedJlptLevel,
    DailyStudyTime? selectedStudyTime,
    DateTime? targetExamDate,
    int? dailyStudyMinutes,
    bool clearSelectedStudyTime = false,
    bool clearDailyStudyMinutes = false,
    bool? customMinutesTouched,
    bool? placementSkipFailed,
    bool? placementDecisionRecorded,
    bool? isSubmitting,
    bool? submissionFailed,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedCurrentStudyLevel:
          selectedCurrentStudyLevel ?? this.selectedCurrentStudyLevel,
      selectedJlptLevel: selectedJlptLevel ?? this.selectedJlptLevel,
      selectedStudyTime: clearSelectedStudyTime
          ? null
          : selectedStudyTime ?? this.selectedStudyTime,
      targetExamDate: targetExamDate ?? this.targetExamDate,
      dailyStudyMinutes: clearDailyStudyMinutes
          ? null
          : dailyStudyMinutes ?? this.dailyStudyMinutes,
      customMinutesTouched: customMinutesTouched ?? this.customMinutesTouched,
      placementSkipFailed: placementSkipFailed ?? this.placementSkipFailed,
      placementDecisionRecorded:
          placementDecisionRecorded ?? this.placementDecisionRecorded,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionFailed: submissionFailed ?? this.submissionFailed,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void selectCurrentStudyLevel(JlptLevelCatalogItem level) {
    state = state.copyWith(
      selectedCurrentStudyLevel: level,
      placementSkipFailed: false,
    );
  }

  void selectJlptLevel(JlptLevelCatalogItem level) {
    state = state.copyWith(selectedJlptLevel: level);
  }

  void selectStudyTime(DailyStudyTime studyTime) {
    state = state.copyWith(
      selectedStudyTime: studyTime,
      dailyStudyMinutes: studyTime.minutes,
      customMinutesTouched: false,
    );
  }

  void selectCustomStudyMinutes(int? minutes) {
    state = state.copyWith(
      clearSelectedStudyTime: true,
      clearDailyStudyMinutes: minutes == null || minutes < 1 || minutes > 1440,
      dailyStudyMinutes: minutes != null && minutes >= 1 && minutes <= 1440
          ? minutes
          : null,
      customMinutesTouched: true,
    );
  }

  void selectTargetExamDate(DateTime date) {
    state = state.copyWith(targetExamDate: DateUtils.dateOnly(date));
  }

  void continueToStudyTime() {
    if (!state.canContinue) return;
    state = state.copyWith(currentStep: OnboardingStep.studyTime);
  }

  void recordPlacementDecision() {
    state = state.copyWith(
      placementDecisionRecorded: true,
      placementSkipFailed: false,
      isSubmitting: false,
    );
  }

  void placementSkipFailed() {
    state = state.copyWith(placementSkipFailed: true);
  }

  void hydrateFromProfile({
    required JlptLevelCatalogItem? currentStudyLevel,
    required JlptLevelCatalogItem? targetLevel,
    required int dailyMinutes,
    required DateTime? targetExamDate,
  }) {
    if (state.currentStep != OnboardingStep.studyLevels ||
        state.selectedCurrentStudyLevel != null ||
        state.selectedJlptLevel != null) {
      return;
    }
    final selectedMinutes = DailyStudyTime.values
        .where((choice) => choice.minutes == dailyMinutes)
        .firstOrNull;
    state = state.copyWith(
      currentStep: OnboardingStep.studyLevels,
      selectedCurrentStudyLevel: currentStudyLevel,
      selectedJlptLevel: targetLevel,
      selectedStudyTime: selectedMinutes,
      dailyStudyMinutes: dailyMinutes > 0 ? dailyMinutes : null,
      targetExamDate: targetExamDate,
    );
  }

  void completeLocally() {
    if (!state.canComplete) return;
    state = state.copyWith(
      currentStep: OnboardingStep.complete,
      isSubmitting: false,
      submissionFailed: false,
    );
  }

  void startSubmission() {
    if (!state.canComplete || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, submissionFailed: false);
  }

  void startPlacementSkip() {
    if (state.isSubmitting || !state.canContinue) return;
    state = state.copyWith(isSubmitting: true, placementSkipFailed: false);
  }

  void failSubmission() {
    state = state.copyWith(isSubmitting: false, submissionFailed: true);
  }

  void goBack() {
    switch (state.currentStep) {
      case OnboardingStep.studyLevels:
        return;
      case OnboardingStep.studyTime:
        state = state.copyWith(currentStep: OnboardingStep.studyLevels);
        return;
      case OnboardingStep.complete:
        state = state.copyWith(currentStep: OnboardingStep.studyTime);
        return;
    }
  }
}
