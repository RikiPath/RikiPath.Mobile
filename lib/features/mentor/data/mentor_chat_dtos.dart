import 'package:rikipath_mobile/features/mentor/data/mentor_json_helpers.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_chat.dart';

class MentorChatMessageDto {
  MentorChatMessageDto._();

  static MentorChatMessage fromJson(Map<String, Object?> json) {
    return MentorChatMessage(
      id: readRequiredPositiveInt(json, 'id'),
      bookingId: readIntOrZero(json, 'bookingId'),
      senderUserId: readIntOrZero(json, 'senderUserId'),
      senderName: readStringOrEmpty(json, 'senderName'),
      senderRole: readStringOrEmpty(json, 'senderRole'),
      text: readStringOrEmpty(json, 'text'),
      sentAt: readRequiredTimestamp(json, 'sentAt'),
      readAt: readOptionalTimestamp(json, 'readAt'),
    );
  }
}

class MentorChatThreadDto {
  MentorChatThreadDto._();

  static MentorChatThread fromJson(Map<String, Object?> json) {
    final rawLast = readMapOrEmpty(json['lastMessage']);
    return MentorChatThread(
      bookingId: readRequiredPositiveInt(json, 'bookingId'),
      learnerId: readIntOrZero(json, 'learnerId'),
      learnerName: readStringOrEmpty(json, 'learnerName'),
      mentorId: readIntOrZero(json, 'mentorId'),
      mentorName: readStringOrEmpty(json, 'mentorName'),
      scheduledAt: readOptionalTimestamp(json, 'scheduledAt'),
      endsAt: readOptionalTimestamp(json, 'endsAt'),
      bookingStatus: readStringOrEmpty(json, 'bookingStatus'),
      canSendMessages: readBoolOrFalse(json, 'canSendMessages'),
      unreadCount: readIntOrZero(json, 'unreadCount'),
      lastMessage: rawLast.isEmpty
          ? null
          : MentorChatMessageDto.fromJson(rawLast),
    );
  }
}
