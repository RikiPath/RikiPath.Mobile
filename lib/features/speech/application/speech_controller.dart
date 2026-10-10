import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/speech/data/api_speech_token_repository.dart';
import 'package:rikipath_mobile/features/speech/data/device_speech_services.dart';
import 'package:rikipath_mobile/features/speech/domain/speech_session.dart';

final speechTokenRepositoryProvider = Provider<SpeechTokenRepository>((ref) {
  return ApiSpeechTokenRepository(ref.watch(apiClientProvider));
});

final speechPermissionGatewayProvider = Provider<SpeechPermissionGateway>((
  ref,
) {
  return RecordSpeechPermissionGateway();
});

final speechRecognitionEngineProvider =
    Provider.autoDispose<SpeechRecognitionEngine>((ref) {
      final engine = AzureSpeechRecognitionEngine();
      ref.onDispose(() => unawaited(engine.dispose()));
      return engine;
    });

final speechControllerProvider =
    NotifierProvider.autoDispose<SpeechController, SpeechSessionState>(
      SpeechController.new,
    );

class SpeechController extends Notifier<SpeechSessionState> {
  Timer? _refreshTimer;
  StreamSubscription<SpeechRecognitionUpdate>? _updatesSubscription;
  String _sessionPrefix = '';
  bool _startInFlight = false;
  int _sessionGeneration = 0;
  late SpeechRecognitionEngine _engine;

  @override
  SpeechSessionState build() {
    _engine = ref.watch(speechRecognitionEngineProvider);
    _updatesSubscription = _engine.updates.listen(_applyUpdate);
    ref.onDispose(() {
      _refreshTimer?.cancel();
      unawaited(_updatesSubscription?.cancel());
      unawaited(_engine.stop());
    });
    return const SpeechSessionState();
  }

  Future<void> start() async {
    if (_startInFlight || state.status == SpeechSessionStatus.listening) return;
    _startInFlight = true;
    final generation = ++_sessionGeneration;
    _refreshTimer?.cancel();
    state = state.copyWith(
      status: SpeechSessionStatus.requestingPermission,
      interimTranscript: '',
    );
    try {
      final granted = await ref
          .read(speechPermissionGatewayProvider)
          .requestMicrophonePermission();
      if (!ref.mounted || generation != _sessionGeneration) return;
      if (!granted) {
        state = state.copyWith(status: SpeechSessionStatus.permissionDenied);
        return;
      }

      state = state.copyWith(status: SpeechSessionStatus.ready);
      final token = await ref.read(speechTokenRepositoryProvider).issueToken();
      if (!ref.mounted || generation != _sessionGeneration) return;
      _sessionPrefix = state.finalizedTranscript.trim();
      await _engine.start(token);
      if (!ref.mounted || generation != _sessionGeneration) {
        await _engine.stop();
        return;
      }
      state = state.copyWith(status: SpeechSessionStatus.listening);
      _scheduleRefresh(token);
    } catch (error) {
      if (!ref.mounted || generation != _sessionGeneration) return;
      state = state.copyWith(status: _statusFor(error));
      await _engine.stop();
    } finally {
      _startInFlight = false;
    }
  }

  Future<void> stop() async {
    if (state.status != SpeechSessionStatus.listening && !_startInFlight) {
      return;
    }
    _sessionGeneration++;
    _startInFlight = false;
    _refreshTimer?.cancel();
    state = state.copyWith(status: SpeechSessionStatus.processing);
    await _engine.stop();
    if (!ref.mounted) return;
    state = SpeechSessionState(
      status: SpeechSessionStatus.completed,
      finalizedTranscript: state.transcript,
    );
    _sessionPrefix = state.finalizedTranscript;
  }

  void clear() {
    if (state.isBusy) return;
    _sessionPrefix = '';
    state = const SpeechSessionState();
  }

  Future<void> retry() async {
    if (state.isBusy) return;
    await start();
  }

  void _applyUpdate(SpeechRecognitionUpdate update) {
    if (!ref.mounted) return;
    state = state.copyWith(
      status: update.isListening ? SpeechSessionStatus.listening : state.status,
      finalizedTranscript: _joinTranscript(
        _sessionPrefix,
        update.finalizedTranscript,
      ),
      interimTranscript: update.interimTranscript,
    );
    if (update.hasProviderError) {
      _refreshTimer?.cancel();
      state = state.copyWith(status: SpeechSessionStatus.providerError);
      unawaited(_engine.stop());
      return;
    }
  }

  void _scheduleRefresh(SpeechToken token) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(token.refreshDelay, _refreshToken);
  }

  Future<void> _refreshToken() async {
    if (!ref.mounted || state.status != SpeechSessionStatus.listening) return;
    _sessionPrefix = state.transcript;
    try {
      final token = await ref.read(speechTokenRepositoryProvider).issueToken();
      if (!ref.mounted || state.status != SpeechSessionStatus.listening) return;
      await _engine.start(token);
      _scheduleRefresh(token);
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(status: _statusFor(error));
      await _engine.stop();
    }
  }

  SpeechSessionStatus _statusFor(Object error) {
    return error is NetworkError
        ? SpeechSessionStatus.networkError
        : SpeechSessionStatus.providerError;
  }
}

String _joinTranscript(String first, String second) {
  return <String>[
    first.trim(),
    second.trim(),
  ].where((part) => part.isNotEmpty).join(' ');
}
