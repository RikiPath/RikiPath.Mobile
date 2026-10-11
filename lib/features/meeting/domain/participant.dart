import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';

@immutable
class MeetingParticipant {
  const MeetingParticipant({
    required this.connectionId,
    required this.userId,
    required this.name,
    required this.role,
    this.isMicOn = true,
    this.isCameraOn = true,
    this.isHandRaised = false,
    this.isScreenSharing = false,
    this.webRtcState = 'new',
  });

  factory MeetingParticipant.fromJson(Map<String, Object?> json) {
    return MeetingParticipant(
      connectionId: _string(json, 'connectionId', 'ConnectionId'),
      userId: _integer(json, 'id', 'Id'),
      name: _string(json, 'name', 'Name', fallback: 'RikiPath'),
      role: MeetingParticipantRole.fromApi(json['role'] ?? json['Role']),
    );
  }

  final String connectionId;
  final int userId;
  final String name;
  final MeetingParticipantRole role;
  final bool isMicOn;
  final bool isCameraOn;
  final bool isHandRaised;
  final bool isScreenSharing;
  final String webRtcState;

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 'RP';
    if (words.length == 1) {
      final value = words.first;
      return value.substring(0, value.length.clamp(1, 2)).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  MeetingParticipant copyWith({
    bool? isMicOn,
    bool? isCameraOn,
    bool? isHandRaised,
    bool? isScreenSharing,
    String? webRtcState,
  }) {
    return MeetingParticipant(
      connectionId: connectionId,
      userId: userId,
      name: name,
      role: role,
      isMicOn: isMicOn ?? this.isMicOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      webRtcState: webRtcState ?? this.webRtcState,
    );
  }

  static String _string(
    Map<String, Object?> json,
    String camel,
    String pascal, {
    String fallback = '',
  }) {
    final value = json[camel] ?? json[pascal];
    return value?.toString().trim().isNotEmpty == true
        ? value.toString().trim()
        : fallback;
  }

  static int _integer(Map<String, Object?> json, String camel, String pascal) {
    final value = json[camel] ?? json[pascal];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }
}
