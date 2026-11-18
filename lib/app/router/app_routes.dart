enum OnboardingOrigin {
  auth('auth'),
  profile('profile'),
  profileGoal('profile_goal'),
  roadmap('roadmap');

  const OnboardingOrigin(this.queryValue);

  final String queryValue;

  static OnboardingOrigin fromQuery(String? value) {
    for (final origin in OnboardingOrigin.values) {
      if (origin.queryValue == value) {
        return origin;
      }
    }
    return OnboardingOrigin.auth;
  }
}

abstract final class AppRoutes {
  static const String splash = '/splash';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String mentorRegister = '$register?intent=mentor';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String unsupportedRole = '/auth/unsupported-role';
  static const String learnerStartup = '/learner-startup';
  static const String onboarding = '/onboarding';

  static String onboardingWithOrigin(
    OnboardingOrigin origin, {
    String? returnTo,
  }) {
    final queryParameters = <String, String>{
      'from': origin.queryValue,
      if (returnTo != null && returnTo.isNotEmpty) 'returnTo': returnTo,
    };
    return Uri(
      path: onboarding,
      queryParameters: queryParameters,
    ).toString();
  }

  static bool isShellBranchRoute(String uriOrPath) {
    final path = Uri.tryParse(uriOrPath)?.path ?? uriOrPath;
    if (path == mentor ||
        path == mentorCalendar ||
        path == mentorCohorts ||
        path.startsWith('$mentorCohorts/') ||
        path == mentorAvailability ||
        path == mentorProfile ||
        path.startsWith('$mentorProfile/')) {
      return true;
    }
    if (path == home ||
        path == learn ||
        path.startsWith('$learn/') ||
        path == practice ||
        path == mockTestLibrary ||
        path == writing ||
        path.startsWith('$writing/') ||
        path == notebook ||
        path.startsWith('$notebook/') ||
        path == profile ||
        path.startsWith('$profile/')) {
      return true;
    }
    return false;
  }

  static bool isLearnerTabRoot(String uriOrPath) {
    final path = Uri.tryParse(uriOrPath)?.path ?? uriOrPath;
    return path == home ||
        path == learn ||
        path == practice ||
        path == notebook ||
        path == profile;
  }

  static bool isMentorTabRoot(String uriOrPath) {
    final path = Uri.tryParse(uriOrPath)?.path ?? uriOrPath;
    return path == mentor ||
        path == mentorCalendar ||
        path == mentorCohorts ||
        path == mentorAvailability ||
        path == mentorProfile;
  }

  static const String placementTest = '/placement-test';

  static const String meeting = '/meeting';
  static const String meetingJoinSegment = 'join';
  static const String meetingJoin = '$meeting/$meetingJoinSegment';
  static const String meetingRoomSegment = 'room/:roomId';

  static String meetingRoom(String roomId) =>
      '$meeting/room/${Uri.encodeComponent(roomId)}';

  static const String mentor = '/mentor';
  static const String mentorApplication = '/mentor-application';
  static const String mentorAvailabilitySegment = 'availability';
  static const String mentorAvailability = '$mentor/$mentorAvailabilitySegment';
  static const String mentorProfileSegment = 'profile';
  static const String mentorProfile = '$mentor/$mentorProfileSegment';
  static const String mentorProfileEditSegment = 'edit';
  static const String mentorProfileEdit =
      '$mentorProfile/$mentorProfileEditSegment';
  static const String mentorSettingsSegment = 'settings';
  static const String mentorSettings = '$mentorProfile/$mentorSettingsSegment';
  static const String mentorNotificationsSegment = 'notifications';
  static const String mentorNotifications =
      '$mentorProfile/$mentorNotificationsSegment';
  static const String mentorAttendanceKpiSegment = 'attendance-kpi';
  static const String mentorAttendanceKpi =
      '$mentor/$mentorAttendanceKpiSegment';
  static const String mentorCalendarSegment = 'calendar';
  static const String mentorCalendar = '$mentor/$mentorCalendarSegment';
  static const String mentorChangePasswordSegment = 'change-password';
  static const String mentorChangePassword =
      '$mentor/$mentorChangePasswordSegment';
  static const String mentorChangeEmailSegment = 'change-email';
  static const String mentorChangeEmail = '$mentor/$mentorChangeEmailSegment';
  static const String mentorVerifyEmailSegment = 'verify-email';
  static const String mentorVerifyEmail = '$mentor/$mentorVerifyEmailSegment';
  static const String mentorCohortsSegment = 'cohorts';
  static const String mentorCohortDetailSegment = ':cohortId';
  static const String mentorCohorts = '$mentor/$mentorCohortsSegment';

  static String mentorCohortDetail(int cohortId) {
    if (cohortId <= 0) {
      throw ArgumentError.value(cohortId, 'cohortId', 'Must be positive');
    }
    return '$mentorCohorts/$cohortId';
  }

  static const String learnerMentors = '/mentors';
  static const String learnerMentorPublicProfileSegment = ':mentorId';
  static String learnerMentorPublicProfile(int mentorId) {
    if (mentorId <= 0) {
      throw ArgumentError.value(mentorId, 'mentorId', 'Must be positive');
    }
    return '$learnerMentors/$mentorId';
  }

