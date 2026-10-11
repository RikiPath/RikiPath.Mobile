import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';

typedef MeetingSignalSender =
    Future<void> Function(String method, List<Object?> arguments);

class WebRtcPeerManager {
  WebRtcPeerManager(this._sendSignal, this._onPeersChanged);

  static const Map<String, Object> _configuration = {
    'sdpSemantics': 'unified-plan',
    'iceServers': [
      {
        'urls': ['stun:stun.l.google.com:19302'],
      },
      {
        'urls': ['stun:stun1.l.google.com:19302'],
      },
    ],
  };

  final MeetingSignalSender _sendSignal;
  final VoidCallback _onPeersChanged;
  final Map<String, _PeerEntry> _peers = {};
  MediaStream? _localStream;
  MeetingParticipantRole _localRole = MeetingParticipantRole.learner;

  Iterable<String> get connectionIds => _peers.keys;

  MediaStream? remoteStreamFor(String connectionId) {
    return _peers[connectionId]?.remoteStream;
  }

  void configure({
    required MediaStream? localStream,
    required MeetingParticipantRole localRole,
  }) {
    _localStream = localStream;
    _localRole = localRole;
  }

  Future<void> addPeer(
    MeetingParticipant participant, {
    required bool isOfferer,
  }) async {
    await removePeer(participant.connectionId);
    final pc = await createPeerConnection(_configuration);
    final remoteStream = await createLocalMediaStream(
      'remote-${participant.connectionId}',
    );
    final entry = _PeerEntry(
      participant: participant,
      peerConnection: pc,
      remoteStream: remoteStream,
    );
    _peers[participant.connectionId] = entry;

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate?.isEmpty ?? true) return;
      unawaited(
        _sendSignal('SendIceCandidate', [
          participant.connectionId,
          jsonEncode(candidate.toMap()),
        ]),
      );
    };
    pc.onTrack = (event) {
      unawaited(_attachRemoteTrack(entry, event));
    };
    pc.onConnectionState = (state) {
      entry.webRtcState = _peerConnectionStateLabel(state);
      _onPeersChanged();
    };
    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        unawaited(pc.restartIce());
      }
    };

    final stream = _localStream;
    final kinds = <String>{};
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
        kinds.add(track.kind ?? '');
      }
    }
    if (!kinds.contains('video')) {
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );
    }
    if (!kinds.contains('audio')) {
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );
    }

    _onPeersChanged();
    if (isOfferer) await _sendOffer(entry);
  }

  Future<void> receiveOffer(
    String senderConnectionId,
    Object? sdpPayload,
    MeetingParticipant participant,
  ) async {
    var entry = _peers[senderConnectionId];
    if (entry == null) {
      await addPeer(participant, isOfferer: false);
      entry = _peers[senderConnectionId];
    } else {
      entry.participant = participant.copyWith(
        isMicOn: entry.participant.isMicOn,
        isCameraOn: entry.participant.isCameraOn,
        isHandRaised: entry.participant.isHandRaised,
        isScreenSharing: entry.participant.isScreenSharing,
        webRtcState: entry.webRtcState,
      );
    }
    if (entry == null) return;

    final pc = entry.peerConnection;
    final collision =
        entry.makingOffer ||
        pc.signalingState != RTCSignalingState.RTCSignalingStateStable;
    entry.ignoreOffer =
        _localRole == MeetingParticipantRole.mentor && collision;
    if (entry.ignoreOffer) return;

    final description = _sessionDescription(sdpPayload);
    if (description == null) return;
    await pc.setRemoteDescription(description);
    await _flushIce(entry);
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    await _sendSignal('SendAnswer', [
      senderConnectionId,
      jsonEncode(answer.toMap()),
    ]);
  }

  Future<void> receiveAnswer(
    String senderConnectionId,
    Object? sdpPayload,
  ) async {
    final entry = _peers[senderConnectionId];
    if (entry == null ||
        entry.peerConnection.signalingState !=
            RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      return;
    }
    final description = _sessionDescription(sdpPayload);
    if (description == null) return;
    await entry.peerConnection.setRemoteDescription(description);
    await _flushIce(entry);
  }

  Future<void> receiveIceCandidate(
    String senderConnectionId,
    Object? candidatePayload,
  ) async {
    final entry = _peers[senderConnectionId];
    if (entry == null) return;
    final candidate = _iceCandidate(candidatePayload);
    if (candidate == null) return;

    final remoteDescription = await entry.peerConnection.getRemoteDescription();
    if (remoteDescription == null) {
      entry.pendingIce.add(candidate);
      return;
    }
    try {
      await entry.peerConnection.addCandidate(candidate);
    } catch (_) {
      if (!entry.ignoreOffer) rethrow;
    }
  }

  MeetingParticipant? participantFor(String connectionId) {
    final entry = _peers[connectionId];
    if (entry == null) return null;
    return entry.participant.copyWith(webRtcState: entry.webRtcState);
  }

  void updateParticipant(MeetingParticipant participant) {
    final entry = _peers[participant.connectionId];
    if (entry == null) return;
    entry.participant = participant;
    _onPeersChanged();
  }

  Future<void> removePeer(String connectionId) async {
    final entry = _peers.remove(connectionId);
    if (entry == null) return;
    await entry.peerConnection.close();
    await entry.peerConnection.dispose();
    await entry.remoteStream.dispose();
    _onPeersChanged();
  }

  Future<void> closeAll() async {
    final entries = _peers.values.toList(growable: false);
    _peers.clear();
    for (final entry in entries) {
      await entry.peerConnection.close();
      await entry.peerConnection.dispose();
      await entry.remoteStream.dispose();
    }
    _onPeersChanged();
  }

  Future<void> _sendOffer(_PeerEntry entry) async {
    try {
      entry.makingOffer = true;
      final offer = await entry.peerConnection.createOffer();
      await entry.peerConnection.setLocalDescription(offer);
      await _sendSignal('SendOffer', [
        entry.participant.connectionId,
        jsonEncode(offer.toMap()),
      ]);
    } finally {
      entry.makingOffer = false;
    }
  }

  Future<void> _attachRemoteTrack(_PeerEntry entry, RTCTrackEvent event) async {
    if (entry.remoteStream.getTrackById(event.track.id ?? '') == null) {
      await entry.remoteStream.addTrack(event.track);
    }
    event.track.onEnded = () => _onPeersChanged();
    _onPeersChanged();
  }

  Future<void> _flushIce(_PeerEntry entry) async {
    while (entry.pendingIce.isNotEmpty) {
      final candidate = entry.pendingIce.removeAt(0);
      try {
        await entry.peerConnection.addCandidate(candidate);
      } catch (_) {
        if (!entry.ignoreOffer) rethrow;
      }
    }
  }

  static RTCSessionDescription? _sessionDescription(Object? payload) {
    final json = _jsonMap(payload);
    final sdp = json?['sdp']?.toString();
    final type = json?['type']?.toString();
    if (sdp == null || type == null) return null;
    return RTCSessionDescription(sdp, type);
  }

  static RTCIceCandidate? _iceCandidate(Object? payload) {
    final json = _jsonMap(payload);
    final candidate = json?['candidate']?.toString();
    if (candidate == null || candidate.isEmpty) return null;
    final lineIndexValue = json?['sdpMLineIndex'];
    final lineIndex = lineIndexValue is num
        ? lineIndexValue.toInt()
        : int.tryParse('$lineIndexValue');
    return RTCIceCandidate(candidate, json?['sdpMid']?.toString(), lineIndex);
  }

  static Map<String, Object?>? _jsonMap(Object? payload) {
    final decoded = payload is String ? jsonDecode(payload) : payload;
    if (decoded is! Map) return null;
    return decoded.map((key, value) => MapEntry('$key', value));
  }

  static String _peerConnectionStateLabel(RTCPeerConnectionState state) {
    return state.name.replaceFirst('RTCPeerConnectionState', '').toLowerCase();
  }
}

class _PeerEntry {
  _PeerEntry({
    required this.participant,
    required this.peerConnection,
    required this.remoteStream,
  });

  MeetingParticipant participant;
  final RTCPeerConnection peerConnection;
  final MediaStream remoteStream;
  final List<RTCIceCandidate> pendingIce = [];
  bool makingOffer = false;
  bool ignoreOffer = false;
  String webRtcState = 'new';
}

typedef VoidCallback = void Function();
