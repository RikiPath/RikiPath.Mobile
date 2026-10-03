import 'package:rikipath_mobile/features/learning/domain/learner_journey.dart';

abstract interface class LearnerJourneyRepository {
  Future<LearnerJourneyState> load();

  Future<void> save(LearnerJourneyState state);

  Future<void> reset();
}
