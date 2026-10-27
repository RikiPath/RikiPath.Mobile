abstract final class LearningApiPaths {
  static const String lessons = '/api/LessonProgress/lessons';

  static String lesson(int lessonId) => '$lessons/$lessonId';
  static String playback(int lessonId) =>
      '${lesson(lessonId)}/playback-position';
  static String complete(int lessonId) => '${lesson(lessonId)}/complete';
}
