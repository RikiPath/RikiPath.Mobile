abstract final class AppRoutes {
  static const String splash = '/splash';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String learn = '/learn';
  static const String learnRoadmapSegment = 'roadmap';
  static const String learnProgressSegment = 'progress';
  static const String vocabularySegment = 'vocabulary';
  static const String vocabularyDetailSegment = 'vocabulary/:entryKey';
  static const String kanjiSegment = 'kanji';
  static const String kanjiDetailSegment = 'kanji/:entryKey';
  static const String grammarSegment = 'grammar';
  static const String grammarDetailSegment = 'grammar/:entryKey';
  static const String lessonSegment = 'lesson/:lessonId';
  static const String learnRoadmap = '$learn/$learnRoadmapSegment';
  static const String learnProgress = '$learn/$learnProgressSegment';
  static const String vocabulary = '$learn/$vocabularySegment';
  static String vocabularyDetail(String entryKey) =>
      '$learn/vocabulary/${Uri.encodeComponent(entryKey)}';
  static const String kanji = '$learn/$kanjiSegment';
  static String kanjiDetail(String entryKey) =>
      '$learn/kanji/${Uri.encodeComponent(entryKey)}';
  static const String grammar = '$learn/$grammarSegment';
  static String grammarDetail(String entryKey) =>
      '$learn/grammar/${Uri.encodeComponent(entryKey)}';
  static String lesson(String lessonId) =>
      '$learn/lesson/${Uri.encodeComponent(lessonId)}';
  static const String practice = '/practice';
  static const String notebook = '/notebook';
  static const String notebookVocabularyDetailSegment = 'vocabulary/:entryKey';
  static String notebookVocabularyDetail(String entryKey) =>
      '$notebook/vocabulary/${Uri.encodeComponent(entryKey)}';
  static const String profile = '/profile';
  static const String profileAccountSegment = 'account';
  static const String profileEditSegment = 'edit';
  static const String profileJlptGoalSegment = 'jlpt-goal';
  static const String profileNotificationsSegment = 'notifications';
  static const String profileChangeEmailSegment = 'change-email';
  static const String profileChangePasswordSegment = 'change-password';
  static const String profileAccount = '$profile/$profileAccountSegment';
  static const String profileEdit = '$profile/$profileEditSegment';
  static const String profileJlptGoal = '$profile/$profileJlptGoalSegment';
  static const String profileNotifications =
      '$profile/$profileNotificationsSegment';
  static const String profileChangeEmail =
      '$profile/$profileChangeEmailSegment';
  static const String profileChangePassword =
      '$profile/$profileChangePasswordSegment';
}
