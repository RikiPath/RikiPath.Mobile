import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error_mapper.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/data/api_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/data/api_learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/data/api_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_session.dart';

import '../../support/test_json_preference_store.dart';

void main() {
  test(
    'discovery sends the real level ID and preserves backend lesson IDs',
    () async {
      final client = _LearningApiClient(<String, Object?>{
        'GET /api/LessonProgress/lessons': _discoveryEnvelope(),
      });

      final snapshot = await ApiLearningRepository(
        client,
      ).loadLearningSnapshot(certificateLevelId: 84);

      expect(client.lastQuery, <String, dynamic>{'certificateLevelId': 84});
      expect(snapshot.certificateLevelId, 84);
      expect(snapshot.lessons.map((item) => item.lessonId), <int>[701, 709]);
      expect(snapshot.currentLesson.routeId, '709');
      expect(snapshot.lessons.first.isCompleted, isTrue);
    },
  );

  test(
    'discovery follows backend sortOrder instead of response order',
    () async {
      final client = _LearningApiClient(<String, Object?>{
        'GET /api/LessonProgress/lessons': _discoveryEnvelope(
          lessons: <Object?>[
            _summary(
              lessonId: 709,
              sortOrder: 2,
              completed: false,
              progress: 0,
            ),
            _summary(
              lessonId: 701,
              sortOrder: 1,
              completed: false,
              progress: 0,
            ),
          ],
          completedLessons: 0,
          overallProgressPercent: 0,
        ),
      });

      final snapshot = await ApiLearningRepository(
        client,
      ).loadLearningSnapshot(certificateLevelId: 84);

      expect(snapshot.lessons.map((item) => item.lessonId), <int>[701, 709]);
      expect(snapshot.currentLesson.routeId, '701');
    },
  );

  test(
    'learning-path generation posts an empty contract and maps real IDs',
    () async {
      final client = _LearningApiClient(<String, Object?>{
        'POST /api/LearningPath/generate': _learningPathEnvelope(),
      });

      final path = await ApiLearningPathRepository(client).generate();

      expect(client.lastData, const <String, Object?>{});
      expect(path.dailySchedules, hasLength(2));
      expect(path.orderedLessons.map((item) => item.lessonId), <int>[709, 715]);
      expect(path.recommendationAfter(709)?.lessonId, 715);
    },
  );

  test('latest learning path restores without a generation request', () async {
    final client = _LearningApiClient(<String, Object?>{
      'GET /api/LearningPath/latest': _learningPathEnvelope(),
    });

    final path = await ApiLearningPathRepository(client).loadLatest();

    expect(path?.recommendationAfter(709)?.lessonId, 715);
    expect(client.calls, <String>['GET /api/LearningPath/latest']);
  });

  test(
    'learning-path generation rejects mismatched lesson IDs and titles',
    () async {
      final client = _LearningApiClient(<String, Object?>{
        'POST /api/LearningPath/generate': _learningPathEnvelope(
          firstDayLessonTitles: const <String>[],
        ),
      });

      expect(
        ApiLearningPathRepository(client).generate,
        throwsA(isA<UnknownError>()),
      );
    },
  );

  test(
    'valid empty discovery stays empty without fixture substitution',
    () async {
      final client = _LearningApiClient(<String, Object?>{
        'GET /api/LessonProgress/lessons': _discoveryEnvelope(
          lessons: const <Object?>[],
          completedLessons: 0,
          overallProgressPercent: 0,
        ),
      });

      final snapshot = await ApiLearningRepository(
        client,
      ).loadLearningSnapshot(certificateLevelId: 84);

      expect(snapshot.lessons, isEmpty);
      expect(snapshot.totalLessons, 0);
      expect(snapshot.hasCurrentLesson, isFalse);
      expect(snapshot.currentLesson.routeId, isEmpty);
    },
  );

  test('detail and completion use the real lesson ID routes', () async {
    final client = _LearningApiClient(<String, Object?>{
      'GET /api/LessonProgress/lessons/709': _detailEnvelope(),
      'POST /api/LessonProgress/lessons/709/complete': _detailEnvelope(
        completed: true,
        progressPercent: 100,
      ),
    });
    final repository = ApiLessonRepository(client);

    final lesson = await repository.loadLesson('709');
    final progress = await repository.completeLesson(routeId: '709');

    expect(lesson.remoteLessonId, 709);
    expect(lesson.routeId, '709');
    expect(lesson.mediaSource.type, LessonMediaSourceType.none);
    expect(lesson.vocabulary, isEmpty);
    expect(lesson.relatedGrammar, isEmpty);
    expect(progress.isCompleted, isTrue);
    expect(client.calls, <String>[
      'GET /api/LessonProgress/lessons/709',
      'POST /api/LessonProgress/lessons/709/complete',
    ]);
  });

  test(
    'lesson detail maps verified backend media and attachment URLs',
    () async {
      final client = _LearningApiClient(<String, Object?>{
        'GET /api/LessonProgress/lessons/709': _detailEnvelope(
          videoUrl: 'https://cdn.example.test/lesson.mp4',
          attachmentUrl: 'https://cdn.example.test/lesson.pdf',
        ),
      });

      final lesson = await ApiLessonRepository(client).loadLesson('709');

      expect(lesson.mediaSource.type, LessonMediaSourceType.network);
      expect(
        lesson.mediaSource.uri,
        Uri.parse('https://cdn.example.test/lesson.mp4'),
      );
      expect(
        lesson.attachmentUrl,
        Uri.parse('https://cdn.example.test/lesson.pdf'),
      );
    },
  );

  test('lesson detail maps structured content with backend IDs', () async {
    final client = _LearningApiClient(<String, Object?>{
      'GET /api/LessonProgress/lessons/709': _detailEnvelope(
        vocabularies: <Object?>[
          <String, Object?>{
            'vocabularyId': 91,
            'word': '学ぶ',
            'reading': 'まなぶ',
            'meaning': 'learn',
            'exampleSentence': '日本語を学ぶ。',
            'exampleSentenceMeaning': 'Learn Japanese.',
            'audioUrl': null,
          },
        ],
        kanjis: <Object?>[
          <String, Object?>{
            'kanjiId': 92,
            'character': '学',
            'meaning': 'study',
            'sinoVietnamese': 'HỌC',
            'onYomi': 'ガク',
            'kunYomi': 'まなぶ',
            'strokeCount': 8,
            'strokeOrderImageUrl': null,
            'audioUrl': null,
          },
        ],
        grammars: <Object?>[
          <String, Object?>{
            'grammarPatternId': 93,
            'title': '〜たい',
            'structure': 'Vます + たい',
            'usageNotes': 'Express a desire',
            'exampleSentence': null,
            'exampleSentenceMeaning': null,
          },
        ],
      ),
    });

    final lesson = await ApiLessonRepository(client).loadLesson('709');

    expect(lesson.vocabulary.single.vocabularyId, 91);
    expect(lesson.kanji.single.kanjiId, 92);
    expect(lesson.relatedGrammar.single.grammarPatternId, 93);
  });

  test('completion controller blocks parallel repeated taps', () async {
    final repository = _ControlledLessonRepository();
    final container = _lessonContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(lessonControllerProvider('709').notifier);
    await container.read(lessonControllerProvider('709').future);

    final first = controller.completeLesson();
    final second = controller.completeLesson();
    expect(repository.completeCalls, 1);
    repository.completeResult.complete(_completedProgress);
    await Future.wait(<Future<void>>[first, second]);

    final state = container.read(lessonControllerProvider('709')).requireValue;
    expect(state.stage, LessonStage.completed);
    expect(state.lesson.progress.isCompleted, isTrue);
  });

  test(
    'completion failure preserves lesson data and exposes retry state',
    () async {
      final repository = _FailingCompletionLessonRepository();
      final container = _lessonContainer(repository);
      addTearDown(container.dispose);
      final controller = container.read(
        lessonControllerProvider('709').notifier,
      );
      await container.read(lessonControllerProvider('709').future);

      await controller.completeLesson();

      final state = container
          .read(lessonControllerProvider('709'))
          .requireValue;
      expect(state.stage, LessonStage.detail);
      expect(state.lesson.progress.isCompleted, isFalse);
      expect(state.isCompleting, isFalse);
      expect(state.completionErrorMessage, isNotEmpty);
    },
  );
}

