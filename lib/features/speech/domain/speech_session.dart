import 'package:flutter/foundation.dart';

enum SpeechSessionStatus {
  idle,
  requestingPermission,
  ready,
  listening,
  processing,
  completed,
  permissionDenied,
  networkError,
  providerError,
}

@immutable
class SpeechToken {
  const SpeechToken({
    required this.value,
    required this.region,
    required this.language,
    required this.expiresInSeconds,
  });

  final String value;
  final String region;
  final String language;
  final int expiresInSeconds;

  Duration get refreshDelay {
    final seconds = expiresInSeconds > 60
        ? expiresInSeconds - 60
        : (expiresInSeconds ~/ 2).clamp(1, expiresInSeconds);
    return Duration(seconds: seconds);
  }
}

@immutable
class SpeechRecognitionUpdate {
  const SpeechRecognitionUpdate({
    this.finalizedTranscript = '',
    this.interimTranscript = '',
    this.isListening = false,
    this.hasProviderError = false,
  });

  final String finalizedTranscript;
  final String interimTranscript;
  final bool isListening;
  final bool hasProviderError;
}

@immutable
class SpeechSessionState {
  const SpeechSessionState({
    this.status = SpeechSessionStatus.idle,
    this.finalizedTranscript = '',
    this.interimTranscript = '',
  });

  final SpeechSessionStatus status;
  final String finalizedTranscript;
  final String interimTranscript;

  bool get isBusy => switch (status) {
    SpeechSessionStatus.requestingPermission ||
    SpeechSessionStatus.ready ||
    SpeechSessionStatus.listening ||
    SpeechSessionStatus.processing => true,
    _ => false,
  };

  String get transcript => <String>[
    finalizedTranscript.trim(),
    interimTranscript.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  SpeechSessionState copyWith({
    SpeechSessionStatus? status,
    String? finalizedTranscript,
    String? interimTranscript,
  }) {
    return SpeechSessionState(
      status: status ?? this.status,
      finalizedTranscript: finalizedTranscript ?? this.finalizedTranscript,
      interimTranscript: interimTranscript ?? this.interimTranscript,
    );
  }
}

abstract interface class SpeechTokenRepository {
  Future<SpeechToken> issueToken();
}

abstract interface class SpeechPermissionGateway {
  Future<bool> requestMicrophonePermission();
}

abstract interface class SpeechRecognitionEngine {
  Stream<SpeechRecognitionUpdate> get updates;

  Future<void> start(SpeechToken token);

  Future<void> stop();

  Future<void> dispose();
}
