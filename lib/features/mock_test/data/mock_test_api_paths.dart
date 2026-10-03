abstract final class MockTestApiPaths {
  static String start(int mockTestId) => '/api/MockTest/$mockTestId/start';

  static String submit(int attemptId) =>
      '/api/MockTest/attempts/$attemptId/submit';

  static String result(int attemptId) => '/api/MockTest/attempts/$attemptId';

  static String detailedResult(int attemptId) =>
      '/api/MockTest/attempts/$attemptId/detailed';

  static String testsByLevel(int jlptLevelId) =>
      '/api/MockTest/level/$jlptLevelId/tests';
}
