import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';

final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => const FixtureLearningRepository(),
);

final learningControllerProvider =
    AsyncNotifierProvider<LearningController, LearningSnapshot>(
      LearningController.new,
    );

class LearningController extends AsyncNotifier<LearningSnapshot> {
  @override
  Future<LearningSnapshot> build() {
    return ref.watch(learningRepositoryProvider).loadLearningSnapshot();
  }

  Future<void> retry() async {
    state = const AsyncLoading<LearningSnapshot>();
    state = await AsyncValue.guard(
      ref.read(learningRepositoryProvider).loadLearningSnapshot,
    );
  }
}
