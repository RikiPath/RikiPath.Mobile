import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';

enum MeetingLinkValidationError { empty, invalid }

@immutable
class MeetingJoinTarget {
  const MeetingJoinTarget._(this.room);

  final MeetingRoomReference room;

  String get roomId => room.roomId;

  Uri get browserFallbackUri =>
      room.webUri ?? MeetingRoomReference.trustedWebUriFor(roomId);

  static ({MeetingJoinTarget? target, MeetingLinkValidationError? error}) parse(
    String? rawValue,
  ) {
    final normalized = rawValue?.trim();
    if (normalized == null || normalized.isEmpty) {
      return (target: null, error: MeetingLinkValidationError.empty);
    }
    final room = MeetingRoomReference.fromUserInput(normalized);
    if (room == null) {
      return (target: null, error: MeetingLinkValidationError.invalid);
    }
    return (target: MeetingJoinTarget._(room), error: null);
  }
}
