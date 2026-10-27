abstract final class LearningApiPaths {
  static const String lessons = '/api/LessonProgress/lessons';
  static const String generatePath = '/api/LearningPath/generate';
  static const String latestPath = '/api/LearningPath/latest';
  static const String activePath = '/api/LearningPath/active';
  static const String pathHistory = '/api/LearningPath/history';
  static const String previewPath = '/api/LearningPath/preview';

  static String confirmPreview(int pathId) =>
      '/api/LearningPath/previews/$pathId/confirm';
  static String cancelPreview(int pathId) =>
      '/api/LearningPath/previews/$pathId';

  static String lesson(int lessonId) => '$lessons/$lessonId';
  static String playback(int lessonId) =>
      '${lesson(lessonId)}/playback-position';
  static String complete(int lessonId) => '${lesson(lessonId)}/complete';
}
