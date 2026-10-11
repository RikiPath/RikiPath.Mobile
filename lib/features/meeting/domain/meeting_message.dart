import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';

@immutable
class MeetingMessage {
  const MeetingMessage({
    required this.id,
    required this.sender,
    required this.role,
    required this.text,
    required this.timestamp,
    required this.isSelf,
  });

  factory MeetingMessage.fromJson(Map<String, Object?> json) {
    return MeetingMessage(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      sender: (json['sender'] ?? json['Sender'] ?? 'RikiPath').toString(),
      role: MeetingParticipantRole.fromApi(json['role'] ?? json['Role']),
      text: (json['text'] ?? json['Text'] ?? '').toString(),
      timestamp: (json['timestamp'] ?? json['Timestamp'] ?? '').toString(),
      isSelf: false,
    );
  }

  final String id;
  final String sender;
  final MeetingParticipantRole role;
  final String text;
  final String timestamp;
  final bool isSelf;
}
