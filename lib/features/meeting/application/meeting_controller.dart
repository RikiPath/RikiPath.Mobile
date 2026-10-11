import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;
import 'package:rikipath_mobile/core/config/app_config.dart';
import 'package:rikipath_mobile/core/storage/token_storage.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/meeting_realtime_client.dart';
import 'package:rikipath_mobile/features/meeting/data/realtime/signalr_meeting_realtime_client.dart';
import 'package:rikipath_mobile/features/meeting/domain/meeting_room.dart';
import 'package:rikipath_mobile/features/meeting/domain/participant_role.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_meeting_link_launcher.dart';

typedef MeetingRealtimeClientFactory = MeetingRealtimeClient Function();

final meetingRealtimeClientFactoryProvider =
    Provider<MeetingRealtimeClientFactory>((ref) {
      final config = ref.watch(appConfigProvider);
      final tokenStorage = ref.watch(tokenStorageProvider);
      final hubUri = config.apiBaseUrl.replace(
        path: '/hubs/mentor-meeting',
        query: null,
        fragment: null,
      );
      return () => SignalRMeetingRealtimeClient(
        hubUri: hubUri,
        tokenStorage: tokenStorage,
      );
    });

final meetingControllerProvider = ChangeNotifierProvider.autoDispose
    .family<MeetingController, MeetingRoomReference>((ref, room) {
      final controller = MeetingController(
        room: room,
        client: ref.watch(meetingRealtimeClientFactoryProvider)(),
        tokenStorage: ref.watch(tokenStorageProvider),
        browserLauncher: ref.watch(mentorMeetingLinkLauncherProvider),
      );
      unawaited(controller.start());
      return controller;
    });

class MeetingController extends ChangeNotifier {
  MeetingController({
    required this.room,
    required MeetingRealtimeClient client,
    required this.tokenStorage,
    required this.browserLauncher,
  }) : _client = client,
       _state = client.currentSnapshot {
    _subscription = _client.snapshots.listen((snapshot) {
      _state = snapshot;
      notifyListeners();
    });
  }

  final MeetingRoomReference room;
  final MeetingRealtimeClient _client;
  final TokenStorage tokenStorage;
  final MentorMeetingLinkLauncher browserLauncher;
  late final StreamSubscription<MeetingRealtimeSnapshot> _subscription;
  MeetingRealtimeSnapshot _state;
  bool _isDisposed = false;
  bool _isStarting = false;

  MeetingRealtimeSnapshot get state => _state;

  MeetingRealtimeClient get media => _client;

  Future<void> start() async {
    if (_isStarting || _isDisposed) return;
    _isStarting = true;
    try {
      final storedRole = await tokenStorage.readAuthenticatedRole();
      final role = MeetingParticipantRole.fromApi(storedRole);
      await _client.connect(room: room, displayName: 'RikiPath', role: role);
    } catch (_) {
      // The realtime client emits a sanitized failed state for presentation.
    } finally {
      _isStarting = false;
    }
  }

  Future<void> retry() => start();

  Future<void> toggleMicrophone() => _client.toggleMicrophone();

  Future<void> toggleCamera() => _client.toggleCamera();

  Future<void> switchCamera() => _client.switchCamera();

  Future<void> toggleRaiseHand() => _client.toggleRaiseHand();

  Future<void> sendChatMessage(String text) => _client.sendChatMessage(text);

  Future<void> pause() => _client.pause();

  Future<void> resume() => _client.resume();

  Future<void> leave() => _client.leave();

  Future<bool> openBrowserFallback() async {
    final uri = room.webUri;
    if (uri == null) return false;
    return browserLauncher.open(uri);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    unawaited(_subscription.cancel());
    unawaited(_client.dispose());
    super.dispose();
  }
}
