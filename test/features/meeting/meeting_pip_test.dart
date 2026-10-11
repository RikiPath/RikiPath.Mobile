import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_controller.dart';
import 'package:rikipath_mobile/features/meeting/application/meeting_pip_controller.dart';
import 'package:rikipath_mobile/features/meeting/data/platform/meeting_pip_platform.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/meeting_realtime_client.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_connection_state.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_message.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_pip_policy.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';
import 'package:rikipath_mobile/features/meeting/presentation/meeting_room_screen.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  group('Meeting PiP policy', () {
    test('only active connected or reconnecting sessions are eligible', () {
      for (final status in MeetingConnectionStatus.values) {
        final expected =
            status == MeetingConnectionStatus.connected ||
            status == MeetingConnectionStatus.reconnecting;
        expect(
          MeetingPipPolicy.isEligible(status: status, hasExplicitlyLeft: false),
          expected,
          reason: status.name,
        );
      }
      expect(
        MeetingPipPolicy.isEligible(
          status: MeetingConnectionStatus.connected,
          hasExplicitlyLeft: true,
        ),
        isFalse,
      );
    });

    test('compact mode keeps the first remote participant predictably', () {
      const first = MeetingParticipant(
        connectionId: 'first',
        userId: 1,
        name: 'First',
        role: MeetingParticipantRole.mentor,
      );
      const second = MeetingParticipant(
        connectionId: 'second',
        userId: 2,
        name: 'Second',
        role: MeetingParticipantRole.learner,
      );
      expect(
        MeetingPipPolicy.selectRemoteParticipant(const [first, second]),
        same(first),
      );
      expect(
        MeetingPipPolicy.selectRemoteParticipant(const [second]),
        same(second),
      );
      expect(MeetingPipPolicy.selectRemoteParticipant(const []), isNull);
    });
  });

  group('MeetingPipController', () {
    test('manual entry follows support and eligibility', () async {
      final platform = _FakeMeetingPipPlatform();
      final controller = MeetingPipController(platform);
      addTearDown(controller.dispose);

      await controller.setEligible(true);
      expect(controller.state.isSupported, isTrue);
      expect(controller.state.isEligible, isTrue);
      expect(await controller.enter(), isTrue);
      expect(platform.enterCalls, 1);

      platform.emitMode(true);
      expect(controller.state.isInPip, isTrue);
      platform.emitMode(false);
      expect(controller.state.isInPip, isFalse);
    });

    test('unsupported hosts keep PiP unavailable without throwing', () async {
      final platform = _FakeMeetingPipPlatform(supported: false);
      final controller = MeetingPipController(platform);
      addTearDown(controller.dispose);

      await controller.setEligible(true);
      expect(controller.state.isSupported, isFalse);
      expect(await controller.enter(), isFalse);
      expect(platform.enterCalls, 0);
    });

    test('native dismissal is exposed exactly once', () async {
      final platform = _FakeMeetingPipPlatform();
      final controller = MeetingPipController(platform);
      addTearDown(controller.dispose);
      var dismissals = 0;
      final subscription = controller.dismissals.listen((_) => dismissals++);
      addTearDown(subscription.cancel);

      await controller.initialize();
      platform.emitMode(true);
      platform.emitDismissed();

      expect(controller.state.isInPip, isFalse);
      expect(dismissals, 1);
    });
  });

  group('MeetingRoomScreen PiP lifecycle', () {
    testWidgets('PiP uses compact remote UI and preserves meeting state', (
      tester,
    ) async {
      final harness = await _pumpMeetingRoom(tester);
      addTearDown(harness.dispose);

      expect(
        find.byKey(const Key('meeting_more_actions_button')),
        findsOneWidget,
      );
      harness.pipPlatform.emitMode(true);
      await tester.pump();

      expect(find.byKey(const Key('meeting_pip_compact_view')), findsOneWidget);
      expect(find.byKey(const ValueKey('pip-mentor')), findsOneWidget);
      expect(
        find.byKey(const Key('meeting_more_actions_button')),
        findsNothing,
      );
      expect(find.byKey(const Key('meeting_microphone_control')), findsNothing);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 500));
      expect(harness.realtimeClient.pauseCalls, 0);

      await harness.container
          .read(meetingControllerProvider(harness.room))
          .sendChatMessage('Tin nhắn trong PiP');
      expect(
        harness.container
            .read(meetingControllerProvider(harness.room))
            .state
            .messages
            .single
            .text,
        'Tin nhắn trong PiP',
      );
      expect(harness.realtimeClient.connectCalls, 1);

      harness.pipPlatform.emitMode(false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byKey(const Key('meeting_pip_compact_view')), findsNothing);
      expect(
        find.byKey(const Key('meeting_microphone_control')),
        findsOneWidget,
      );
      expect(harness.realtimeClient.resumeCalls, 0);
      expect(harness.realtimeClient.connectCalls, 1);
      expect(harness.realtimeClient.currentSnapshot.isMicOn, isTrue);
      expect(harness.realtimeClient.currentSnapshot.isCameraOn, isTrue);
    });

    testWidgets('PiP dismisses an open chat sheet before compact layout', (
      tester,
    ) async {
      final harness = await _pumpMeetingRoom(tester);
      addTearDown(harness.dispose);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      harness.pipPlatform.emitMode(true);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('meeting_pip_compact_view')), findsOneWidget);
      expect(harness.realtimeClient.connectCalls, 1);
    });

    testWidgets('unsupported PiP falls back to the existing pause behavior', (
      tester,
    ) async {
      final harness = await _pumpMeetingRoom(tester, pipSupported: false);
      addTearDown(harness.dispose);

      expect(
        find.byKey(const Key('meeting_more_actions_button')),
        findsNothing,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 500));
      expect(harness.realtimeClient.pauseCalls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(harness.realtimeClient.resumeCalls, 1);
    });

    testWidgets('dismissing PiP leaves and cleans up the meeting', (
      tester,
    ) async {
      final harness = await _pumpMeetingRoom(tester);
      addTearDown(harness.dispose);
      harness.pipPlatform.emitMode(true);
      await tester.pump();

      harness.pipPlatform.emitDismissed();
      await tester.pump();

      expect(harness.realtimeClient.leaveCalls, 1);
      expect(
        harness.realtimeClient.currentSnapshot.status,
        MeetingConnectionStatus.disconnected,
      );
    });
  });
}

