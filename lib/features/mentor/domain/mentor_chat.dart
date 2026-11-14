import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';

/// Chat message model matching Backend `MentorChatMessageResponse`.
class MentorChatMessage {
  const MentorChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderUserId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.sentAt,
    this.readAt,
  });

  final int id;
  final int bookingId;
  final int senderUserId;
  final String senderName;
  final String senderRole;
  final String text;
  final MentorTimestamp sentAt;
  final MentorTimestamp? readAt;

  bool get isRead => readAt != null;

  MentorChatMessage copyWith({MentorTimestamp? readAt}) {
    return MentorChatMessage(
      id: id,
      bookingId: bookingId,
      senderUserId: senderUserId,
      senderName: senderName,
      senderRole: senderRole,
      text: text,
      sentAt: sentAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// Chat thread summary matching Backend `MentorChatThreadResponse`.
class MentorChatThread {
  const MentorChatThread({
    required this.bookingId,
    required this.learnerId,
    required this.learnerName,
    required this.mentorId,
    required this.mentorName,
    required this.bookingStatus,
    required this.canSendMessages,
    required this.unreadCount,
    this.scheduledAt,
    this.endsAt,
    this.lastMessage,
  });

  final int bookingId;
  final int learnerId;
  final String learnerName;
  final int mentorId;
  final String mentorName;
  final MentorTimestamp? scheduledAt;
  final MentorTimestamp? endsAt;
  final String bookingStatus;
  final bool canSendMessages;
  final int unreadCount;
  final MentorChatMessage? lastMessage;

  MentorChatThread copyWith({
    int? unreadCount,
    MentorChatMessage? lastMessage,
    bool? canSendMessages,
  }) {
    return MentorChatThread(
      bookingId: bookingId,
      learnerId: learnerId,
      learnerName: learnerName,
      mentorId: mentorId,
      mentorName: mentorName,
      scheduledAt: scheduledAt,
      endsAt: endsAt,
      bookingStatus: bookingStatus,
      canSendMessages: canSendMessages ?? this.canSendMessages,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

enum MentorChatConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}
