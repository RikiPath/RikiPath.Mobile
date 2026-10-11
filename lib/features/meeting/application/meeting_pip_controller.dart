import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;
import 'package:rikipath_mobile/features/meeting/data/platform/meeting_pip_platform.dart';

@immutable
class MeetingPipState {
  const MeetingPipState({
    this.isInitialized = false,
    this.isSupported = false,
    this.isEligible = false,
    this.isInPip = false,
  });

  final bool isInitialized;
  final bool isSupported;
  final bool isEligible;
  final bool isInPip;

  MeetingPipState copyWith({
    bool? isInitialized,
    bool? isSupported,
    bool? isEligible,
    bool? isInPip,
  }) {
    return MeetingPipState(
      isInitialized: isInitialized ?? this.isInitialized,
      isSupported: isSupported ?? this.isSupported,
      isEligible: isEligible ?? this.isEligible,
      isInPip: isInPip ?? this.isInPip,
    );
  }
}

final meetingPipPlatformProvider = Provider.autoDispose<MeetingPipPlatform>(
  (ref) => MethodChannelMeetingPipPlatform(),
);

final meetingPipControllerProvider =
    ChangeNotifierProvider.autoDispose<MeetingPipController>((ref) {
      return MeetingPipController(ref.watch(meetingPipPlatformProvider));
    });

class MeetingPipController extends ChangeNotifier {
  MeetingPipController(this._platform);

  final MeetingPipPlatform _platform;
  final StreamController<void> _dismissals = StreamController<void>.broadcast(
    sync: true,
  );
  StreamSubscription<MeetingPipEvent>? _eventSubscription;
  Future<void>? _initializeFuture;
  MeetingPipState _state = const MeetingPipState();
  bool _disposed = false;

  MeetingPipState get state => _state;

  Stream<void> get dismissals => _dismissals.stream;

  Future<void> initialize() {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    _eventSubscription ??= _platform.events.listen(_handleEvent);
    final supported = await _platform.isSupported();
    final isInPip = supported && await _platform.isInPip();
    if (_disposed) return;
    _setState(
      _state.copyWith(
        isInitialized: true,
        isSupported: supported,
        isInPip: isInPip,
      ),
    );
    if (supported) {
      await _platform.setAutoEnterEnabled(_state.isEligible);
    }
  }

  Future<void> setEligible(bool eligible) async {
    if (_state.isEligible != eligible) {
      _setState(_state.copyWith(isEligible: eligible));
    }
    await initialize();
    if (_disposed || !_state.isSupported) return;
    await _platform.setAutoEnterEnabled(eligible);
  }

  Future<bool> enter() async {
    await initialize();
    if (_disposed || !_state.isSupported || !_state.isEligible) return false;
    return _platform.enter();
  }

  Future<void> refreshMode() async {
    await initialize();
    if (_disposed || !_state.isSupported) return;
    final isInPip = await _platform.isInPip();
    if (_disposed || isInPip == _state.isInPip) return;
    _setState(_state.copyWith(isInPip: isInPip));
  }

  void _handleEvent(MeetingPipEvent event) {
    if (_disposed) return;
    switch (event.type) {
      case MeetingPipEventType.modeChanged:
        if (_state.isInPip != event.isInPip) {
          _setState(_state.copyWith(isInPip: event.isInPip));
        }
      case MeetingPipEventType.dismissed:
        if (_state.isInPip) {
          _setState(_state.copyWith(isInPip: false));
        }
        _dismissals.add(null);
    }
  }

  void _setState(MeetingPipState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_eventSubscription?.cancel());
    unawaited(_dismissals.close());
    unawaited(_platform.dispose());
    super.dispose();
  }
}
