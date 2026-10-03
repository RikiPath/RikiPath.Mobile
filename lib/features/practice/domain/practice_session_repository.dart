import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';

abstract interface class PracticeSessionRepository {
  Future<DemoPracticeSessions?> load({
    required List<DemoReviewCard> reviewCards,
    required DemoMockTest mockTest,
  });

  Future<void> save(DemoPracticeSessions sessions);

  Future<void> reset();
}
