import 'package:permission_handler/permission_handler.dart';

class MeetingPermissionResult {
  const MeetingPermissionResult({
    required this.cameraGranted,
    required this.microphoneGranted,
    required this.hasPermanentDenial,
  });

  final bool cameraGranted;
  final bool microphoneGranted;
  final bool hasPermanentDenial;

  String? get warningCode =>
      switch ((cameraGranted, microphoneGranted, hasPermanentDenial)) {
        (false, true, _) => 'cameraDenied',
        (true, false, _) => 'microphoneDenied',
        (false, false, true) => 'permissionPermanentlyDenied',
        (false, false, false) => 'cameraAndMicrophoneDenied',
        _ => null,
      };
}

abstract interface class MeetingPermissionGateway {
  Future<MeetingPermissionResult> requestMediaPermissions();
}

class PermissionHandlerMeetingPermissionGateway
    implements MeetingPermissionGateway {
  const PermissionHandlerMeetingPermissionGateway();

  @override
  Future<MeetingPermissionResult> requestMediaPermissions() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final camera = statuses[Permission.camera] ?? PermissionStatus.denied;
    final microphone =
        statuses[Permission.microphone] ?? PermissionStatus.denied;
    return MeetingPermissionResult(
      cameraGranted: camera.isGranted,
      microphoneGranted: microphone.isGranted,
      hasPermanentDenial:
          camera.isPermanentlyDenied || microphone.isPermanentlyDenied,
    );
  }
}
