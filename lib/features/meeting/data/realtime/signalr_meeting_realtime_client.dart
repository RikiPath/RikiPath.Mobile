import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/meeting_permission_gateway.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/meeting_realtime_client.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/web_rtc_peer_manager.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_connection_state.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_message.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';
import 'package:signalr_hub/signalr_client.dart';

class SignalRMeetingRealtimeClient implements MeetingRealtimeClient {
  SignalRMeetingRealtimeClient({
    required this.hubUri,
    required this.tokenStorage,
    this.permissionGateway = const PermissionHandlerMeetingPermissionGateway(),
  }) {
    _peerManager = WebRtcPeerManager(_sendPeerSignal, _syncPeerState);
  }

  final Uri hubUri;
  final TokenStorage tokenStorage;
  final MeetingPermissionGateway permissionGateway;
  final StreamController<MeetingRealtimeSnapshot> _snapshotController =
      StreamController<MeetingRealtimeSnapshot>.broadcast(sync: true);
  final Map<String, MeetingParticipant> _participants = {};
  late final WebRtcPeerManager _peerManager;

  HubConnection? _hub;
  MeetingRoomReference? _room;
  MediaStream? _localStream;
  MeetingParticipantRole _localRole = MeetingParticipantRole.learner;
  String _displayName = 'RikiPath';
  MeetingRealtimeSnapshot _snapshot = const MeetingRealtimeSnapshot();
  bool _leaving = false;
  bool _disposed = false;
  bool _paused = false;
  bool _resumeMic = false;
  bool _resumeCamera = false;
  int _messageSequence = 0;

  @override
  Stream<MeetingRealtimeSnapshot> get snapshots => _snapshotController.stream;

  @override
  MeetingRealtimeSnapshot get currentSnapshot => _snapshot;

  @override
  MediaStream? get localStream => _localStream;

  @override
  MediaStream? remoteStreamFor(String connectionId) {
    return _peerManager.remoteStreamFor(connectionId);
  }

