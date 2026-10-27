import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

enum OnboardingStep { jlptTarget, studyTime, complete }

enum DailyStudyTime {
  fifteen(minutes: 15, description: 'Nhẹ nhàng'),
  thirty(minutes: 30, description: 'Cân bằng'),
  fortyFive(minutes: 45, description: 'Tích cực'),
  sixty(minutes: 60, description: 'Chuyên sâu');

  const DailyStudyTime({required this.minutes, required this.description});

  final int minutes;
  final String description;

  String get label => '$minutes phút/ngày';
}

class OnboardingState {
  const OnboardingState({
    this.currentStep = OnboardingStep.jlptTarget,
    this.selectedJlptLevel,
    this.selectedStudyTime,
    this.isSubmitting = false,
    this.submissionFailed = false,
  });

  final OnboardingStep currentStep;
  final JlptLevelCatalogItem? selectedJlptLevel;
  final DailyStudyTime? selectedStudyTime;
  final bool isSubmitting;
  final bool submissionFailed;

  bool get canContinue => selectedJlptLevel != null;
  bool get canComplete =>
      selectedJlptLevel != null && selectedStudyTime != null;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    JlptLevelCatalogItem? selectedJlptLevel,
    DailyStudyTime? selectedStudyTime,
    bool? isSubmitting,
    bool? submissionFailed,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedJlptLevel: selectedJlptLevel ?? this.selectedJlptLevel,
      selectedStudyTime: selectedStudyTime ?? this.selectedStudyTime,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionFailed: submissionFailed ?? this.submissionFailed,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void selectJlptLevel(JlptLevelCatalogItem level) {
    state = state.copyWith(selectedJlptLevel: level);
  }

  void selectStudyTime(DailyStudyTime studyTime) {
    state = state.copyWith(selectedStudyTime: studyTime);
  }

  void continueToStudyTime() {
    if (!state.canContinue) return;
    state = state.copyWith(currentStep: OnboardingStep.studyTime);
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

  void failSubmission() {
    state = state.copyWith(isSubmitting: false, submissionFailed: true);
  }

  void goBack() {
    switch (state.currentStep) {
      case OnboardingStep.jlptTarget:
        return;
      case OnboardingStep.studyTime:
        state = state.copyWith(currentStep: OnboardingStep.jlptTarget);
        return;
      case OnboardingStep.complete:
        state = state.copyWith(currentStep: OnboardingStep.studyTime);
        return;
    }
  }
}
