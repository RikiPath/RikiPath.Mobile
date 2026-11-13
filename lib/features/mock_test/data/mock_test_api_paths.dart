abstract final class MockTestApiPaths {
  static String start(int mockTestId) => '/api/MockTest/$mockTestId/start';

  static String active(int mockTestId) => '/api/MockTest/$mockTestId/active';

  static String submit(int attemptId) =>
      '/api/MockTest/attempts/$attemptId/submit';

  static String saveAnswer(int attemptId) =>
      '/api/MockTest/attempts/$attemptId/answer';

  static String finalizeExpired(int attemptId) =>
      '/api/MockTest/attempts/$attemptId/finalize';

  static String result(int attemptId) => '/api/MockTest/attempts/$attemptId';

  static String detailedResult(int attemptId) =>
      '/api/MockTest/attempts/$attemptId/detailed';

  static String testsByLevel(int jlptLevelId) =>
      '/api/MockTest/level/$jlptLevelId/tests';
}