  @override
  Future<void> connect({
    required MeetingRoomReference room,
    required String displayName,
    required MeetingParticipantRole role,
  }) async {
    if (_disposed) throw StateError('Meeting client is already disposed.');
    if (_hub != null) await leave();
    _leaving = false;
    _room = room;
    _displayName = displayName.trim().isEmpty ? 'RikiPath' : displayName.trim();
    _localRole = role;
    _emit(
      _snapshot.copyWith(
        status: MeetingConnectionStatus.connecting,
        clearError: true,
        clearMediaWarning: true,
      ),
    );

    try {
      final token = await tokenStorage.readAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw const MeetingAuthenticationException();
      }
      await _initializeLocalMedia();
      _peerManager.configure(localStream: _localStream, localRole: role);
      final hub = HubConnectionBuilder()
          .withUrl(
            hubUri.toString(),
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                final current = await tokenStorage.readAccessToken();
                if (current == null || current.trim().isEmpty) {
                  throw const MeetingAuthenticationException();
                }
                return current;
              },
              requestTimeout: 10000,
            ),
          )
          .withAutomaticReconnect(
            retryDelays: const [0, 2000, 5000, 10000, 30000],
          )
          .build();
      hub.invocationTimeout = const Duration(seconds: 15);
      _hub = hub;
      _registerHubHandlers(hub);
      await hub.start();
      await _joinRoom(status: MeetingConnectionStatus.joining);
      await _broadcastMediaState();
    } catch (error) {
      await _releaseConnection(emitDisconnected: false);
      _emit(
        _snapshot.copyWith(
          status: MeetingConnectionStatus.failed,
          error: _safeError(error),
        ),
      );
      rethrow;
    }
  }

  Future<void> _initializeLocalMedia() async {
    final permissions = await permissionGateway.requestMediaPermissions();
    _emit(_snapshot.copyWith(mediaWarning: permissions.warningCode));

    if (!permissions.cameraGranted && !permissions.microphoneGranted) return;
    final constraints = <String, Object>{
      'video': permissions.cameraGranted
          ? <String, Object>{
              'facingMode': 'user',
              'width': <String, int>{'ideal': 1280},
              'height': <String, int>{'ideal': 720},
            }
          : false,
      'audio': permissions.microphoneGranted
          ? <String, bool>{
              'echoCancellation': true,
              'noiseSuppression': true,
              'autoGainControl': true,
            }
          : false,
    };
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (_) {
      if (!permissions.microphoneGranted) {
        _emit(_snapshot.copyWith(mediaWarning: 'mediaUnavailable'));
        return;
      }
      try {
        _localStream = await navigator.mediaDevices.getUserMedia({
          'video': false,
          'audio': constraints['audio']!,
        });
        _emit(_snapshot.copyWith(mediaWarning: 'cameraUnavailable'));
      } catch (_) {
        _emit(_snapshot.copyWith(mediaWarning: 'mediaUnavailable'));
        return;
      }
    }
    final micOn = _localStream!.getAudioTracks().isNotEmpty;
    final cameraOn = _localStream!.getVideoTracks().isNotEmpty;
    _emit(_snapshot.copyWith(isMicOn: micOn, isCameraOn: cameraOn));
    try {
      await Helper.setSpeakerphoneOnButPreferBluetooth();
    } catch (_) {
      // The OS still provides its default audio route when this is unsupported.
    }
  }

  void _registerHubHandlers(HubConnection hub) {
    hub.on('UserJoined', (arguments) async {
      final peer = _participantFrom(_argument(arguments, 0));
      if (peer == null || peer.connectionId.isEmpty) return;
      _participants[peer.connectionId] = peer;
      await _peerManager.addPeer(peer, isOfferer: true);
      await _broadcastMediaState();
      _emitParticipants();
    });
    hub.on('ReceiveOffer', (arguments) async {
      final connectionId = _stringArgument(arguments, 0);
      final participant = _participantFrom(_argument(arguments, 2));
      if (connectionId == null || participant == null) return;
      _participants[connectionId] = participant;
      await _peerManager.receiveOffer(
        connectionId,
        _argument(arguments, 1),
        participant,
      );
      _emitParticipants();
    });
    hub.on('ReceiveAnswer', (arguments) async {
      final connectionId = _stringArgument(arguments, 0);
      if (connectionId == null) return;
      await _peerManager.receiveAnswer(connectionId, _argument(arguments, 1));
    });
    hub.on('ReceiveIceCandidate', (arguments) async {
      final connectionId = _stringArgument(arguments, 0);
      if (connectionId == null) return;
      await _peerManager.receiveIceCandidate(
        connectionId,
        _argument(arguments, 1),
      );
    });
    hub.on('UserLeft', (arguments) async {
      final connectionId = _stringArgument(arguments, 0);
      if (connectionId == null) return;
      _participants.remove(connectionId);
      await _peerManager.removePeer(connectionId);
      _emitParticipants();
    });
    hub.on('ReceiveMediaState', (arguments) {
      final connectionId = _stringArgument(arguments, 0);
      final state = _mapArgument(arguments, 1);
      final participant = connectionId == null
          ? null
          : _participants[connectionId];
      if (participant == null || state == null) return;
      final updated = participant.copyWith(
        isMicOn: _boolean(state, 'isMicOn', 'IsMicOn', fallback: true),
        isCameraOn: _boolean(state, 'isCamOn', 'IsCamOn', fallback: true),
        isScreenSharing: _boolean(
          state,
          'isScreenSharing',
          'IsScreenSharing',
          fallback: false,
        ),
      );
      _participants[connectionId!] = updated;
      _peerManager.updateParticipant(updated);
      _emitParticipants();
    });
    hub.on('ReceiveHandRaised', (arguments) {
      final connectionId = _stringArgument(arguments, 0);
      final participant = connectionId == null
          ? null
          : _participants[connectionId];
      if (participant == null) return;
      final updated = participant.copyWith(
        isHandRaised: _argument(arguments, 1) == true,
      );
      _participants[connectionId!] = updated;
      _peerManager.updateParticipant(updated);
      _emitParticipants();
    });
    hub.on('ReceiveChatMessage', (arguments) {
      final messageMap = _mapArgument(arguments, 0);
      if (messageMap == null) return;
      final message = MeetingMessage.fromJson(messageMap);
      if (message.id.isEmpty || message.text.trim().isEmpty) return;
      if (_snapshot.messages.any((item) => item.id == message.id)) return;
      _emit(_snapshot.copyWith(messages: [..._snapshot.messages, message]));
    });
    hub.on('ForceMuted', (_) async {
      for (final track in _localStream?.getAudioTracks() ?? const []) {
        track.enabled = false;
      }
      _emit(_snapshot.copyWith(isMicOn: false));
      await _broadcastMediaState();
    });
    hub.on('PresentationForceStopped', (_) {});
    hub.onreconnecting(({error}) {
      if (_leaving || _disposed) return;
      _emit(_snapshot.copyWith(status: MeetingConnectionStatus.reconnecting));
    });
    hub.onreconnected(({connectionId}) {
      if (_leaving || _disposed) return;
      unawaited(_rejoinAfterReconnect());
    });
    hub.onclose(({error}) {
      if (_leaving || _disposed) return;
      _emit(
        _snapshot.copyWith(
          status: MeetingConnectionStatus.failed,
          error: _safeError(error),
        ),
      );
    });
  }

  Future<void> _joinRoom({required MeetingConnectionStatus status}) async {
    final hub = _hub;
    final room = _room;
    if (hub == null || room == null) return;
    _emit(_snapshot.copyWith(status: status, clearError: true));
    final response = await hub.invoke(
      'JoinRoom',
      args: [room.roomId, _displayName, _localRole.apiValue],
      timeout: const Duration(seconds: 15),
    );
    final map = _asMap(response);
    final self = _participantFrom(map?['self'] ?? map?['Self']);
    final rawParticipants = map?['participants'] ?? map?['Participants'];
    _participants.clear();
    await _peerManager.closeAll();
    if (rawParticipants is Iterable) {
      for (final value in rawParticipants) {
        final participant = _participantFrom(value);
        if (participant == null || participant.connectionId.isEmpty) continue;
        _participants[participant.connectionId] = participant;
        await _peerManager.addPeer(participant, isOfferer: false);
      }
    }
    _emit(
      _snapshot.copyWith(
        status: MeetingConnectionStatus.connected,
        self: self,
        participants: _participants.values.toList(growable: false),
        clearError: true,
      ),
    );
  }

  Future<void> _rejoinAfterReconnect() async {
    try {
      await _joinRoom(status: MeetingConnectionStatus.reconnecting);
      await _broadcastMediaState();
    } catch (error) {
      _emit(
        _snapshot.copyWith(
          status: MeetingConnectionStatus.failed,
          error: _safeError(error),
        ),
      );
    }
  }

  @override
  Future<void> toggleMicrophone() async {
    final tracks = _localStream?.getAudioTracks() ?? const [];
    if (tracks.isEmpty) return;
    final next = !_snapshot.isMicOn;
    for (final track in tracks) {
      track.enabled = next;
    }
    _emit(_snapshot.copyWith(isMicOn: next));
    await _broadcastMediaState();
  }

  @override
  Future<void> toggleCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? const [];
    if (tracks.isEmpty) return;
    final next = !_snapshot.isCameraOn;
    for (final track in tracks) {
      track.enabled = next;
    }
    _emit(_snapshot.copyWith(isCameraOn: next));
    await _broadcastMediaState();
  }

  @override
  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? const [];
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
  }

  @override
  Future<void> toggleRaiseHand() async {
    final next = !_snapshot.isHandRaised;
    _emit(_snapshot.copyWith(isHandRaised: next));
    await _invokeRoomMethod('RaiseHand', [next]);
  }

  @override
  Future<void> sendChatMessage(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    final safeText = normalized.length > 2000
        ? normalized.substring(0, 2000)
        : normalized;
    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final id = '${now.microsecondsSinceEpoch}-${_messageSequence++}';
    final message = MeetingMessage(
      id: id,
      sender: _snapshot.self?.name ?? _displayName,
      role: _snapshot.self?.role ?? _localRole,
      text: safeText,
      timestamp: timestamp,
      isSelf: true,
    );
    _emit(_snapshot.copyWith(messages: [..._snapshot.messages, message]));
    await _invokeRoomMethod('SendChatMessage', [
      {'id': id, 'text': safeText, 'timestamp': timestamp},
    ]);
  }

  @override
  Future<void> pause() async {
    if (_paused || _disposed || _leaving) return;
    _paused = true;
    _resumeMic = _snapshot.isMicOn;
    _resumeCamera = _snapshot.isCameraOn;
    for (final track in _localStream?.getAudioTracks() ?? const []) {
      track.enabled = false;
    }
    for (final track in _localStream?.getVideoTracks() ?? const []) {
      track.enabled = false;
    }
    _emit(_snapshot.copyWith(isMicOn: false, isCameraOn: false));
    await _broadcastMediaState();
  }

  @override
  Future<void> resume() async {
    if (_disposed || _leaving) return;
    _paused = false;
    final hub = _hub;
    if (hub == null) return;
    final isReachable = await hub.probeConnection();
    if (!isReachable) {
      try {
        await hub.stop();
        await hub.start();
        await _joinRoom(status: MeetingConnectionStatus.reconnecting);
      } catch (error) {
        _emit(
          _snapshot.copyWith(
            status: MeetingConnectionStatus.failed,
            error: _safeError(error),
          ),
        );
        return;
      }
    }
    for (final track in _localStream?.getAudioTracks() ?? const []) {
      track.enabled = _resumeMic;
    }
    for (final track in _localStream?.getVideoTracks() ?? const []) {
      track.enabled = _resumeCamera;
    }
    _emit(
      _snapshot.copyWith(
        isMicOn:
            _resumeMic && (_localStream?.getAudioTracks().isNotEmpty ?? false),
        isCameraOn:
            _resumeCamera &&
            (_localStream?.getVideoTracks().isNotEmpty ?? false),
      ),
    );
    await _broadcastMediaState();
  }

  @override
  Future<void> leave() async {
    if (_leaving) return;
    _leaving = true;
    final hub = _hub;
    final room = _room;
    if (hub != null && room != null) {
      try {
        await hub.invoke(
          'LeaveRoom',
          args: [room.roomId],
          timeout: const Duration(seconds: 4),
        );
      } catch (_) {
        // Local cleanup must continue when the signaling server is unreachable.
      }
    }
    await _releaseConnection();
  }

  Future<void> _releaseConnection({bool emitDisconnected = true}) async {
    final hub = _hub;
    _hub = null;
    if (hub != null) {
      try {
        await hub.stop();
      } catch (_) {}
    }
    await _peerManager.closeAll();
    _participants.clear();
    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        track.stop();
      }
      await stream.dispose();
    }
    try {
      // flutter_webrtc can keep its Android AudioRecord alive after every
      // stream/peer has been disposed (notably after a PiP dismissal). Force
      // the shared ADM recorder to stop so the meeting cannot retain the
      // microphone when its UI and signaling session have already ended.
      await NativeAudioManagement.stopLocalRecording();
    } catch (_) {
      // Track and stream cleanup above remains the cross-platform fallback.
    }
    _emit(
      _snapshot.copyWith(
        status: emitDisconnected
            ? MeetingConnectionStatus.disconnected
            : _snapshot.status,
        clearSelf: true,
        participants: const [],
        isMicOn: false,
        isCameraOn: false,
        isHandRaised: false,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await leave();
    _disposed = true;
    await _snapshotController.close();
  }

  Future<void> _broadcastMediaState() {
    return _invokeRoomMethod('ToggleMediaState', [
      {
        'isMicOn': _snapshot.isMicOn,
        'isCamOn': _snapshot.isCameraOn,
        'isScreenSharing': false,
        'screenStreamId': null,
      },
    ]);
  }

  Future<void> _sendPeerSignal(String method, List<Object?> arguments) {
    return _invokeRoomMethod(method, arguments);
  }

  Future<void> _invokeRoomMethod(String method, List<Object?> arguments) async {
    final hub = _hub;
    final room = _room;
    if (hub == null ||
        room == null ||
        hub.state != HubConnectionState.connected) {
      return;
    }
    await hub.invoke(
      method,
      args: [room.roomId, ...arguments],
      timeout: const Duration(seconds: 10),
    );
  }

  void _syncPeerState() {
    for (final connectionId in _peerManager.connectionIds) {
      final participant = _peerManager.participantFor(connectionId);
      if (participant != null) _participants[connectionId] = participant;
    }
    _emitParticipants();
  }

  void _emitParticipants() {
    _emit(
      _snapshot.copyWith(
        participants: _participants.values.toList(growable: false),
      ),
    );
  }

  void _emit(MeetingRealtimeSnapshot next) {
    _snapshot = next;
    if (!_snapshotController.isClosed) _snapshotController.add(next);
  }

  static Object? _argument(List<Object?>? arguments, int index) {
    if (arguments == null || index < 0 || index >= arguments.length) {
      return null;
    }
    return arguments[index];
  }

  static String? _stringArgument(List<Object?>? arguments, int index) {
    final value = _argument(arguments, index)?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Map<String, Object?>? _mapArgument(
    List<Object?>? arguments,
    int index,
  ) {
    return _asMap(_argument(arguments, index));
  }

  static Map<String, Object?>? _asMap(Object? value) {
    if (value is! Map) return null;
    return value.map((key, item) => MapEntry('$key', item));
  }

  static MeetingParticipant? _participantFrom(Object? value) {
    final map = _asMap(value);
    if (map == null) return null;
    return MeetingParticipant.fromJson(map);
  }

  static bool _boolean(
    Map<String, Object?> map,
    String camel,
    String pascal, {
    required bool fallback,
  }) {
    final value = map[camel] ?? map[pascal];
    return value is bool ? value : fallback;
  }

  static String _safeError(Object? error) {
    if (error is MeetingAuthenticationException) return 'authRequired';
    if (error is SignalRAuthException) return 'notAuthorized';
    final raw = error?.toString().trim() ?? '';
    final normalized = raw.toLowerCase();
    if (normalized.contains('không tìm thấy phòng meeting đã thanh toán')) {
      return 'roomNotFound';
    }
    if (normalized.contains('không có quyền vào phòng này')) {
      return 'notAuthorized';
    }
    if (normalized.contains('socketexception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('connection refused') ||
        normalized.contains('timed out')) {
      return 'networkError';
    }
    return 'connectionFailed';
  }
}

class MeetingAuthenticationException implements Exception {
  const MeetingAuthenticationException();

  @override
  String toString() => 'Meeting authentication is required.';
}
