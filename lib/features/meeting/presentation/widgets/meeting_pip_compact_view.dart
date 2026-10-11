import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/meeting_realtime_client.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_pip_policy.dart';
import 'package:rikipath_mobile/features/meeting/presentation/widgets/meeting_video_tile.dart';

class MeetingPipCompactView extends StatelessWidget {
  const MeetingPipCompactView({
    required this.snapshot,
    required this.remoteStreamFor,
    super.key,
  });

  final MeetingRealtimeSnapshot snapshot;
  final MediaStream? Function(String connectionId) remoteStreamFor;

  @override
  Widget build(BuildContext context) {
    final participant = MeetingPipPolicy.selectRemoteParticipant(
      snapshot.participants,
    );
    return ColoredBox(
      key: const Key('meeting_pip_compact_view'),
      color: const Color(0xFF17161B),
      child: participant == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white54,
                    size: 36,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.meetingNativeNoParticipants,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD5D1D7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : MeetingVideoTile(
              key: ValueKey('pip-${participant.connectionId}'),
              stream: remoteStreamFor(participant.connectionId),
              name: participant.name,
              initials: participant.initials,
              isCameraOn: participant.isCameraOn,
              isMicOn: participant.isMicOn,
              isHandRaised: participant.isHandRaised,
              borderRadius: BorderRadius.zero,
            ),
    );
  }
}
