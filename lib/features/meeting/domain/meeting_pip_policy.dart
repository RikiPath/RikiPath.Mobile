import 'package:rikipath_mobile/features/meeting/domain/meeting_connection_state.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant.dart';

abstract final class MeetingPipPolicy {
  static bool isEligible({
    required MeetingConnectionStatus status,
    required bool hasExplicitlyLeft,
  }) {
    if (hasExplicitlyLeft) return false;
    return status == MeetingConnectionStatus.connected ||
        status == MeetingConnectionStatus.reconnecting;
  }

  static MeetingParticipant? selectRemoteParticipant(
    List<MeetingParticipant> participants,
  ) {
    return participants.isEmpty ? null : participants.first;
  }
}
