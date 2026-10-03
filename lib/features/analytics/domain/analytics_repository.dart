import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';

abstract interface class AnalyticsRepository {
  Future<LearnerAnalytics> loadLearnerAnalytics();
}
