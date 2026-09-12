abstract final class AppRoutes {
  static const String splash = '/splash';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String learn = '/learn';
  static const String learnRoadmapSegment = 'roadmap';
  static const String learnProgressSegment = 'progress';
  static const String lessonSegment = 'lesson/:lessonId';
  static const String learnRoadmap = '$learn/$learnRoadmapSegment';
  static const String learnProgress = '$learn/$learnProgressSegment';
  static String lesson(String lessonId) =>
      '$learn/lesson/${Uri.encodeComponent(lessonId)}';
  static const String practice = '/practice';
  static const String notebook = '/notebook';
  static const String profile = '/profile';
}
