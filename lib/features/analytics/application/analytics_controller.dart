import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/analytics/data/api_analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => ApiAnalyticsRepository(ref.watch(apiClientProvider)),
);

final learnerAnalyticsControllerProvider =
    AsyncNotifierProvider<LearnerAnalyticsController, LearnerAnalytics>(
      LearnerAnalyticsController.new,
      retry: (_, _) => null,
    );

class LearnerAnalyticsController extends AsyncNotifier<LearnerAnalytics> {
  @override
  Future<LearnerAnalytics> build() {
    return ref.watch(analyticsRepositoryProvider).loadLearnerAnalytics();
  }

  Future<void> retry() async {
    state = const AsyncLoading<LearnerAnalytics>();
    state = await AsyncValue.guard(build);
  }
}
