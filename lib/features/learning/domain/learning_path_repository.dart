import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';

abstract interface class LearningPathRepository {
  Future<RecommendedLearningPath?> loadLatest();

  Future<RecommendedLearningPath> generate();
}

abstract interface class LearningPathVersionRepository {
  Future<RecommendedLearningPath?> loadActive();

  Future<List<RecommendedLearningPath>> loadHistory();

  Future<RecommendedLearningPath> preview({
    required int startingJlptLevelId,
    int? targetJlptLevelId,
  });

  Future<RecommendedLearningPath> confirmPreview(int pathId);

  Future<RecommendedLearningPath> cancelPreview(int pathId);
}
