import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';

abstract interface class LearningRepository {
  Future<LearningSnapshot> loadLearningSnapshot();
}
