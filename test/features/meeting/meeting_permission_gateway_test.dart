import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/meeting_permission_gateway.dart';

void main() {
  test('partial permanent denial reports only the denied media permission', () {
    const cameraDenied = MeetingPermissionResult(
      cameraGranted: false,
      microphoneGranted: true,
      hasPermanentDenial: true,
    );
    const microphoneDenied = MeetingPermissionResult(
      cameraGranted: true,
      microphoneGranted: false,
      hasPermanentDenial: true,
    );

    expect(cameraDenied.warningCode, 'cameraDenied');
    expect(microphoneDenied.warningCode, 'microphoneDenied');
  });

  test('complete denial distinguishes permanent and retryable states', () {
    const permanent = MeetingPermissionResult(
      cameraGranted: false,
      microphoneGranted: false,
      hasPermanentDenial: true,
    );
    const retryable = MeetingPermissionResult(
      cameraGranted: false,
      microphoneGranted: false,
      hasPermanentDenial: false,
    );

    expect(permanent.warningCode, 'permissionPermanentlyDenied');
    expect(retryable.warningCode, 'cameraAndMicrophoneDenied');
  });

  test('granted media permissions do not emit a warning', () {
    const granted = MeetingPermissionResult(
      cameraGranted: true,
      microphoneGranted: true,
      hasPermanentDenial: false,
    );

    expect(granted.warningCode, isNull);
  });
}
