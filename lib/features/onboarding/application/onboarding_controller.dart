import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

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
  });

  final OnboardingStep currentStep;
  final JlptLevel? selectedJlptLevel;
  final DailyStudyTime? selectedStudyTime;

  bool get canContinue => selectedJlptLevel != null;
  bool get canComplete =>
      selectedJlptLevel != null && selectedStudyTime != null;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    JlptLevel? selectedJlptLevel,
    DailyStudyTime? selectedStudyTime,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedJlptLevel: selectedJlptLevel ?? this.selectedJlptLevel,
      selectedStudyTime: selectedStudyTime ?? this.selectedStudyTime,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void selectJlptLevel(JlptLevel level) {
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
    state = state.copyWith(currentStep: OnboardingStep.complete);
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
