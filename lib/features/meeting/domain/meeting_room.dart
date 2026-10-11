import 'package:flutter/foundation.dart';

@immutable
class MeetingRoomReference {
  const MeetingRoomReference({required this.roomId, this.webUri});

  static const String trustedWebHost = 'riki-path-web.vercel.app';
  static const String trustedWebPathSegment = 'meeting-room';

  static const String _roomIdSource =
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}';
  static final RegExp _roomIdPattern = RegExp('^$_roomIdSource\$');
  static final RegExp _trustedWebPathPattern = RegExp(
    '^/$trustedWebPathSegment/($_roomIdSource)/?\$',
  );
  static final RegExp _backendMeetingPathPattern = RegExp(
    '^/(?:meeting-room|consultation-room|mentor-meeting)/'
    '($_roomIdSource)/?\$',
  );

  final String roomId;
  final Uri? webUri;

  static MeetingRoomReference? fromUserInput(String? value) {
    final candidate = value?.trim();
    if (candidate == null || candidate.isEmpty) return null;

    final directRoomId = _normalizeRoomId(candidate);
    if (directRoomId != null) {
      return MeetingRoomReference(
        roomId: directRoomId,
        webUri: trustedWebUriFor(directRoomId),
      );
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != trustedWebHost ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    final match = _trustedWebPathPattern.firstMatch(uri.path);
    final roomId = _normalizeRoomId(match?.group(1));
    if (roomId == null) return null;
    return MeetingRoomReference(
      roomId: roomId,
      webUri: trustedWebUriFor(roomId),
    );
  }

  static Uri trustedWebUriFor(String roomId) {
    final normalized = _normalizeRoomId(roomId);
    if (normalized == null) {
      throw ArgumentError.value(roomId, 'roomId', 'Must be a canonical UUID.');
    }
    return Uri.https(trustedWebHost, '/$trustedWebPathSegment/$normalized');
  }

  static MeetingRoomReference? resolve({String? roomId, Uri? webUri}) {
    final explicit = _normalizeRoomId(roomId);
    if (explicit != null) {
      return MeetingRoomReference(roomId: explicit, webUri: webUri);
    }
    if (webUri == null) return null;

    final queryRoom = _normalizeRoomId(webUri.queryParameters['roomId']);
    if (queryRoom != null) {
      return MeetingRoomReference(roomId: queryRoom, webUri: webUri);
    }

    final pathMatch = _backendMeetingPathPattern.firstMatch(webUri.path);
    final pathRoom = _normalizeRoomId(pathMatch?.group(1));
    return pathRoom == null
        ? null
        : MeetingRoomReference(roomId: pathRoom, webUri: webUri);
  }

  static String? _normalizeRoomId(String? value) {
    final candidate = value?.trim();
    if (candidate == null || !_roomIdPattern.hasMatch(candidate)) return null;
    return candidate.toLowerCase();
  }
}
