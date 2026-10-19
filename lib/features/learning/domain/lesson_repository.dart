import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

abstract interface class LessonRepository {
  Future<Lesson> loadLesson(String routeId);

  Future<LessonProgress> updatePlaybackPosition({
    required String routeId,
    required int positionSeconds,
    required int durationSeconds,
  });

  Future<LessonProgress> completeLesson({required String routeId});
}
