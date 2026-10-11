import 'dart:async';

import 'package:flutter/services.dart';

enum MeetingPipEventType { modeChanged, dismissed }

class MeetingPipEvent {
  const MeetingPipEvent.modeChanged(this.isInPip)
    : type = MeetingPipEventType.modeChanged;

  const MeetingPipEvent.dismissed()
    : type = MeetingPipEventType.dismissed,
      isInPip = false;

  final MeetingPipEventType type;
  final bool isInPip;
}

abstract interface class MeetingPipPlatform {
  Stream<MeetingPipEvent> get events;

  Future<bool> isSupported();

  Future<bool> isInPip();

  Future<void> setAutoEnterEnabled(bool enabled);

  Future<bool> enter();

  Future<void> dispose();
}

class MethodChannelMeetingPipPlatform implements MeetingPipPlatform {
  MethodChannelMeetingPipPlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const _channelName = 'com.rikipath.rikipath_mobile/meeting_pip';

  final MethodChannel _channel;
  final StreamController<MeetingPipEvent> _events =
      StreamController<MeetingPipEvent>.broadcast(sync: true);
  bool _disposed = false;

  @override
  Stream<MeetingPipEvent> get events => _events.stream;

  @override
  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> isInPip() async {
    try {
      return await _channel.invokeMethod<bool>('isInPip') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> setAutoEnterEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setAutoEnterEnabled', {
        'enabled': enabled,
      });
    } on PlatformException {
      // Unsupported devices keep the existing fullscreen lifecycle behavior.
    } on MissingPluginException {
      // Non-Android hosts do not provide the native PiP bridge.
    }
  }

  @override
  Future<bool> enter() async {
    try {
      return await _channel.invokeMethod<bool>('enter') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (_disposed) return;
    switch (call.method) {
      case 'onPipModeChanged':
        final arguments = call.arguments;
        final isInPip = arguments is Map ? arguments['isInPip'] == true : false;
        _events.add(MeetingPipEvent.modeChanged(isInPip));
      case 'onPipDismissed':
        _events.add(const MeetingPipEvent.dismissed());
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _channel.setMethodCallHandler(null);
    await _events.close();
  }
}
