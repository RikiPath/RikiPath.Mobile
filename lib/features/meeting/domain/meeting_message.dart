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
    final rawTimestamp =
        (json['timestamp'] ?? json['Timestamp'] ?? '').toString().trim();
    final timestamp = rawTimestamp.isNotEmpty
        ? rawTimestamp
        : _formatSentAt(json['sentAt'] ?? json['SentAt']);
    return MeetingMessage(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      sender: (json['sender'] ?? json['Sender'] ?? 'RikiPath').toString(),
      role: MeetingParticipantRole.fromApi(json['role'] ?? json['Role']),
      text: (json['text'] ?? json['Text'] ?? '').toString(),
      timestamp: timestamp,
      isSelf: false,
    );
  }

  static String _formatSentAt(Object? raw) {
    final str = raw?.toString().trim();
    if (str == null || str.isEmpty) return '';
    final parsed = DateTime.tryParse(str)?.toLocal();
    if (parsed == null) return '';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  final String id;
  final String sender;
  final MeetingParticipantRole role;
  final String text;
  final String timestamp;
  final bool isSelf;
}
