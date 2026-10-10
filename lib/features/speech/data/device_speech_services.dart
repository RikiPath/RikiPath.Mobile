import 'dart:async';

import 'package:azure_speech_services/azure_speech_services.dart';
import 'package:record/record.dart';
import 'package:rikipath_mobile/features/speech/domain/speech_session.dart';

class RecordSpeechPermissionGateway implements SpeechPermissionGateway {
  @override
  Future<bool> requestMicrophonePermission() async {
    final recorder = AudioRecorder();
    try {
      return await recorder.hasPermission();
    } finally {
      await recorder.dispose();
    }
  }
}

class AzureSpeechRecognitionEngine implements SpeechRecognitionEngine {
  final StreamController<SpeechRecognitionUpdate> _updates =
      StreamController<SpeechRecognitionUpdate>.broadcast();

  AzureSpeechToText? _client;
  StreamSubscription<TranscriptionState>? _subscription;
  bool _disposed = false;

  @override
  Stream<SpeechRecognitionUpdate> get updates => _updates.stream;

  @override
  Future<void> start(SpeechToken token) async {
    if (_disposed) return;
    await _disposeSession();

    final client = AzureSpeechToText(
      config: AzureSpeechConfig.authorizationToken(
        region: token.region,
        token: token.value,
      ),
      sttConfig: SpeechToTextConfig(
        languages: <String>[token.language],
        // RikiPath owns transcript clearing. Keep the package from erasing a
        // learner's confirmed result during a natural speaking pause.
        textClearTimeout: const Duration(hours: 1),
      ),
    );
    _client = client;
    _subscription = client.stream.listen((state) {
      if (_disposed) return;
      _updates.add(
        SpeechRecognitionUpdate(
          finalizedTranscript: state.finalizedText.join(' ').trim(),
          interimTranscript: state.intermediateText.trim(),
          isListening: state.isListening,
          hasProviderError: state.error != null,
        ),
      );
    });
    await client.start();
  }

  @override
  Future<void> stop() async {
    await _client?.stop();
  }

  Future<void> _disposeSession() async {
    await _subscription?.cancel();
    _subscription = null;
    final client = _client;
    _client = null;
    await client?.dispose();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _disposeSession();
    await _updates.close();
  }
}
