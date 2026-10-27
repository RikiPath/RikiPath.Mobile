abstract final class PlacementTestApiPaths {
  static const String status = '/api/PlacementTest/status';
  static const String start = '/api/PlacementTest/start';
  static const String skip = '/api/PlacementTest/skip';
  static const String activeAttempt = '/api/PlacementTest/attempts/active';

  static String submit(int attemptId) =>
      '/api/PlacementTest/attempts/$attemptId/submit';

  static String result(int attemptId) =>
      '/api/PlacementTest/attempts/$attemptId';
}
