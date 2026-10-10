import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/speech/application/speech_controller.dart';
import 'package:rikipath_mobile/features/speech/data/api_speech_token_repository.dart';
import 'package:rikipath_mobile/features/speech/data/speech_api_paths.dart';
import 'package:rikipath_mobile/features/speech/data/speech_token_dto.dart';
import 'package:rikipath_mobile/features/speech/domain/speech_session.dart';

void main() {
  const token = SpeechToken(
    value: 'temporary-token',
    region: 'southeastasia',
    language: 'ja-JP',
    expiresInSeconds: 600,
  );

  group('Speech token contract', () {
    test('maps the exact source-backed response fields', () {
      final dto = SpeechTokenDto.fromEnvelope(_tokenEnvelope());

      expect(dto.token, token.value);
      expect(dto.region, token.region);
      expect(dto.language, token.language);
      expect(dto.expiresInSeconds, token.expiresInSeconds);
      expect(dto.toDomain().refreshDelay, const Duration(minutes: 9));
    });

    test('refreshes short-lived tokens before they expire', () {
      const shortLivedToken = SpeechToken(
        value: 'temporary-token',
        region: 'southeastasia',
        language: 'ja-JP',
        expiresInSeconds: 10,
      );

      expect(shortLivedToken.refreshDelay, const Duration(seconds: 5));
    });

    test('rejects a missing or invalid token TTL', () {
      final envelope = _tokenEnvelope();
      final result = envelope['result']! as Map<String, Object?>;
      result['expiresInSeconds'] = 0;

      expect(
        () => SpeechTokenDto.fromEnvelope(envelope),
        throwsFormatException,
      );
    });

    test('repository uses the verified authenticated token route', () async {
      final client = _SpeechApiClient(_tokenEnvelope());
      final repository = ApiSpeechTokenRepository(client);

      final result = await repository.issueToken();

      expect(client.lastPath, SpeechApiPaths.token);
      expect(result.value, token.value);
    });
  });

  group('Speech controller', () {
    test('reports permission denied without requesting a token', () async {
      final repository = _SpeechTokenRepository(token);
      final engine = _SpeechEngine();
      final container = _container(
        repository: repository,
        permission: const _SpeechPermission(false),
        engine: engine,
      );

      await container.read(speechControllerProvider.notifier).start();

      expect(
        container.read(speechControllerProvider).status,
        SpeechSessionStatus.permissionDenied,
      );
      expect(repository.calls, 0);
      expect(engine.startCalls, 0);
    });

    test('starts once, streams transcript, and stops cleanly', () async {
      final engine = _SpeechEngine();
      final container = _container(
        repository: _SpeechTokenRepository(token),
        permission: const _SpeechPermission(true),
        engine: engine,
      );
      final controller = container.read(speechControllerProvider.notifier);

      await controller.start();
      engine.emit(
        const SpeechRecognitionUpdate(
          finalizedTranscript: '日本語を',
          interimTranscript: '勉強します',
          isListening: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(speechControllerProvider).transcript, '日本語を 勉強します');
      await controller.stop();
      expect(
        container.read(speechControllerProvider).status,
        SpeechSessionStatus.completed,
      );
      expect(engine.stopCalls, 1);
    });

    test('prevents duplicate start taps', () async {
      final engine = _SpeechEngine();
      final permission = _DeferredPermission();
      final container = _container(
        repository: _SpeechTokenRepository(token),
        permission: permission,
        engine: engine,
      );
      final controller = container.read(speechControllerProvider.notifier);

      final first = controller.start();
      final second = controller.start();
      permission.complete(true);
      await Future.wait(<Future<void>>[first, second]);

      expect(engine.startCalls, 1);
    });

    test('classifies token transport failure as network error', () async {
      final container = _container(
        repository: _SpeechTokenRepository(token, error: const NetworkError()),
        permission: const _SpeechPermission(true),
        engine: _SpeechEngine(),
      );

      await container.read(speechControllerProvider.notifier).start();

      expect(
        container.read(speechControllerProvider).status,
        SpeechSessionStatus.networkError,
      );
    });

    test('provider stream failure preserves recognized transcript', () async {
      final engine = _SpeechEngine();
      final container = _container(
        repository: _SpeechTokenRepository(token),
        permission: const _SpeechPermission(true),
        engine: engine,
      );
      await container.read(speechControllerProvider.notifier).start();
      engine.emit(
        const SpeechRecognitionUpdate(
          finalizedTranscript: '桜が好きです。',
          hasProviderError: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(speechControllerProvider);
      expect(state.status, SpeechSessionStatus.providerError);
      expect(state.transcript, '桜が好きです。');
    });
  });
}

ProviderContainer _container({
  required SpeechTokenRepository repository,
  required SpeechPermissionGateway permission,
  required SpeechRecognitionEngine engine,
}) {
  final container = ProviderContainer(
    overrides: [
      speechTokenRepositoryProvider.overrideWithValue(repository),
      speechPermissionGatewayProvider.overrideWithValue(permission),
      speechRecognitionEngineProvider.overrideWithValue(engine),
    ],
  );
  final subscription = container.listen(
    speechControllerProvider,
    (_, _) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);
  addTearDown(container.dispose);
  return container;
}

Map<String, Object?> _tokenEnvelope() => <String, Object?>{
  'statusCode': 200,
  'isSuccess': true,
  'result': <String, Object?>{
    'token': 'temporary-token',
    'region': 'southeastasia',
    'language': 'ja-JP',
    'expiresInSeconds': 600,
  },
};

class _SpeechApiClient extends ApiClient {
  _SpeechApiClient(this.body) : super(Dio(), const ApiErrorMapper());

  final Object? body;
  String? lastPath;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: body as T,
    );
  }
}

class _SpeechTokenRepository implements SpeechTokenRepository {
  _SpeechTokenRepository(this.token, {this.error});

  final SpeechToken token;
  final Object? error;
  int calls = 0;

  @override
  Future<SpeechToken> issueToken() async {
    calls++;
    if (error != null) throw error!;
    return token;
  }
}

class _SpeechPermission implements SpeechPermissionGateway {
  const _SpeechPermission(this.granted);

  final bool granted;

  @override
  Future<bool> requestMicrophonePermission() async => granted;
}

class _DeferredPermission implements SpeechPermissionGateway {
  final Completer<bool> _completer = Completer<bool>();

  void complete(bool value) => _completer.complete(value);

  @override
  Future<bool> requestMicrophonePermission() => _completer.future;
}

class _SpeechEngine implements SpeechRecognitionEngine {
  final StreamController<SpeechRecognitionUpdate> _updates =
      StreamController<SpeechRecognitionUpdate>.broadcast();
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Stream<SpeechRecognitionUpdate> get updates => _updates.stream;

  void emit(SpeechRecognitionUpdate update) => _updates.add(update);

  @override
  Future<void> start(SpeechToken token) async {
    startCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {
    if (!_updates.isClosed) await _updates.close();
  }
}