const _room = MeetingRoomReference(
  roomId: '123e4567-e89b-42d3-a456-426614174000',
);

Future<_MeetingRoomHarness> _pumpMeetingRoom(
  WidgetTester tester, {
  bool pipSupported = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final realtimeClient = _FakeMeetingRealtimeClient();
  final pipPlatform = _FakeMeetingPipPlatform(supported: pipSupported);
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(
        TokenStorage(_MemorySecureStore()),
      ),
      mentorMeetingLinkLauncherProvider.overrideWithValue(
        const _FakeMeetingLauncher(),
      ),
      meetingRealtimeClientFactoryProvider.overrideWithValue(
        () => realtimeClient,
      ),
      meetingPipPlatformProvider.overrideWithValue(pipPlatform),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MeetingRoomScreen(room: _room),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return _MeetingRoomHarness(
    container: container,
    room: _room,
    realtimeClient: realtimeClient,
    pipPlatform: pipPlatform,
  );
}

class _MeetingRoomHarness {
  const _MeetingRoomHarness({
    required this.container,
    required this.room,
    required this.realtimeClient,
    required this.pipPlatform,
  });

  final ProviderContainer container;
  final MeetingRoomReference room;
  final _FakeMeetingRealtimeClient realtimeClient;
  final _FakeMeetingPipPlatform pipPlatform;

  void dispose() {
    container.dispose();
  }
}

class _FakeMeetingPipPlatform implements MeetingPipPlatform {
  _FakeMeetingPipPlatform({this.supported = true});

  final bool supported;
  final StreamController<MeetingPipEvent> _events =
      StreamController<MeetingPipEvent>.broadcast(sync: true);
  bool inPip = false;
  int enterCalls = 0;
  final List<bool> autoEnterValues = [];

  @override
  Stream<MeetingPipEvent> get events => _events.stream;

  void emitMode(bool value) {
    inPip = value;
    _events.add(MeetingPipEvent.modeChanged(value));
  }

  void emitDismissed() {
    inPip = false;
    _events.add(const MeetingPipEvent.dismissed());
  }

  @override
  Future<bool> enter() async {
    enterCalls += 1;
    return supported;
  }

  @override
  Future<bool> isInPip() async => inPip;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<void> setAutoEnterEnabled(bool enabled) async {
    autoEnterValues.add(enabled);
  }

  @override
  Future<void> dispose() async {
    if (!_events.isClosed) await _events.close();
  }
}

class _FakeMeetingRealtimeClient implements MeetingRealtimeClient {
  final StreamController<MeetingRealtimeSnapshot> _snapshots =
      StreamController<MeetingRealtimeSnapshot>.broadcast(sync: true);
  MeetingRealtimeSnapshot _snapshot = const MeetingRealtimeSnapshot(
    status: MeetingConnectionStatus.connected,
    self: MeetingParticipant(
      connectionId: 'self',
      userId: 42,
      name: 'Learner',
      role: MeetingParticipantRole.learner,
      isMicOn: true,
      isCameraOn: true,
    ),
    participants: [
      MeetingParticipant(
        connectionId: 'mentor',
        userId: 7,
        name: 'Mentor A',
        role: MeetingParticipantRole.mentor,
        isMicOn: true,
        isCameraOn: true,
      ),
    ],
    isMicOn: true,
    isCameraOn: true,
  );
  int connectCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int leaveCalls = 0;

  @override
  MeetingRealtimeSnapshot get currentSnapshot => _snapshot;

  @override
  Stream<MeetingRealtimeSnapshot> get snapshots => _snapshots.stream;

  @override
  MediaStream? get localStream => null;

  @override
  MediaStream? remoteStreamFor(String connectionId) => null;

  void _emit(MeetingRealtimeSnapshot next) {
    _snapshot = next;
    _snapshots.add(next);
  }

  @override
  Future<void> connect({
    required MeetingRoomReference room,
    required String displayName,
    required MeetingParticipantRole role,
  }) async {
    connectCalls += 1;
    _emit(_snapshot);
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
  }

  @override
  Future<void> resume() async {
    resumeCalls += 1;
  }

  @override
  Future<void> leave() async {
    leaveCalls += 1;
    _emit(
      _snapshot.copyWith(
        status: MeetingConnectionStatus.disconnected,
        participants: const [],
        isMicOn: false,
        isCameraOn: false,
      ),
    );
  }

  @override
  Future<void> sendChatMessage(String text) async {
    _emit(
      _snapshot.copyWith(
        messages: [
          ..._snapshot.messages,
          MeetingMessage(
            id: 'message-${_snapshot.messages.length}',
            sender: 'Learner',
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
  Future<void> switchCamera() async {}

  @override
  Future<void> toggleCamera() async {
    _emit(_snapshot.copyWith(isCameraOn: !_snapshot.isCameraOn));
  }

  @override
  Future<void> toggleMicrophone() async {
    _emit(_snapshot.copyWith(isMicOn: !_snapshot.isMicOn));
  }

  @override
  Future<void> toggleRaiseHand() async {
    _emit(_snapshot.copyWith(isHandRaised: !_snapshot.isHandRaised));
  }

  @override
  Future<void> dispose() async {
    if (!_snapshots.isClosed) await _snapshots.close();
  }
}

class _FakeMeetingLauncher implements MentorMeetingLinkLauncher {
  const _FakeMeetingLauncher();

  @override
  Future<bool> open(Uri uri) async => true;
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
