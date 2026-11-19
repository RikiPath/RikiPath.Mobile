abstract final class AnalyticsApiPaths {
  static const String studyStreak = '/api/Analytics/study-streak';
  static const String completionStats = '/api/Analytics/completion-stats';
  static const String skillBreakdown = '/api/Analytics/skill-breakdown';
  static String skillMonthly([int months = 12]) =>
      '/api/Analytics/skill-monthly?months=$months';
  static const String mockTestHistory = '/api/MockTest/history';
  static const String practiceHistory = '/api/PracticeSubmission/my-history';
  static String homeworkReport(String from, String to) =>
      '/api/homework/report?from=$from&to=$to';
}