ProviderContainer _lessonContainer(LessonRepository repository) {
  return ProviderContainer(
    overrides: [
      jsonPreferenceStoreProvider.overrideWithValue(TestJsonPreferenceStore()),
      lessonRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

class _LearningApiClient extends ApiClient {
  _LearningApiClient(this.responses) : super(Dio(), const ApiErrorMapper());

  final Map<String, Object?> responses;
  final List<String> calls = <String>[];
  Map<String, dynamic>? lastQuery;
  Object? lastData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
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
    lastData = data;
    return _response<T>('POST $path', path);
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async => _response<T>('PATCH $path', path);

  Response<T> _response<T>(String key, String path) {
    calls.add(key);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: responses[key] as T,
    );
  }
}

class _ControlledLessonRepository implements LessonRepository {
  final Completer<LessonProgress> completeResult = Completer<LessonProgress>();
  int completeCalls = 0;

  @override
  Future<Lesson> loadLesson(String routeId) async => _liveLesson;

  @override
  Future<LessonProgress> completeLesson({required String routeId}) {
    completeCalls++;
    return completeResult.future;
  }

  @override
  Future<LessonProgress> updatePlaybackPosition({
    required String routeId,
    required int positionSeconds,
    required int durationSeconds,
  }) => throw UnsupportedError('No media is exposed by this contract.');
}

class _FailingCompletionLessonRepository implements LessonRepository {
  @override
  Future<Lesson> loadLesson(String routeId) async => _liveLesson;

  @override
  Future<LessonProgress> completeLesson({required String routeId}) =>
      Future<LessonProgress>.error(StateError('controlled failure'));

  @override
  Future<LessonProgress> updatePlaybackPosition({
    required String routeId,
    required int positionSeconds,
    required int durationSeconds,
  }) => throw UnsupportedError('No media is exposed by this contract.');
}

const _completedProgress = LessonProgress(
  progressPercent: 100,
  resumePositionSeconds: 0,
  isCompleted: true,
);

const _liveLesson = Lesson(
  routeId: '709',
  remoteLessonId: 709,
  title: 'Live grammar lesson',
  focus: 'Authoritative content',
  level: JlptLevel.n4,
  category: 'Grammar',
  curriculum: 'JLPT N4',
  chapterNumber: 0,
  lessonNumber: 2,
  durationSeconds: 0,
  objective: 'Authoritative content',
  parts: <LessonPart>[],
  vocabulary: <LessonVocabularyItem>[],
  detailVocabularyCount: 0,
  videoVocabularyCount: 0,
  relatedGrammar: <LessonRelatedGrammar>[],
  article: LessonArticle(
    formulas: <String>[],
    meaning: 'Authoritative content',
    usageSteps: <String>[],
    examples: <LessonExample>[],
    importantNotes: <String>[],
  ),
  progress: LessonProgress(
    progressPercent: 0,
    resumePositionSeconds: 0,
    isCompleted: false,
  ),
  availability: LessonAvailability.available,
  noteCount: 0,
  streakDays: 0,
  detailXp: 0,
  completionXp: 0,
  masteryItems: <LessonMasteryItem>[],
  mediaSource: LessonMediaSource.none(),
);

Map<String, Object?> _discoveryEnvelope({
  List<Object?>? lessons,
  int completedLessons = 1,
  int overallProgressPercent = 63,
}) {
  final items =
      lessons ??
      <Object?>[
        _summary(lessonId: 701, sortOrder: 1, completed: true, progress: 100),
        _summary(lessonId: 709, sortOrder: 2, completed: false, progress: 25),
      ];
  return <String, Object?>{
    'statusCode': 200,
    'isSuccess': true,
    'result': <String, Object?>{
      'certificateLevelId': 84,
      'levelCode': 'N4',
      'totalLessons': items.length,
      'completedLessons': completedLessons,
      'overallProgressPercent': overallProgressPercent,
      'lessons': items,
    },
  };
}

Map<String, Object?> _summary({
  required int lessonId,
  required int sortOrder,
  required bool completed,
  required int progress,
}) => <String, Object?>{
  'lessonId': lessonId,
  'title': 'Lesson $lessonId',
  'description': null,
  'sortOrder': sortOrder,
  'languageSkillId': 3,
  'languageSkillName': 'Grammar',
  'progressPercent': progress,
  'resumePositionSeconds': 0,
  'isCompleted': completed,
  'completedAt': completed ? '2026-10-19T08:00:00Z' : null,
};

Map<String, Object?> _detailEnvelope({
  bool completed = false,
  int progressPercent = 25,
  String? videoUrl,
  String? attachmentUrl,
  List<Object?>? vocabularies,
  List<Object?>? kanjis,
  List<Object?>? grammars,
}) => <String, Object?>{
  'statusCode': 200,
  'isSuccess': true,
  'result': <String, Object?>{
    'lessonId': 709,
    'certificateLevelId': 84,
    'levelCode': 'N4',
    'languageSkillId': 3,
    'languageSkillName': 'Grammar',
    'title': 'Live grammar lesson',
    'content': 'Authoritative content',
    'videoUrl': videoUrl,
    'attachmentUrl': attachmentUrl,
    'orderIndex': 2,
    'progressPercent': progressPercent,
    'resumePositionSeconds': 0,
    'isCompleted': completed,
    'completedAt': completed ? '2026-10-19T08:00:00Z' : null,
    'vocabularies': ?vocabularies,
    'kanjis': ?kanjis,
    'grammars': ?grammars,
  },
};

Map<String, Object?> _learningPathEnvelope({
  List<String> firstDayLessonTitles = const <String>['Live grammar lesson'],
}) => <String, Object?>{
  'statusCode': 200,
  'isSuccess': true,
  'result': <String, Object?>{
    'userId': 42,
    'generatedAt': '2026-10-26T08:00:00Z',
    'summary': 'Ưu tiên ngữ pháp còn yếu.',
    'strengths': <String>['Từ vựng'],
    'weaknesses': <String>['Ngữ pháp'],
    'feasibility': 'Khả thi nếu học đều.',
    'isExamDateRealistic': true,
    'recommendedStudyDays': 2,
    'suggestedExamDate': null,
    'focusTopics': <String>['Ngữ pháp N4'],
    'dailySchedules': <Object?>[
      <String, Object?>{
        'day': 1,
        'title': 'Củng cố ngữ pháp',
        'focus': 'Hoàn thành bài đang học.',
        'lessonIds': <int>[709],
        'lessons': firstDayLessonTitles,
      },
      <String, Object?>{
        'day': 2,
        'title': 'Luyện đọc',
        'focus': 'Đọc hiểu theo ngữ cảnh.',
        'lessonIds': <int>[715],
        'lessons': <String>['Live reading lesson'],
      },
    ],
  },
};