  static const String learnerCohorts = '/cohorts';
  static const String learnerMyCourses = '/my-courses';
  static const String learnerCohortDetailSegment = ':courseId';
  static String learnerCohortDetail(int courseId) {
    if (courseId <= 0) {
      throw ArgumentError.value(courseId, 'courseId', 'Must be positive');
    }
    return '$learnerMyCourses/$courseId';
  }

  static const String home = '/home';
  static const String calendar = '/calendar';
  static String calendarOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final dateParam =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return '$calendar?date=$dateParam';
  }

  static const String notifications = '/notifications';
  static const String learn = '/learn';
  static const String learnRoadmapSegment = 'roadmap';
  static const String lessonCatalogSegment = 'lessons';
  static const String learnProgressSegment = 'progress';
  static const String sharedBankSegment = 'library';
  static const String vocabularySegment = 'vocabulary';
  static const String vocabularyDetailSegment = 'vocabulary/:entryKey';
  static const String kanjiSegment = 'kanji';
  static const String kanjiDetailSegment = 'kanji/:entryKey';
  static const String grammarSegment = 'grammar';
  static const String grammarDetailSegment = 'grammar/:entryKey';
  static const String lessonSegment = 'lesson/:lessonId';
  static const String learnRoadmap = '$learn/$learnRoadmapSegment';
  static const String lessonCatalog = '$learn/$lessonCatalogSegment';
  static const String learnProgress = '$learn/$learnProgressSegment';
  static const String sharedBank = '$learn/$sharedBankSegment';
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
  static const String reviewSegment = 'review';
  static const String writingSegment = 'writing';
  static const String essayWritingSegment = 'essay';
  static const String writingHiraganaSegment = 'hiragana';
  static const String writingKatakanaSegment = 'katakana';
  static const String writingKanjiSegment = 'kanji';
  static const String writingHiraganaDetailSegment = 'hiragana/:characterId';
  static const String writingKatakanaDetailSegment = 'katakana/:characterId';
  static const String writingKanjiDetailSegment = 'kanji/:characterId';
  static const String speechSegment = 'speech';
  static const String textScanSegment = 'scan-text';
  static const String mockTestSegment = 'mock/:testId';
  static const String mockTestLibrarySegment = 'mock-library';
  static const String mockResultSegment = 'result';
  static const String mockDetailedReviewSegment = 'review';
  static const String dailyReview = '$practice/$reviewSegment';
  static const String writing = '$practice/$writingSegment';
  static const String essayWriting = '$practice/$essayWritingSegment';
  static const String writingHiragana = '$writing/$writingHiraganaSegment';
  static const String writingKatakana = '$writing/$writingKatakanaSegment';
  static const String writingKanji = '$writing/$writingKanjiSegment';
  static String writingHiraganaDetail(int characterId) =>
      '$writingHiragana/${_positiveId(characterId, "characterId")}';
  static String writingKatakanaDetail(int characterId) =>
      '$writingKatakana/${_positiveId(characterId, "characterId")}';
  static String writingKanjiDetail(int characterId) =>
      '$writingKanji/${_positiveId(characterId, "characterId")}';
  static const String speechPractice = '$practice/$speechSegment';
  static const String textScan = '$practice/$textScanSegment';
  static const String mockTestLibrary = '$practice/$mockTestLibrarySegment';
  static String mockTest(String testId) =>
      '$practice/mock/${Uri.encodeComponent(testId)}';
  static String mockTestResult(String testId) => '${mockTest(testId)}/result';
  static String mockTestDetailedReview(String testId) =>
      '${mockTestResult(testId)}/review';
  static const String analytics = '/analytics';
  static const String notebook = '/notebook';
  static const String notebookCollectionSegment = 'collection/:collectionKey';
  static const String notebookVocabularyDetailSegment = 'vocabulary/:entryKey';
  static const String notebookEntryDetailSegment = 'item/:entryKey';
  static String notebookCollection(String collectionKey) =>
      '$notebook/collection/${Uri.encodeComponent(collectionKey)}';
  static String notebookVocabularyDetail(String entryKey) =>
      '$notebook/vocabulary/${Uri.encodeComponent(entryKey)}';
  static String notebookEntryDetail(String entryKey) =>
      '$notebook/item/${Uri.encodeComponent(entryKey)}';
  static const String profile = '/profile';
  static const String profileAccountSegment = 'account';
  static const String profileEditSegment = 'edit';
  static const String profileJlptGoalSegment = 'jlpt-goal';
  static const String profileNotificationsSegment = 'notifications';
  static const String profileChangeEmailSegment = 'change-email';
  static const String profileChangePasswordSegment = 'change-password';
  static const String profileVerifyEmailSegment = 'verify-email';
  static const String profileAccount = '$profile/$profileAccountSegment';
  static const String profileEdit = '$profile/$profileEditSegment';
  static const String profileJlptGoal = '$profile/$profileJlptGoalSegment';
  static const String profileNotifications =
      '$profile/$profileNotificationsSegment';
  static const String profileChangeEmail =
      '$profile/$profileChangeEmailSegment';
  static const String profileChangePassword =
      '$profile/$profileChangePasswordSegment';
  static const String profileVerifyEmail =
      '$profile/$profileVerifyEmailSegment';

  static int _positiveId(int value, String name) {
    if (value <= 0) {
      throw ArgumentError.value(value, name, 'Must be positive');
    }
    return value;
  }
}
