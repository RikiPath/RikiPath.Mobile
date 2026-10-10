import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/writing_practice/application/writing_practice_controller.dart';
import 'package:rikipath_mobile/features/writing_practice/data/api_writing_practice_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/data/writing_api_paths.dart';
import 'package:rikipath_mobile/features/writing_practice/data/writing_dtos.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/writing_practice_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/engine/writing_practice_engine.dart';
import 'package:rikipath_mobile/features/writing_practice/engine/writing_stroke_data_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/presentation/writing_practice_detail_screen.dart';
import 'package:rikipath_mobile/features/writing_practice/presentation/writing_practice_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_json_preference_store.dart';

void main() {
  const kana = WritingCharacter(
    id: 101,
    character: 'あ',
    script: WritingScript.hiragana,
    strokeCount: 3,
    isNew: true,
    romaji: 'a',
  );
  const kanji = WritingCharacter(
    id: 910005,
    character: '木',
    script: WritingScript.kanji,
    strokeCount: 4,
    isNew: false,
    meaning: 'Cây; gỗ',
    onYomi: 'モク',
    kunYomi: 'き',
  );
  const result = WritingPracticeResult(
    totalMistakes: 1,
    correctStrokeCount: 3,
    totalStrokeCount: 4,
  );

  group('Writing contract DTOs', () {
    test('parses the exact Kana queue fields and enum', () {
      final dto = KanaWritingQueueItemDto.fromJson(
        _kanaQueueItem(id: 101, type: 'Hiragana'),
      );

      expect(dto.kanaCharacterId, 101);
      expect(dto.type, WritingScript.hiragana);
      expect(dto.toDomain().romaji, 'a');
      expect(dto.toDomain().strokeOrderImageUrl, isNull);
    });

    test('parses nullable Kanji fields and verified mode values', () {
      final dto = KanjiWritingQueueItemDto.fromJson(_kanjiQueueItem());

      expect(dto.kanjiId, 910005);
      expect(dto.writingPracticeMode, WritingPracticeMode.free);
      expect(dto.toDomain().writingScore, 50);
    });

    test('keeps unknown nullable practice mode non-authoritative', () {
      final dto = KanjiWritingQueueItemDto.fromJson(<String, Object?>{
        ..._kanjiQueueItem(),
        'writingPracticeMode': 'future-mode',
      });

      expect(dto.writingPracticeMode, isNull);
      expect(
        () => KanaWritingQueueItemDto.fromJson(
          _kanaQueueItem(id: 101, type: 'Unknown'),
        ),
        throwsFormatException,
      );
    });

    test('rejects zero identifiers instead of inventing local API ids', () {
      expect(
        () => KanaWritingQueueItemDto.fromJson(
          _kanaQueueItem(id: 0, type: 'Katakana'),
        ),
        throwsFormatException,
      );
      expect(
        () => KanjiWritingQueueItemDto.fromJson(<String, Object?>{
          ..._kanjiQueueItem(),
          'kanjiId': -1,
        }),
        throwsFormatException,
      );
    });

    test('maps both submission response shapes', () {
      final kanaReceipt = KanaWritingSubmissionDto.fromJson(
        _kanaSubmissionResult(),
      ).toDomain();
      final kanjiReceipt = KanjiWritingSubmissionDto.fromJson(
        _kanjiSubmissionResult(),
      ).toDomain(kanji.id);

      expect(kanaReceipt.characterId, kana.id);
      expect(kanaReceipt.score, isNull);
      expect(kanjiReceipt.characterId, kanji.id);
      expect(kanjiReceipt.score, 90);
    });

    test('uses the Web-verified score formula with safe bounds', () {
      expect(result.scoreFor(kanji.strokeCount), 90);
      expect(
        const WritingPracticeResult(
          totalMistakes: 99,
          correctStrokeCount: 0,
          totalStrokeCount: 1,
        ).scoreFor(1),
        0,
      );
    });
  });

  group('Writing API repository', () {
    test('loads Hiragana with the exact route and query', () async {
      final client = _RecordingWritingApiClient(<String, Object?>{
        'GET ${WritingApiPaths.kanaDue}': _envelope(<Object?>[
          _kanaQueueItem(id: kana.id, type: 'Hiragana'),
        ]),
      });
      final repository = ApiWritingPracticeRepository(client);

      final items = await repository.loadQueue(
        const WritingQueueRequest(script: WritingScript.hiragana),
      );

      expect(items.single.id, kana.id);
      expect(client.lastQuery, <String, Object?>{
        'count': 100,
        'type': 'Hiragana',
      });
    });

    test('loads all Kanji without adding an invented type filter', () async {
      final client = _RecordingWritingApiClient(<String, Object?>{
        'GET ${WritingApiPaths.kanjiAll}': _envelope(<Object?>[
          _kanjiQueueItem(),
        ]),
      });
      final repository = ApiWritingPracticeRepository(client);

      final items = await repository.loadQueue(
        const WritingQueueRequest(
          script: WritingScript.kanji,
          kanjiCollection: KanjiWritingCollection.all,
        ),
      );

      expect(items.single.id, kanji.id);
      expect(client.lastQuery, <String, Object?>{'count': 100});
    });

    test('loads due Kanji from the exact route', () async {
      final client = _RecordingWritingApiClient(<String, Object?>{
        'GET ${WritingApiPaths.kanjiDue}': _envelope(<Object?>[
          _kanjiQueueItem(),
        ]),
      });
      final repository = ApiWritingPracticeRepository(client);

      final items = await repository.loadQueue(
        const WritingQueueRequest(script: WritingScript.kanji),
      );

      expect(items.single.id, kanji.id);
      expect(client.lastPath, WritingApiPaths.kanjiDue);
    });

    test('loads and maps Kanji scores from the exact route', () async {
      final client = _RecordingWritingApiClient(<String, Object?>{
        'GET ${WritingApiPaths.kanjiScores}': _envelope(<Object?>[
          <String, Object?>{
            'kanjiId': kanji.id,
            'score': 90,
            'correctStrokeCount': 3,
            'totalStrokeCount': 4,
            'practiceMode': 'free',
            'completedAt': '2026-10-09T00:00:00Z',
          },
        ]),
      });
      final repository = ApiWritingPracticeRepository(client);

      final scores = await repository.loadKanjiScores();

      expect(scores.single.practiceMode, WritingPracticeMode.free);
      expect(client.lastPath, WritingApiPaths.kanjiScores);
    });

    test('submits the exact Kana body', () async {
      final client = _RecordingWritingApiClient(<String, Object?>{
        'POST ${WritingApiPaths.kanaSubmit}': _envelope(
          _kanaSubmissionResult(),
        ),
      });
      final repository = ApiWritingPracticeRepository(client);

      await repository.submitKana(character: kana, result: result);

      expect(client.lastData, <String, Object?>{
        'kanaCharacterId': kana.id,
        'totalMistakes': 1,
      });
    });

    test('submits exact Kanji metrics and lowercase mode', () async {
      final client = _RecordingWritingApiClient(<String, Object?>{
        'POST ${WritingApiPaths.kanjiSubmit}': _envelope(
          _kanjiSubmissionResult(),
        ),
      });
      final repository = ApiWritingPracticeRepository(client);

      await repository.submitKanji(
        character: kanji,
        result: result,
        mode: WritingPracticeMode.free,
      );

      expect(client.lastData, <String, Object?>{
        'kanjiId': kanji.id,
        'totalMistakes': 1,
        'score': 90,
        'correctStrokeCount': 3,
        'totalStrokeCount': 4,
        'practiceMode': 'free',
      });
    });
  });

  group('Writing engine', () {
    test('loads, animates, starts quiz, resets, and disposes', () async {
      final engine = NativeWritingPracticeEngine(
        const _StrokeDataRepository(_singleStrokeJson),
        const TestVSync(),
      );

      await engine.loadCharacter(character: '木', script: WritingScript.kanji);
      expect(engine.snapshot.phase, WritingEnginePhase.ready);
      expect(engine.snapshot.totalStrokeCount, 1);

      engine.showStrokeAnimation();
      expect(engine.snapshot.phase, WritingEnginePhase.animating);
      engine.startQuiz(guided: true);
      expect(engine.snapshot.phase, WritingEnginePhase.quizzing);
      engine.reset();
      expect(engine.snapshot.phase, WritingEnginePhase.ready);
      engine.dispose();
      expect(engine.snapshot.phase, WritingEnginePhase.disposed);
    });

    test('maps quiz mistakes into a bounded domain result', () {
      final summary = QuizSummary(3)..mistakes = <int>[0, 2, 1];

      final mapped = writingPracticeResultFromQuiz(summary);

      expect(mapped.totalMistakes, 3);
      expect(mapped.correctStrokeCount, 0);
      expect(mapped.totalStrokeCount, 3);
    });

    test('publishes a failure when stroke data is unavailable', () async {
      final engine = NativeWritingPracticeEngine(
        const _ThrowingStrokeDataRepository(),
        const TestVSync(),
      );
      addTearDown(engine.dispose);

      await engine.loadCharacter(character: '木', script: WritingScript.kanji);

      expect(engine.snapshot.phase, WritingEnginePhase.failed);
      expect(engine.snapshot.error, isA<StateError>());
    });

    test('uses cached stroke data without a network dependency', () async {
      final store = TestJsonPreferenceStore(
        initialValues: const <String, String>{
          'writing.stroke.v1.kanji.6728': _singleStrokeJson,
        },
      );
      final repository = CachedNetworkWritingStrokeDataRepository(Dio(), store);

      final raw = await repository.load(
        character: '木',
        script: WritingScript.kanji,
      );

      expect(raw, _singleStrokeJson);
      expect(store.readCount, 1);
      expect(store.writeCount, 0);
    });
  });

  group('Writing controller', () {
    test('submits completion once even when callback repeats', () async {
      final repository = _DeferredWritingRepository(<WritingCharacter>[kanji]);
      final harness = _controllerHarness(repository);
      await harness.ready;
      harness.controller.selectCharacter(kanji.id);

      final first = harness.controller.completePractice(result);
      final second = harness.controller.completePractice(result);
      repository.completeSubmit(_receipt(kanji.id));
      await Future.wait(<Future<WritingSubmissionReceipt?>>[first, second]);

      expect(repository.kanjiSubmitCalls, 1);
      expect(harness.value.submissionStatus, WritingSubmissionStatus.succeeded);
    });

    test('retains a local result after failure and retries safely', () async {
      final repository = _FakeWritingRepository(<WritingCharacter>[
        kana,
      ], failuresBeforeSuccess: 1);
      final harness = _controllerHarness(repository);
      await harness.ready;
      harness.controller.selectCharacter(kana.id);

      await harness.controller.completePractice(result);
      expect(harness.value.submissionStatus, WritingSubmissionStatus.failed);
      expect(harness.value.localResult, same(result));

      await harness.controller.retrySubmission();
      expect(harness.value.submissionStatus, WritingSubmissionStatus.succeeded);
      expect(repository.kanaSubmitCalls, 2);
    });

    test('retries a failed queue load without provider auto-retry', () async {
      final repository = _RetryQueueRepository(<WritingCharacter>[kanji]);
      final harness = _controllerHarness(repository);

      await expectLater(harness.ready, throwsStateError);
      expect(
        harness.container.read(
          writingPracticeControllerProvider(harness.request),
        ),
        isA<AsyncError<WritingPracticeState>>(),
      );

      await harness.controller.retry();
      expect(harness.value.items.single.id, kanji.id);
      expect(repository.loadCalls, 2);
    });

    test(
      'ignores unknown ids, advances by API order, and resets result',
      () async {
        const secondKana = WritingCharacter(
          id: 102,
          character: 'い',
          script: WritingScript.hiragana,
          strokeCount: 2,
          isNew: false,
          romaji: 'i',
        );
        final repository = _FakeWritingRepository(<WritingCharacter>[
          kana,
          secondKana,
        ]);
        final harness = _controllerHarness(repository);
        await harness.ready;

        harness.controller.selectCharacter(999999);
        expect(harness.value.selectedCharacterId, isNull);
        harness.controller.selectCharacter(kana.id);
        await harness.controller.completePractice(result);
        harness.controller.resetPractice();
        expect(harness.value.localResult, isNull);
        expect(harness.controller.selectNextCharacter(), secondKana.id);
        expect(harness.value.selectedCharacterId, secondKana.id);
      },
    );
  });

  group('Writing presentation states', () {
    testWidgets('shows a non-empty list using backend item ids', (
      tester,
    ) async {
      await _pumpWriting(
        tester,
        repository: _FakeWritingRepository(<WritingCharacter>[kana]),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('writing_character_101')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the Katakana grid from API-backed items', (
      tester,
    ) async {
      const katakana = WritingCharacter(
        id: 201,
        character: 'ア',
        script: WritingScript.katakana,
        strokeCount: 2,
        isNew: true,
        romaji: 'a',
      );
      await _pumpWriting(
        tester,
        script: WritingScript.katakana,
        repository: _FakeWritingRepository(const <WritingCharacter>[katakana]),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('writing_character_201')),
        findsOneWidget,
      );
    });

    testWidgets('distinguishes loading, empty, and error states', (
      tester,
    ) async {
      final deferred = _DeferredQueueRepository();
      await _pumpWriting(tester, repository: deferred);
      await tester.pump();
      expect(find.byType(RikiSectionSkeleton), findsOneWidget);

      deferred.complete(const <WritingCharacter>[]);
      await tester.pumpAndSettle();
      expect(find.byType(RikiEmptyState), findsOneWidget);

      await _pumpWriting(
        tester,
        repository: _FakeWritingRepository(
          const <WritingCharacter>[],
          loadError: StateError('offline'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RikiErrorState), findsOneWidget);
    });

    testWidgets('router reaches the authenticated Kanji writing route', (
      tester,
    ) async {
      final repository = _FakeWritingRepository(<WritingCharacter>[kanji]);
      final container = ProviderContainer(
        overrides: [
          writingPracticeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final session = createTestAuthSession();
      final router = createAppRouter(
        authSession: session,
        initialLocation: AppRoutes.writingKanji,
      );
      addTearDown(container.dispose);
      addTearDown(session.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _localizedRouter(router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WritingPracticeScreen), findsOneWidget);
      expect(
        tester
            .widget<WritingPracticeScreen>(find.byType(WritingPracticeScreen))
            .script,
        WritingScript.kanji,
      );
      expect(
        find.byKey(const ValueKey<String>('writing_character_910005')),
        findsOneWidget,
      );
    });

    testWidgets('writing detail fits a 320px phone with the native engine', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          writingPracticeRepositoryProvider.overrideWithValue(
            _FakeWritingRepository(<WritingCharacter>[kanji]),
          ),
          writingStrokeDataRepositoryProvider.overrideWithValue(
            const _StrokeDataRepository(_singleStrokeJson),
          ),
        ],
      );
      final session = createTestAuthSession();
      final router = createAppRouter(
        authSession: session,
        initialLocation: AppRoutes.writingKanjiDetail(kanji.id),
      );
      addTearDown(container.dispose);
      addTearDown(session.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _localizedRouter(router),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('writing_detail_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('writing_engine_木')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Writing canvas gesture ownership', () {
    testWidgets('locks on canvas down and unlocks on pointer up', (
      tester,
    ) async {
      await _pumpWritingDetail(tester, character: kanji);

      final gesture = await tester.startGesture(
        tester.getCenter(_writingCanvasFinder),
      );
      await tester.pump();
      expect(
        _writingDetailPhysics(tester),
        isA<NeverScrollableScrollPhysics>(),
      );

      await gesture.up();
      await tester.pump();
      expect(
        _writingDetailPhysics(tester),
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
    });

    testWidgets('unlocks when the active canvas pointer is cancelled', (
      tester,
    ) async {
      await _pumpWritingDetail(tester, character: kanji);

      final gesture = await tester.startGesture(
        tester.getCenter(_writingCanvasFinder),
      );
      await tester.pump();
      expect(
        _writingDetailPhysics(tester),
        isA<NeverScrollableScrollPhysics>(),
      );

      await gesture.cancel();
      await tester.pump();
      expect(
        _writingDetailPhysics(tester),
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
    });

    testWidgets('vertical and diagonal canvas strokes never move the page', (
      tester,
    ) async {
      await _pumpWritingDetail(tester, character: kanji);
      final scrollable = _writingDetailScrollable(tester);
      final initialOffset = scrollable.position.pixels;

      final verticalGesture = await tester.startGesture(
        tester.getCenter(_writingCanvasFinder),
      );
      await tester.pump();
      await verticalGesture.moveBy(const Offset(0, -110));
      await tester.pump();
      expect(scrollable.position.pixels, initialOffset);
      await verticalGesture.up();
      await tester.pump();

      final diagonalGesture = await tester.startGesture(
        tester.getCenter(_writingCanvasFinder),
      );
      await tester.pump();
      await diagonalGesture.moveBy(const Offset(70, -100));
      await tester.pump();
      expect(scrollable.position.pixels, initialOffset);
      await diagonalGesture.up();
    });

    testWidgets('a gesture starting outside the canvas scrolls normally', (
      tester,
    ) async {
      await _pumpWritingDetail(tester, character: kanji);
      final scrollable = _writingDetailScrollable(tester);
      final canvasTopLeft = tester.getTopLeft(_writingCanvasFinder);
      final gesture = await tester.startGesture(
        canvasTopLeft + const Offset(12, -12),
      );
      await tester.pump();

      expect(
        _writingDetailPhysics(tester),
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
      await gesture.moveBy(const Offset(0, -120));
      await tester.pump();
      expect(scrollable.position.pixels, greaterThan(0));
      await gesture.up();
    });

    testWidgets('repeated gestures release the scroll lock every time', (
      tester,
    ) async {
      await _pumpWritingDetail(tester, character: kanji);

      for (var attempt = 0; attempt < 3; attempt++) {
        final gesture = await tester.startGesture(
          tester.getCenter(_writingCanvasFinder),
        );
        await tester.pump();
        expect(
          _writingDetailPhysics(tester),
          isA<NeverScrollableScrollPhysics>(),
        );
        await gesture.up();
        await tester.pump();
        expect(
          _writingDetailPhysics(tester),
          isNot(isA<NeverScrollableScrollPhysics>()),
        );
      }
    });

    testWidgets('lifecycle interruption releases an active gesture', (
      tester,
    ) async {
      await _pumpWritingDetail(tester, character: kanji);
      final gesture = await tester.startGesture(
        tester.getCenter(_writingCanvasFinder),
      );
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(
        _writingDetailPhysics(tester),
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await gesture.cancel();
    });

    testWidgets('completion releases the lock and submits the result once', (
      tester,
    ) async {
      final repository = _FakeWritingRepository(<WritingCharacter>[kanji]);
      final engineFactory = _CompletableWritingEngineFactory();
      await _pumpWritingDetail(
        tester,
        character: kanji,
        repository: repository,
        engineFactory: engineFactory,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(_writingCanvasFinder),
      );
      await tester.pump();
      expect(
        _writingDetailPhysics(tester),
        isA<NeverScrollableScrollPhysics>(),
      );

      engineFactory.engine.complete(result);
      await tester.pumpAndSettle();

      expect(
        _writingDetailPhysics(tester),
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
      expect(repository.kanjiSubmitCalls, 1);
      await gesture.cancel();
    });

    testWidgets('disposing during a stroke leaves no gesture lock behind', (
      tester,
    ) async {
      await _pumpWritingDetail(tester, character: kanji);
      final gesture = await tester.startGesture(
        tester.getCenter(_writingCanvasFinder),
      );
      await tester.pump();
      expect(
        _writingDetailPhysics(tester),
        isA<NeverScrollableScrollPhysics>(),
      );

      await tester.pumpWidget(_localizedApp(const SizedBox.shrink()));
      await tester.pump();
      await gesture.cancel();

      await _pumpWritingDetail(tester, character: kanji);
      expect(
        _writingDetailPhysics(tester),
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Map<String, Object?> _envelope(Object? result) => <String, Object?>{
  'statusCode': 200,
  'isSuccess': true,
  'result': result,
};

Map<String, Object?> _kanaQueueItem({required int id, required String type}) =>
    <String, Object?>{
      'kanaCharacterId': id,
      'character': type == 'Hiragana' ? 'あ' : 'ア',
      'type': type,
      'romaji': 'a',
      'strokeCount': 3,
      'strokeOrderImageUrl': null,
      'audioUrl': null,
      'isNew': true,
    };

Map<String, Object?> _kanjiQueueItem() => <String, Object?>{
  'kanjiId': 910005,
  'character': '木',
  'meaning': 'Cây; gỗ',
  'onYomi': 'モク',
  'kunYomi': 'き',
  'strokeCount': 4,
  'writingScore': 50,
  'writingPracticeMode': 'free',
  'isNew': false,
};

Map<String, Object?> _kanaSubmissionResult() => <String, Object?>{
  'practiceCardId': 7001,
  'kanaCharacterId': 101,
  'totalMistakes': 1,
  'qualityScore': 4,
  'repetitions': 2,
  'intervalDays': 3,
  'nextReviewDate': '2026-10-12T00:00:00Z',
};

Map<String, Object?> _kanjiSubmissionResult() => <String, Object?>{
  'reviewCardId': 8001,
  'totalMistakes': 1,
  'qualityScore': 4,
  'repetitions': 2,
  'intervalDays': 3,
  'nextReviewDate': '2026-10-12T00:00:00Z',
  'score': 90,
};

WritingSubmissionReceipt _receipt(int id) => WritingSubmissionReceipt(
  characterId: id,
  totalMistakes: 1,
  qualityScore: 4,
  repetitions: 2,
  intervalDays: 3,
  nextReviewDate: DateTime.utc(2026, 10, 12),
  score: id == 910005 ? 90 : null,
);

class _RecordingWritingApiClient extends ApiClient {
  _RecordingWritingApiClient(this.responses)
    : super(Dio(), const ApiErrorMapper());

  final Map<String, Object?> responses;
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Object? lastData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    return _response<T>('GET $path', path);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;
    return _response<T>('POST $path', path);
  }

  Response<T> _response<T>(String key, String path) => Response<T>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: responses[key] as T,
  );
}

class _FakeWritingRepository implements WritingPracticeRepository {
  _FakeWritingRepository(
    this.items, {
    this.loadError,
    this.failuresBeforeSuccess = 0,
  });

  final List<WritingCharacter> items;
  final Object? loadError;
  int failuresBeforeSuccess;
  int kanaSubmitCalls = 0;
  int kanjiSubmitCalls = 0;

  @override
  Future<List<WritingCharacter>> loadQueue(WritingQueueRequest request) async {
    if (loadError != null) throw loadError!;
    return items;
  }

  @override
  Future<List<KanjiWritingScore>> loadKanjiScores() async => const [];

  @override
  Future<WritingSubmissionReceipt> submitKana({
    required WritingCharacter character,
    required WritingPracticeResult result,
  }) async {
    kanaSubmitCalls++;
    return _submit(character.id);
  }

  @override
  Future<WritingSubmissionReceipt> submitKanji({
    required WritingCharacter character,
    required WritingPracticeResult result,
    required WritingPracticeMode mode,
  }) async {
    kanjiSubmitCalls++;
    return _submit(character.id);
  }

  WritingSubmissionReceipt _submit(int id) {
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw StateError('submit failed');
    }
    return _receipt(id);
  }
}

class _DeferredWritingRepository extends _FakeWritingRepository {
  _DeferredWritingRepository(super.items);

  final Completer<WritingSubmissionReceipt> _submitCompleter =
      Completer<WritingSubmissionReceipt>();

  void completeSubmit(WritingSubmissionReceipt receipt) {
    _submitCompleter.complete(receipt);
  }

  @override
  Future<WritingSubmissionReceipt> submitKanji({
    required WritingCharacter character,
    required WritingPracticeResult result,
    required WritingPracticeMode mode,
  }) {
    kanjiSubmitCalls++;
    return _submitCompleter.future;
  }
}

class _DeferredQueueRepository extends _FakeWritingRepository {
  _DeferredQueueRepository() : super(const <WritingCharacter>[]);

  final Completer<List<WritingCharacter>> _queueCompleter =
      Completer<List<WritingCharacter>>();

  void complete(List<WritingCharacter> items) =>
      _queueCompleter.complete(items);

  @override
  Future<List<WritingCharacter>> loadQueue(WritingQueueRequest request) =>
      _queueCompleter.future;
}

class _RetryQueueRepository extends _FakeWritingRepository {
  _RetryQueueRepository(super.items);

  int loadCalls = 0;

  @override
  Future<List<WritingCharacter>> loadQueue(WritingQueueRequest request) async {
    loadCalls++;
    if (loadCalls == 1) throw StateError('offline');
    return items;
  }
}

class _ControllerHarness {
  const _ControllerHarness(
    this.container,
    this.request,
    this.controller,
    this.ready,
  );

  final ProviderContainer container;
  final WritingQueueRequest request;
  final WritingPracticeController controller;
  final Future<WritingPracticeState> ready;

  WritingPracticeState get value =>
      container.read(writingPracticeControllerProvider(request)).requireValue;
}

_ControllerHarness _controllerHarness(WritingPracticeRepository repository) {
  const request = WritingQueueRequest(script: WritingScript.kanji);
  final container = ProviderContainer(
    overrides: [
      writingPracticeRepositoryProvider.overrideWithValue(repository),
    ],
  );
  final subscription = container.listen(
    writingPracticeControllerProvider(request),
    (_, _) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);
  addTearDown(container.dispose);
  return _ControllerHarness(
    container,
    request,
    container.read(writingPracticeControllerProvider(request).notifier),
    container.read(writingPracticeControllerProvider(request).future),
  );
}

Future<void> _pumpWriting(
  WidgetTester tester, {
  required WritingPracticeRepository repository,
  WritingScript script = WritingScript.hiragana,
}) async {
  final container = ProviderContainer(
    overrides: [
      writingPracticeRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _localizedApp(WritingPracticeScreen(script: script)),
    ),
  );
}

Finder get _writingCanvasFinder =>
    find.byKey(const ValueKey<String>('writing_canvas_pointer_region'));

Future<void> _pumpWritingDetail(
  WidgetTester tester, {
  required WritingCharacter character,
  WritingPracticeRepository? repository,
  WritingPracticeEngineFactory? engineFactory,
}) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      writingPracticeRepositoryProvider.overrideWithValue(
        repository ?? _FakeWritingRepository(<WritingCharacter>[character]),
      ),
      if (engineFactory != null)
        writingPracticeEngineFactoryProvider.overrideWithValue(engineFactory)
      else
        writingStrokeDataRepositoryProvider.overrideWithValue(
          const _StrokeDataRepository(_singleStrokeJson),
        ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _localizedApp(
        WritingPracticeDetailScreen(
          script: character.script,
          characterId: character.id,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(_writingCanvasFinder, findsOneWidget);
}

ScrollPhysics? _writingDetailPhysics(WidgetTester tester) => tester
    .widget<ListView>(find.byKey(const ValueKey<String>('writing_detail_view')))
    .physics;

ScrollableState _writingDetailScrollable(WidgetTester tester) => tester.state(
  find
      .descendant(
        of: find.byKey(const ValueKey<String>('writing_detail_view')),
        matching: find.byType(Scrollable),
      )
      .first,
);

Widget _localizedApp(Widget home) => MaterialApp(
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light,
  home: home,
);

Widget _localizedRouter(GoRouter router) => MaterialApp.router(
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light,
  routerConfig: router,
);

const _singleStrokeJson =
    '{"strokes":["M 100 100 L 900 900"],'
    '"medians":[[[100,100],[900,900]]]}';

class _StrokeDataRepository implements WritingStrokeDataRepository {
  const _StrokeDataRepository(this.data);

  final String data;

  @override
  Future<String> load({
    required String character,
    required WritingScript script,
  }) async => data;
}

class _CompletableWritingEngineFactory implements WritingPracticeEngineFactory {
  late final _CompletableWritingEngine engine;

  @override
  WritingPracticeEngine create(TickerProvider tickerProvider) {
    return engine = _CompletableWritingEngine();
  }
}

class _CompletableWritingEngine extends ChangeNotifier
    implements WritingPracticeEngine {
  WritingEngineSnapshot _snapshot = const WritingEngineSnapshot.empty();
  bool _disposed = false;

  @override
  Listenable get listenable => this;

  @override
  WritingEngineSnapshot get snapshot => _snapshot;

  @override
  Future<void> loadCharacter({
    required String character,
    required WritingScript script,
  }) async {
    _replaceSnapshot(
      WritingEngineSnapshot(
        phase: WritingEnginePhase.ready,
        character: character,
        totalStrokeCount: 4,
      ),
    );
  }

  void complete(WritingPracticeResult result) {
    _replaceSnapshot(
      WritingEngineSnapshot(
        phase: WritingEnginePhase.completed,
        character: _snapshot.character,
        totalStrokeCount: result.totalStrokeCount,
        result: result,
      ),
    );
  }

  void _replaceSnapshot(WritingEngineSnapshot snapshot) {
    if (_disposed) return;
    _snapshot = snapshot;
    notifyListeners();
  }

  @override
  Widget buildCanvas({required Size size, Key? key}) {
    return SizedBox.fromSize(size: size, key: key);
  }

  @override
  void reset() {}

  @override
  void showStrokeAnimation() {}

  @override
  void startQuiz({required bool guided}) {}

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _snapshot = const WritingEngineSnapshot(phase: WritingEnginePhase.disposed);
    super.dispose();
  }
}

class _ThrowingStrokeDataRepository implements WritingStrokeDataRepository {
  const _ThrowingStrokeDataRepository();

  @override
  Future<String> load({
    required String character,
    required WritingScript script,
  }) {
    throw StateError('stroke data unavailable');
  }
}
