abstract final class AppRoutes {
  static const String splash = '/splash';

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String unsupportedRole = '/auth/unsupported-role';
  static const String learnerStartup = '/learner-startup';
  static const String onboarding = '/onboarding';
  static const String placementTest = '/placement-test';

  static const String meeting = '/meeting';
  static const String meetingJoinSegment = 'join';
  static const String meetingJoin = '$meeting/$meetingJoinSegment';
  static const String meetingRoomSegment = 'room/:roomId';

  static String meetingRoom(String roomId) =>
      '$meeting/room/${Uri.encodeComponent(roomId)}';

  static const String mentor = '/mentor';
  static const String mentorAvailabilitySegment = 'availability';
  static const String mentorMeetingsSegment = 'meetings';
  static const String mentorMeetingDetailSegment = ':meetingId';
  static const String mentorAvailability = '$mentor/$mentorAvailabilitySegment';
  static const String mentorMeetings = '$mentor/$mentorMeetingsSegment';
  static String mentorMeetingDetail(int meetingId) {
    if (meetingId <= 0) {
      throw ArgumentError.value(meetingId, 'meetingId', 'Must be positive');
    }
    return '$mentorMeetings/$meetingId';
  }

  static const String learnerMentorMeetings = '/mentor-meetings';
  static const String learnerMentorAvailabilitySegment =
      'plans/:planId/availability';
  static const String learnerMentorBookingsSegment = 'bookings';
  static const String learnerMentorBookingDetailSegment = ':bookingId';
  static const String learnerMentorPurchaseStatusSegment =
      'purchases/:subscriptionId';
  static const String learnerMentorBookings =
      '$learnerMentorMeetings/$learnerMentorBookingsSegment';

  static String learnerMentorAvailability(int planId) {
    if (planId <= 0) {
      throw ArgumentError.value(planId, 'planId', 'Must be positive');
    }
    return '$learnerMentorMeetings/plans/$planId/availability';
  }

  static String learnerMentorBookingDetail(int bookingId) {
    if (bookingId <= 0) {
      throw ArgumentError.value(bookingId, 'bookingId', 'Must be positive');
    }
    return '$learnerMentorBookings/$bookingId';
  }

  static String learnerMentorPurchaseStatus(int subscriptionId) {
    if (subscriptionId <= 0) {
      throw ArgumentError.value(
        subscriptionId,
        'subscriptionId',
        'Must be positive',
      );
    }
    return '$learnerMentorMeetings/purchases/$subscriptionId';
  }

  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String learn = '/learn';
  static const String learnRoadmapSegment = 'roadmap';
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
  static const String writingHiraganaSegment = 'hiragana';
  static const String writingKatakanaSegment = 'katakana';
  static const String writingKanjiSegment = 'kanji';
  static const String writingHiraganaDetailSegment = 'hiragana/:characterId';
  static const String writingKatakanaDetailSegment = 'katakana/:characterId';
  static const String writingKanjiDetailSegment = 'kanji/:characterId';
  static const String speechSegment = 'speech';
  static const String textScanSegment = 'scan-text';
  static const String mockTestSegment = 'mock/:testId';
  static const String mockResultSegment = 'result';
  static const String mockDetailedReviewSegment = 'review';
  static const String dailyReview = '$practice/$reviewSegment';
  static const String writing = '$practice/$writingSegment';
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
  static const String profileAccount = '$profile/$profileAccountSegment';
  static const String profileEdit = '$profile/$profileEditSegment';
  static const String profileJlptGoal = '$profile/$profileJlptGoalSegment';
  static const String profileNotifications =
      '$profile/$profileNotificationsSegment';
  static const String profileChangeEmail =
      '$profile/$profileChangeEmailSegment';
  static const String profileChangePassword =
      '$profile/$profileChangePasswordSegment';

  static int _positiveId(int value, String name) {
    if (value <= 0) {
      throw ArgumentError.value(value, name, 'Must be positive');
    }
    return value;
  }
}
