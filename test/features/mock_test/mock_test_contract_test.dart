import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mock_test/data/mock_test_api_paths.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_attempt_status.dart';

void main() {
  test(
    'uses the current MockTest paths instead of the removed PracticeTest path',
    () {
      expect(MockTestApiPaths.start(7), '/api/MockTest/7/start');
      expect(MockTestApiPaths.submit(11), '/api/MockTest/attempts/11/submit');
      expect(MockTestApiPaths.result(11), '/api/MockTest/attempts/11');
      expect(
        MockTestApiPaths.detailedResult(11),
        '/api/MockTest/attempts/11/detailed',
      );
      expect(MockTestApiPaths.testsByLevel(3), '/api/MockTest/level/3/tests');
    },
  );

  test('maps only source-backed attempt status strings', () {
    expect(
      MockTestAttemptStatus.fromApiValue('in_progress'),
      MockTestAttemptStatus.inProgress,
    );
    expect(
      MockTestAttemptStatus.fromApiValue('completed'),
      MockTestAttemptStatus.completed,
    );
    expect(MockTestAttemptStatus.fromApiValue('pending'), isNull);
  });
}
