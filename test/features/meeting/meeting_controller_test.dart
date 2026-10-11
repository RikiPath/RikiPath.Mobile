import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_controller.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/meeting_realtime_client.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_connection_state.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_message.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';

void main() {
  final room = MeetingRoomReference(
    roomId: '123e4567-e89b-42d3-a456-426614174000',
    webUri: Uri.parse(
      'https://meeting.example/meeting-room/'
      '123e4567-e89b-42d3-a456-426614174000',
    ),
  );

  late _FakeMeetingRealtimeClient client;
  late _FakeMeetingLauncher launcher;
  late TokenStorage storage;
  late MeetingController controller;

  setUp(() async {
    client = _FakeMeetingRealtimeClient();
    launcher = _FakeMeetingLauncher();
    storage = TokenStorage(_MemorySecureStore());
    await storage.saveAuthenticatedSession(
      accessToken: 'test-token',
      userId: 42,
      role: 'Learner',
    );
    controller = MeetingController(
      room: room,
      client: client,
      tokenStorage: storage,
      browserLauncher: launcher,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('join transitions to connected with server participants', () async {
    await controller.start();

    expect(controller.state.status, MeetingConnectionStatus.connected);
    expect(controller.state.self?.userId, 42);
    expect(controller.state.participants.single.name, 'Mentor A');
    expect(client.lastRole, MeetingParticipantRole.learner);
  });

  test('leave transitions to disconnected and releases the room', () async {
    await controller.start();
    await controller.leave();

    expect(controller.state.status, MeetingConnectionStatus.disconnected);
    expect(client.leaveCalls, 1);
  });

  test('mute, camera, chat and raise-hand actions update state', () async {
    await controller.start();

    await controller.toggleMicrophone();
    await controller.toggleCamera();
    await controller.toggleRaiseHand();
    await controller.sendChatMessage('Xin chào');

    expect(controller.state.isMicOn, isFalse);
    expect(controller.state.isCameraOn, isFalse);
    expect(controller.state.isHandRaised, isTrue);
    expect(controller.state.messages.single.text, 'Xin chào');
    expect(controller.state.messages.single.isSelf, isTrue);
  });

  test('participant and reconnect snapshots stay observable', () async {
    await controller.start();

    client.emit(
      client.currentSnapshot.copyWith(
        status: MeetingConnectionStatus.reconnecting,
        participants: [
          client.currentSnapshot.participants.single.copyWith(
            isHandRaised: true,
            isMicOn: false,
          ),
        ],
      ),
    );

    expect(controller.state.status, MeetingConnectionStatus.reconnecting);
    expect(controller.state.participants.single.isHandRaised, isTrue);
    expect(controller.state.participants.single.isMicOn, isFalse);
  });

  test('invalid room authorization is exposed as a failed state', () async {
    client.failConnect = true;

    await controller.start();

    expect(controller.state.status, MeetingConnectionStatus.failed);
    expect(controller.state.error, 'unauthorized');
  });

  test('released snapshot clears stale participant and media state', () {
    const self = MeetingParticipant(
      connectionId: 'self',
      userId: 42,
      name: 'Learner',
      role: MeetingParticipantRole.learner,
      isMicOn: true,
      isCameraOn: true,
    );
    const active = MeetingRealtimeSnapshot(
      status: MeetingConnectionStatus.connected,
      self: self,
      isMicOn: true,
      isCameraOn: true,
      isHandRaised: true,
    );

    final released = active.copyWith(
      status: MeetingConnectionStatus.failed,
      clearSelf: true,
      participants: const [],
      isMicOn: false,
      isCameraOn: false,
      isHandRaised: false,
    );

    expect(released.self, isNull);
    expect(released.isMicOn, isFalse);
    expect(released.isCameraOn, isFalse);
    expect(released.isHandRaised, isFalse);
  });

  test('browser fallback uses only the preserved verified Web URI', () async {
    expect(await controller.openBrowserFallback(), isTrue);
    expect(launcher.opened, room.webUri);

    final noFallbackController = MeetingController(
      room: const MeetingRoomReference(roomId: 'room'),
      client: _FakeMeetingRealtimeClient(),
      tokenStorage: storage,
      browserLauncher: launcher,
    );
    expect(await noFallbackController.openBrowserFallback(), isFalse);
    noFallbackController.dispose();
  });

  test('dispose delegates media/signaling cleanup to the client', () async {
    controller.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(client.disposed, isTrue);
  });
}

class _FakeMeetingRealtimeClient implements MeetingRealtimeClient {
  final StreamController<MeetingRealtimeSnapshot> _controller =
      StreamController<MeetingRealtimeSnapshot>.broadcast(sync: true);
  MeetingRealtimeSnapshot _snapshot = const MeetingRealtimeSnapshot();
  bool failConnect = false;
  bool disposed = false;
  int leaveCalls = 0;
  MeetingParticipantRole? lastRole;

  @override
  MeetingRealtimeSnapshot get currentSnapshot => _snapshot;

  @override
  Stream<MeetingRealtimeSnapshot> get snapshots => _controller.stream;

  @override
  MediaStream? get localStream => null;

  @override
  MediaStream? remoteStreamFor(String connectionId) => null;

  void emit(MeetingRealtimeSnapshot snapshot) {
    _snapshot = snapshot;
    _controller.add(snapshot);
  }

  @override
  Future<void> connect({
    required MeetingRoomReference room,
    required String displayName,
    required MeetingParticipantRole role,
  }) async {
    lastRole = role;
    emit(_snapshot.copyWith(status: MeetingConnectionStatus.connecting));
    if (failConnect) {
      emit(
        _snapshot.copyWith(
          status: MeetingConnectionStatus.failed,
          error: 'unauthorized',
        ),
      );
      throw StateError('unauthorized');
    }
    emit(_snapshot.copyWith(status: MeetingConnectionStatus.joining));
    emit(
      _snapshot.copyWith(
        status: MeetingConnectionStatus.connected,
        self: const MeetingParticipant(
          connectionId: 'self',
          userId: 42,
          name: 'Learner A',
          role: MeetingParticipantRole.learner,
        ),
        participants: const [
          MeetingParticipant(
            connectionId: 'mentor',
            userId: 7,
            name: 'Mentor A',
            role: MeetingParticipantRole.mentor,
          ),
        ],
        isMicOn: true,
        isCameraOn: true,
      ),
    );
  }

  @override
  Future<void> toggleMicrophone() async {
    emit(_snapshot.copyWith(isMicOn: !_snapshot.isMicOn));
  }

  @override
  Future<void> toggleCamera() async {
    emit(_snapshot.copyWith(isCameraOn: !_snapshot.isCameraOn));
  }

  @override
  Future<void> switchCamera() async {}

  @override
  Future<void> toggleRaiseHand() async {
    emit(_snapshot.copyWith(isHandRaised: !_snapshot.isHandRaised));
  }

  @override
  Future<void> sendChatMessage(String text) async {
    emit(
      _snapshot.copyWith(
        messages: [
          ..._snapshot.messages,
          MeetingMessage(
            id: 'message-${_snapshot.messages.length}',
            sender: 'Learner A',
            role: MeetingParticipantRole.learner,
            text: text,
            timestamp: '10:00',
            isSelf: true,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> leave() async {
    leaveCalls += 1;
    emit(
      _snapshot.copyWith(
        status: MeetingConnectionStatus.disconnected,
        participants: const [],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}

class _FakeMeetingLauncher implements MentorMeetingLinkLauncher {
  Uri? opened;

  @override
  Future<bool> open(Uri uri) async {
    opened = uri;
    return true;
  }
}

class _MemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }
}
