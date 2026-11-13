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
import 'package:rikipath_mobile/features/learning/application/learner_journey_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/learning/data/api_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/data/api_learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/data/api_lesson_practice_repository.dart';
import 'package:rikipath_mobile/features/learning/data/api_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_session.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

import '../../support/test_json_preference_store.dart';

void main() {
  test(
    'live discovery uses server study level, not stale local target',
    () async {
      final client = _LearningApiClient(<String, Object?>{
        'GET /api/LessonProgress/lessons': _discoveryEnvelope(),
      });
      final container = ProviderContainer(
        overrides: [
          jsonPreferenceStoreProvider.overrideWithValue(
            TestJsonPreferenceStore(),
          ),
          learningRepositoryProvider.overrideWithValue(
            ApiLearningRepository(client),
          ),
          userProfileRepositoryProvider.overrideWithValue(
            _CurrentStudyProfileRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(learnerJourneyControllerProvider.notifier)
          .selectLevel(JlptLevel.n3);

      final snapshot = await container.read(learningControllerProvider.future);

      expect(client.lastQuery, <String, dynamic>{'certificateLevelId': 84});
      expect(snapshot.certificateLevelId, 84);
      expect(snapshot.lessons.map((lesson) => lesson.lessonId), <int>[
        701,
        709,
      ]);
    },
  );

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

  test('active path survives a newer unconfirmed preview', () async {
    final draft = _learningPathEnvelope();
    (draft['result']! as Map<String, Object?>)
      ..['pathId'] = 100
      ..['version'] = 2
      ..['status'] = 'DRAFT';
    final active = _learningPathEnvelope()['result'];
    final client = _LearningApiClient(<String, Object?>{
      'GET /api/LearningPath/active': draft,
      'GET /api/LearningPath/history': <String, Object?>{
        'isSuccess': true,
        'result': <Object?>[active],
      },
    });

    final path = await ApiLearningPathRepository(client).loadActive();

    expect(path?.pathId, 99);
    expect(path?.status, LearningPathStatus.active);
    expect(client.calls, <String>[
      'GET /api/LearningPath/active',
      'GET /api/LearningPath/history',
    ]);
  });

  test('an active response does not fetch history unnecessarily', () async {
    final client = _LearningApiClient(<String, Object?>{
      'GET /api/LearningPath/active': _learningPathEnvelope(),
    });

    final path = await ApiLearningPathRepository(client).loadActive();

    expect(path?.status, LearningPathStatus.active);
    expect(client.calls, <String>['GET /api/LearningPath/active']);
  });

  test(
    'AI path accepts a missing exam date and maps server day state',
    () async {
      final body = _learningPathEnvelope();
      final result = body['result']! as Map<String, Object?>;
      result['isExamDateRealistic'] = null;
      result['hasTargetExamDate'] = false;
      result['horizon'] = 'long_term';
      result['planDurationDays'] = 30;
      final days = result['dailySchedules']! as List<Object?>;
      (days.first! as Map<String, Object?>).addAll(<String, Object?>{
        'canStart': true,
        'isStarted': false,
        'isCompleted': false,
        'startedAt': null,
        'completedAt': null,
      });
      final client = _LearningApiClient(<String, Object?>{
        'GET /api/LearningPath/latest': body,
      });

      final path = await ApiLearningPathRepository(client).loadLatest();

      expect(path?.isExamDateRealistic, isNull);
      expect(path?.hasTargetExamDate, isFalse);
      expect(path?.planDurationDays, 30);
      expect(path?.dailySchedules.first.canStart, isTrue);
      expect(path?.dailySchedules.first.isStarted, isFalse);
    },
  );

  test(
    'AI next lesson never crosses a locked day or unrelated lesson',
    () async {
      final body = _learningPathEnvelope();
      final result = body['result']! as Map<String, Object?>;
      final days = result['dailySchedules']! as List<Object?>;
      (days[0]! as Map<String, Object?>)['canStart'] = true;
      (days[1]! as Map<String, Object?>)['canStart'] = false;
      final client = _LearningApiClient(<String, Object?>{
        'GET /api/LearningPath/latest': body,
      });

      final path = await ApiLearningPathRepository(client).loadLatest();

      expect(path?.recommendationAfter(709), isNull);
      expect(path?.recommendationAfter(999), isNull);
    },
  );

  test('AI day actions call canonical Backend routes', () async {
    final client = _LearningApiClient(<String, Object?>{
      'POST /api/LearningPath/active/days/1/start': _learningPathEnvelope(),
      'POST /api/LearningPath/active/days/1/complete': _learningPathEnvelope(),
    });
    final repository = ApiLearningPathRepository(client);

    await repository.startDay(1);
    await repository.completeDay(1);

    expect(client.calls, <String>[
      'POST /api/LearningPath/active/days/1/start',
      'POST /api/LearningPath/active/days/1/complete',
    ]);
  });

  test(
    'lesson Practice Exercise uses actual Backend IDs and answer contract',
    () async {
      final client = _LearningApiClient(<String, Object?>{
        'GET /api/PracticeExercise/lesson/709': <String, Object?>{
          'isSuccess': true,
          'result': <Object?>[
            <String, Object?>{
              'id': 801,
              'lessonId': 709,
              'title': 'Ôn ngữ pháp',
              'description': null,
              'questionCount': 1,
              'bestScorePercent': null,
            },
          ],
        },
        'POST /api/PracticeExercise/801/start': <String, Object?>{
          'isSuccess': true,
          'result': <String, Object?>{
            'attemptId': 901,
            'practiceExerciseId': 801,
            'title': 'Ôn ngữ pháp',
            'resumed': false,
            'questions': <Object?>[
              <String, Object?>{
                'id': 1001,
                'questionText': 'Chọn đáp án',
                'options': <Object?>[
                  <String, Object?>{'id': 1101, 'optionText': 'A'},
                  <String, Object?>{'id': 1102, 'optionText': 'B'},
                ],
              },
            ],
            'savedAnswers': <Object?>[],
          },
        },
        'POST /api/PracticeExercise/attempt/901/submit': <String, Object?>{
          'isSuccess': true,
          'result': <String, Object?>{
            'attemptId': 901,
            'scorePercent': 100,
            'correctCount': 1,
            'gradedQuestions': 1,
            'totalQuestions': 1,
          },
        },
      });
      final repository = ApiLessonPracticeRepository(client);

      final exercises = await repository.loadForLesson(709);
      final attempt = await repository.start(exercises.single.id);
      final result = await repository.submit(
        attemptId: attempt.attemptId,
        selectedOptionIds: <int, int>{attempt.questions.single.id: 1102},
        textAnswers: const <int, String>{},
      );

      expect(exercises.single.id, 801);
      expect(attempt.questions.single.options.map((item) => item.id), <int>[
        1101,
        1102,
      ]);
      expect(result.scorePercent, 100);
      expect(client.lastData, <String, Object?>{
        'answers': <Map<String, Object?>>[
          <String, Object?>{
            'questionId': 1001,
            'selectedOptionId': 1102,
            'textAnswer': null,
          },
        ],
      });
      expect(client.calls, <String>[
        'GET /api/PracticeExercise/lesson/709',
        'POST /api/PracticeExercise/801/start',
        'POST /api/PracticeExercise/attempt/901/submit',
      ]);
    },
  );

  test('Practice Exercise restores and submits a written answer', () async {
    final client = _LearningApiClient(<String, Object?>{
      'POST /api/PracticeExercise/801/start': <String, Object?>{
        'isSuccess': true,
        'result': <String, Object?>{
          'attemptId': 901,
          'practiceExerciseId': 801,
          'title': 'Viết câu',
          'resumed': true,
          'questions': <Object?>[
            <String, Object?>{
              'id': 1001,
              'questionText': 'Viết câu trả lời',
              'options': <Object?>[],
            },
          ],
          'savedAnswers': <Object?>[
            <String, Object?>{
              'questionId': 1001,
              'selectedOptionId': null,
              'textAnswer': 'Xin chào',
            },
          ],
        },
      },
      'POST /api/PracticeExercise/attempt/901/submit': <String, Object?>{
        'isSuccess': true,
        'result': <String, Object?>{
          'attemptId': 901,
          'scorePercent': 0,
          'correctCount': 0,
          'gradedQuestions': 0,
          'totalQuestions': 1,
        },
      },
    });
    final repository = ApiLessonPracticeRepository(client);

    final attempt = await repository.start(801);
    expect(attempt.resumed, isTrue);
    expect(attempt.savedTextAnswers, <int, String>{1001: 'Xin chào'});
    await repository.submit(
      attemptId: attempt.attemptId,
      selectedOptionIds: const <int, int>{},
      textAnswers: attempt.savedTextAnswers,
    );
    expect(client.lastData, <String, Object?>{
      'answers': <Map<String, Object?>>[
        <String, Object?>{
          'questionId': 1001,
          'selectedOptionId': null,
          'textAnswer': 'Xin chào',
        },
      ],
    });
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

  test('live completion refreshes the standard roadmap cache', () async {
    final repository = _ControlledLessonRepository();
    var roadmapLoads = 0;
    final container = ProviderContainer(
      overrides: [
        jsonPreferenceStoreProvider.overrideWithValue(
          TestJsonPreferenceStore(),
        ),
        lessonRepositoryProvider.overrideWithValue(repository),
        standardRoadmapProvider.overrideWith((ref) async {
          roadmapLoads++;
          return const StandardRoadmap(
            currentStudyLevelId: 1,
            currentStudyLevelName: 'N5',
            targetJlptLevelId: 2,
            targetJlptLevelName: 'N4',
            learningMode: LearningMode.standard,
            totalLessons: 1,
            completedLessons: 0,
            nextLessonId: 709,
            lessons: <StandardRoadmapLesson>[],
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    final roadmapSubscription = container.listen(
      standardRoadmapProvider,
      (_, _) {},
    );
    addTearDown(roadmapSubscription.close);
    await container.read(standardRoadmapProvider.future);
    expect(roadmapLoads, 1);

    final controller = container.read(lessonControllerProvider('709').notifier);
    await container.read(lessonControllerProvider('709').future);
    final completion = controller.completeLesson();
    repository.completeResult.complete(_completedProgress);
    await completion;
    await container.read(standardRoadmapProvider.future);

    expect(roadmapLoads, 2);
  });

  test(
    'live completion uses Backend next lesson ID, never guessed order',
    () async {
      final repository = _ControlledLessonRepository();
      final container = ProviderContainer(
        overrides: [
          jsonPreferenceStoreProvider.overrideWithValue(
            TestJsonPreferenceStore(),
          ),
          lessonRepositoryProvider.overrideWithValue(repository),
          standardRoadmapProvider.overrideWith(
            (ref) async => const StandardRoadmap(
              currentStudyLevelId: 1,
              currentStudyLevelName: 'N5',
              targetJlptLevelId: 2,
              targetJlptLevelName: 'N4',
              learningMode: LearningMode.standard,
              totalLessons: 2,
              completedLessons: 1,
              nextLessonId: 824,
              lessons: <StandardRoadmapLesson>[
                StandardRoadmapLesson(
                  lessonId: 709,
                  title: 'Bài đã học',
                  sortOrder: 1,
                  progressPercent: 100,
                  isCompleted: true,
                ),
                StandardRoadmapLesson(
                  lessonId: 824,
                  title: 'Bài học tiếp theo từ Backend',
                  sortOrder: 6,
                  progressPercent: 0,
                  isCompleted: false,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final lessonSubscription = container.listen(
        lessonControllerProvider('709'),
        (_, _) {},
      );
      addTearDown(lessonSubscription.close);
      final controller = container.read(
        lessonControllerProvider('709').notifier,
      );
      await container.read(lessonControllerProvider('709').future);
      final completion = controller.completeLesson();
      repository.completeResult.complete(_completedProgress);
      await completion;

      final completed = container
          .read(lessonControllerProvider('709'))
          .requireValue;
      expect(
        completed.stage,
        LessonStage.completed,
        reason:
            'progress=${completed.lesson.progress.isCompleted}, '
            'calls=${repository.completeCalls}, '
            'error=${completed.completionErrorMessage}',
      );
      expect(completed.lesson.nextLesson?.routeId, '824');
      expect(
        completed.lesson.nextLesson?.title,
        'Bài học tiếp theo từ Backend',
      );
    },
  );

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

class _CurrentStudyProfileRepository implements UserProfileRepository {
  @override
  Future<UserProfile> loadProfile() async => const UserProfile(
    userId: 42,
    email: 'learner@example.com',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    currentStudyLevelId: 84,
    currentStudyLevelName: 'N4',
    targetJlptLevelId: 3,
    targetJlptLevelName: 'N3',
    dailyStudyMinutes: 30,
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) => throw UnimplementedError();

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) =>
      throw UnimplementedError();
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
    'pathId': 99,
    'version': 1,
    'status': 'ACTIVE',
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
