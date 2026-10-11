import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_native_rollout.dart';

void main() {
  test('native meeting is enabled by default for the verified demo', () {
    expect(MeetingNativeRollout.isEnabled, isTrue);
  });
}
