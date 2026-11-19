import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_connection_state.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_message.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';

@immutable
class MeetingRealtimeSnapshot {
  const MeetingRealtimeSnapshot({
    this.status = MeetingConnectionStatus.idle,
    this.self,
    this.participants = const [],
    this.messages = const [],
    this.isMicOn = false,
    this.isCameraOn = false,
    this.isHandRaised = false,
    this.isRoomReady = false,
    this.presenterConnectionId,
    this.stageNotice,
    this.mediaWarning,
    this.error,
  });

  final MeetingConnectionStatus status;
  final MeetingParticipant? self;
  final List<MeetingParticipant> participants;
  final List<MeetingMessage> messages;
  final bool isMicOn;
  final bool isCameraOn;
  final bool isHandRaised;
  final bool isRoomReady;
  final String? presenterConnectionId;
  final String? stageNotice;
  final String? mediaWarning;
  final String? error;

  MeetingRealtimeSnapshot copyWith({
    MeetingConnectionStatus? status,
    MeetingParticipant? self,
    bool clearSelf = false,
    List<MeetingParticipant>? participants,
    List<MeetingMessage>? messages,
    bool? isMicOn,
    bool? isCameraOn,
    bool? isHandRaised,
    bool? isRoomReady,
    String? presenterConnectionId,
    bool clearPresenter = false,
    String? stageNotice,
    bool clearStageNotice = false,
    String? mediaWarning,
    bool clearMediaWarning = false,
    String? error,
    bool clearError = false,
  }) {
    return MeetingRealtimeSnapshot(
      status: status ?? this.status,
      self: clearSelf ? null : self ?? this.self,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      isMicOn: isMicOn ?? this.isMicOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isRoomReady: isRoomReady ?? this.isRoomReady,
      presenterConnectionId: clearPresenter
          ? null
          : presenterConnectionId ?? this.presenterConnectionId,
      stageNotice: clearStageNotice ? null : stageNotice ?? this.stageNotice,
      mediaWarning: clearMediaWarning
          ? null
          : mediaWarning ?? this.mediaWarning,
      error: clearError ? null : error ?? this.error,
    );
  }
}

abstract interface class MeetingRealtimeClient {
  Stream<MeetingRealtimeSnapshot> get snapshots;

  MeetingRealtimeSnapshot get currentSnapshot;

  MediaStream? get localStream;

  MediaStream? remoteStreamFor(String connectionId);

  Future<void> connect({
    required MeetingRoomReference room,
    required String displayName,
    required MeetingParticipantRole role,
  });

  Future<void> toggleMicrophone();

  Future<void> toggleCamera();

  Future<void> switchCamera();

  Future<void> toggleRaiseHand();

  Future<void> sendChatMessage(String text);

  Future<void> muteParticipant(String targetConnectionId);

  Future<void> startPresenting();

  Future<void> stopPresenting();

  Future<void> pause();

  Future<void> resume();

  Future<void> leave();

  Future<void> dispose();
}
