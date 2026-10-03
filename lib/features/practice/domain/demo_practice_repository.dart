import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';

abstract interface class DemoPracticeRepository {
  Future<List<DemoReviewCard>> loadReviewQueue();

  Future<DemoMockTest> loadMockTest();

  Future<DemoAiGradingResult> gradeSubmission(String text);

  Future<List<DemoMentorPlan>> loadMentorPlans();

  Future<List<DemoMentorSlot>> loadMentorSlots();
}
