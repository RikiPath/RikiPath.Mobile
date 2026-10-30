import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/core/widgets/riki_card.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_path_controller.dart';
import 'package:rikipath_mobile/features/learning/application/standard_roadmap_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_path_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/learning/domain/recommended_learning_path.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap_repository.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_roadmap_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/lesson_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';

void main() {
  testWidgets('/learn renders the approved Learning Home hierarchy', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learn);
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    expect(find.text('Cấp độ bạn đang học N4'), findsOneWidget);
    expect(find.text('Tiếp tục lộ trình'), findsOneWidget);
    expect(find.text('ĐANG HỌC DỞ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('learning_section_library')),
      160,
    );
    expect(find.text('Các phần học chính'), findsOneWidget);
    expect(find.text('Lộ trình'), findsWidgets);
    expect(find.text('Bài học'), findsWidgets);
    expect(find.text('Thư viện'), findsWidgets);
  });

  testWidgets('changing Learn level confirms and preserves the target goal', (
    tester,
  ) async {
    final repository = _DatePreservingProfileRepository();
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      profileRepository: repository,
    );
    await tester.pumpAndSettle();

    final level = find.byKey(const ValueKey<String>('learning_level_n5'));
    await tester.ensureVisible(level);
    await tester.tap(level);
    await tester.pumpAndSettle();
    expect(find.text('Đổi cấp độ đang học?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('confirm_current_study_level_change')),
    );
    await tester.pumpAndSettle();

    expect(repository.loadedProfileCount, 0);
    expect(repository.currentStudyLevelId, 101);
    expect(repository.targetJlptLevelId, 204);
    expect(repository.targetExamDate, DateTime(2030, 12, 1));
    expect(repository.dailyStudyMinutes, 30);
    expect(repository.goalCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canceling current level confirmation makes no request', (
    tester,
  ) async {
    final repository = _DatePreservingProfileRepository();
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      profileRepository: repository,
    );
    await tester.pumpAndSettle();
    final level = find.byKey(const ValueKey<String>('learning_level_n5'));
    await tester.ensureVisible(level);
    await tester.tap(level);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(repository.currentStudyLevelId, 204);
    expect(repository.goalCalls, 0);
    expect(tester.takeException(), isNull);
  });

  test('learning scope supports the complete JLPT catalog', () {
    expect(JlptLevel.values, <JlptLevel>[
      JlptLevel.n5,
      JlptLevel.n4,
      JlptLevel.n3,
      JlptLevel.n2,
      JlptLevel.n1,
    ]);
    expect(FixtureLearningRepository.snapshot.jlptTarget, JlptLevel.n4);
    expect(AppRoutes.learnRoadmap, '/learn/roadmap');
    expect(AppRoutes.learnProgress, '/learn/progress');
  });

  testWidgets('Learning Home opens the roadmap inside the Learn branch', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learn);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('learning_open_roadmap_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LearningRoadmapScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('standard_roadmap_summary')),
      findsOneWidget,
    );
    expect(find.text('Bài tiếp theo'), findsNWidgets(2));
    _expectLearnTabSelected(tester);
  });

  testWidgets(
    'roadmap keeps Standard available and enables AI only after Placement',
    (tester) async {
      final pathRepository = _TestLearningPathRepository();
      await _pumpLearning(
        tester,
        initialLocation: AppRoutes.learnRoadmap,
        placementStatus: const PlacementTestStatus(
          hasCompletedPlacementTest: true,
          isReadyForLearningPath: true,
        ),
        pathRepository: pathRepository,
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('ai_learning_path_generate_button')),
      );
      await tester.pumpAndSettle();

      expect(pathRepository.generateCalls, 1);
      expect(
        find.byKey(const ValueKey<String>('standard_lesson_501')),
        findsOneWidget,
      );
      expect(find.text('Ưu tiên phần kiến thức còn yếu.'), findsOneWidget);
    },
  );

  testWidgets('AI generation failure leaves the Standard Roadmap usable', (
    tester,
  ) async {
    final pathRepository = _TestLearningPathRepository(
      generationError: StateError('AI unavailable'),
    );
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learnRoadmap,
      placementStatus: const PlacementTestStatus(
        hasCompletedPlacementTest: true,
        isReadyForLearningPath: true,
      ),
      pathRepository: pathRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('ai_learning_path_generate_button')),
    );
    await tester.pumpAndSettle();

    expect(pathRepository.generateCalls, 1);
    expect(
      find.byKey(const ValueKey<String>('standard_roadmap_success_view')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('standard_lesson_501')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('ai_learning_path_generate_button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'existing AI path uses preview, cancel and confirm without direct regeneration',
    (tester) async {
      final pathRepository = _TestLearningPathRepository(
        activePath: _testPath(summary: 'Lộ trình đang học', version: 1),
      );
      await _pumpLearning(
        tester,
        initialLocation: AppRoutes.learnRoadmap,
        placementStatus: const PlacementTestStatus(
          hasCompletedPlacementTest: true,
          isReadyForLearningPath: true,
        ),
        pathRepository: pathRepository,
      );
      await tester.pumpAndSettle();

      final regenerate = find.byKey(
        const ValueKey<String>('ai_learning_path_generate_button'),
      );
      await tester.ensureVisible(regenerate);
      await tester.tap(regenerate);
      await tester.pumpAndSettle();
      expect(pathRepository.previewCalls, 1);
      expect(pathRepository.lastStartingLevelId, 101);
      expect(pathRepository.lastTargetLevelId, 204);
      expect(pathRepository.generateCalls, 0);
      expect(
        find.byKey(const ValueKey<String>('ai_learning_path_preview_dialog')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('ai_learning_path_cancel_preview')),
      );
      await tester.pumpAndSettle();
      expect(pathRepository.cancelCalls, 1);
      expect(pathRepository.confirmCalls, 0);
      expect(find.text('Lộ trình đang học'), findsOneWidget);

      await tester.tap(regenerate);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('ai_learning_path_confirm_preview')),
      );
      await tester.pumpAndSettle();
      expect(pathRepository.previewCalls, 2);
      expect(pathRepository.confirmCalls, 1);
      expect(pathRepository.generateCalls, 0);
      expect(find.text('Lộ trình đã xác nhận'), findsOneWidget);
    },
  );

  testWidgets('roadmap renders server lesson IDs, progress, and disabled AI', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learnRoadmap);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('standard_lesson_501')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('standard_lesson_502')),
      findsOneWidget,
    );
    expect(find.text('Tiến độ chuẩn: 1/2 bài'), findsNWidgets(2));
    expect(find.textContaining('Placement để mở khóa'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('ai_learning_path_generate_button')),
      findsNothing,
    );
    _expectLearnTabSelected(tester);
  });

  testWidgets('next standard lesson navigates using the real backend ID', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learnRoadmap);
    await tester.pumpAndSettle();

    final lessonCard = tester.widget<RikiCard>(
      find.byKey(const ValueKey<String>('standard_lesson_502')),
    );
    expect(lessonCard.onTap, isNotNull);
    lessonCard.onTap!();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId,
      '502',
    );
  });

  testWidgets('Standard Roadmap displays the backend empty state', (
    tester,
  ) async {
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learnRoadmap,
      standardRoadmapRepository: _TestStandardRoadmapRepository(empty: true),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('standard_roadmap_empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('ai_personalized_path_section')),
      findsOneWidget,
    );
  });

  testWidgets('Standard Roadmap failure is retryable without an AI request', (
    tester,
  ) async {
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learnRoadmap,
      standardRoadmapRepository: _TestStandardRoadmapRepository(
        error: StateError('offline'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('learning_error_view')),
      findsOneWidget,
    );
  });

  testWidgets('progress screen renders all five approved skill categories', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learnProgress);
    await tester.pumpAndSettle();

    expect(find.text('Tổng tiến độ toàn khóa'), findsOneWidget);
    expect(find.text('Chi tiết tiến độ kỹ năng'), findsOneWidget);
    for (final label in <String>[
      'Từ vựng',
      'Kanji',
      'Ngữ pháp',
      'Đọc hiểu',
      'Nghe hiểu',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('N1'), findsNothing);
    expect(find.text('N2'), findsNothing);
    _expectLearnTabSelected(tester);
  });

  testWidgets('pending learning repository renders loading without crashing', (
    tester,
  ) async {
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      repository: _PendingLearningRepository(),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('learning_loading_view')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed learning repository renders retry state without crashing',
    (tester) async {
      await _pumpLearning(
        tester,
        initialLocation: AppRoutes.learn,
        repository: const _FailingLearningRepository(),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('learning_error_view')),
        findsOneWidget,
      );
      expect(find.text('Chưa thể tải nội dung học tập'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C9 routes do not overflow on a narrow portrait phone', (
    tester,
  ) async {
    final router = await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      viewportSize: const Size(320, 700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.learnRoadmap);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.learnProgress);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('learning presentation contains no direct Dio usage', () {
    final presentationDirectory = Directory(
      'lib/features/learning/presentation',
    );
    final dartFiles = presentationDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('package:dio/')), reason: file.path);
      expect(source, isNot(matches(RegExp(r'\bDio\s*\('))), reason: file.path);
    }
  });
}

class _PendingLearningRepository implements LearningRepository {
  final Completer<LearningSnapshot> _completer = Completer<LearningSnapshot>();

  @override
  Future<LearningSnapshot> loadLearningSnapshot({
    required int certificateLevelId,
  }) => _completer.future;
}

class _FailingLearningRepository implements LearningRepository {
  const _FailingLearningRepository();

  @override
  Future<LearningSnapshot> loadLearningSnapshot({
    required int certificateLevelId,
  }) {
    return Future<LearningSnapshot>.error(StateError('fixture failure'));
  }
}

Future<GoRouter> _pumpLearning(
  WidgetTester tester, {
  required String initialLocation,
  LearningRepository repository = const FixtureLearningRepository(),
  UserProfileRepository? profileRepository,
  PlacementTestStatus placementStatus = const PlacementTestStatus(
    hasCompletedPlacementTest: false,
  ),
  LearningPathRepository? pathRepository,
  StandardRoadmapRepository? standardRoadmapRepository,
  Size viewportSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = viewportSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: initialLocation,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learningRepositoryProvider.overrideWithValue(repository),
        learningPathRepositoryProvider.overrideWithValue(
          pathRepository ?? _TestLearningPathRepository(),
        ),
        standardRoadmapRepositoryProvider.overrideWithValue(
          standardRoadmapRepository ?? _TestStandardRoadmapRepository(),
        ),
        placementTestRepositoryProvider.overrideWithValue(
          _TestPlacementRepository(placementStatus),
        ),
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        if (profileRepository != null)
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return router;
}

class _DatePreservingProfileRepository extends Fake
    implements UserProfileRepository, StudyLevelProfileRepository {
  int loadedProfileCount = 0;
  int goalCalls = 0;
  int? currentStudyLevelId = 204;
  final int targetJlptLevelId = 204;
  final int dailyStudyMinutes = 30;
  final DateTime targetExamDate = DateTime(2030, 12, 1);

  UserProfile get _profile => UserProfile(
    userId: 42,
    email: 'learner@example.test',
    firstName: 'Learner',
    lastName: 'QA',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: 204,
    targetJlptLevelName: 'N4',
    currentStudyLevelId: currentStudyLevelId,
    currentStudyLevelName: currentStudyLevelId == 204 ? 'N4' : 'N5',
    dailyStudyMinutes: 30,
    targetExamDate: DateTime(2030, 12, 1),
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );

  @override
  Future<UserProfile> loadProfile() async {
    loadedProfileCount++;
    return _profile;
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async {
    goalCalls++;
    return _profile;
  }

  @override
  Future<UserProfile> switchStudyLevel({
    required int currentStudyLevelId,
  }) async {
    this.currentStudyLevelId = currentStudyLevelId;
    return _profile;
  }
}

class _TestLearningPathRepository
    implements LearningPathRepository, LearningPathVersionRepository {
  _TestLearningPathRepository({this.generationError, this.activePath});

  final Object? generationError;
  RecommendedLearningPath? activePath;
  int generateCalls = 0;
  int previewCalls = 0;
  int confirmCalls = 0;
  int cancelCalls = 0;
  int? lastStartingLevelId;
  int? lastTargetLevelId;

  @override
  Future<RecommendedLearningPath?> loadLatest() async => activePath;

  @override
  Future<RecommendedLearningPath?> loadActive() async => activePath;

  @override
  Future<List<RecommendedLearningPath>> loadHistory() async =>
      activePath == null ? [] : [activePath!];

  @override
  Future<RecommendedLearningPath> preview({
    required int startingJlptLevelId,
    int? targetJlptLevelId,
  }) async {
    previewCalls++;
    lastStartingLevelId = startingJlptLevelId;
    lastTargetLevelId = targetJlptLevelId;
    return _testPath(
      summary: 'Lộ trình xem trước',
      version: (activePath?.version ?? 0) + 1,
      status: LearningPathStatus.draft,
    );
  }

  @override
  Future<RecommendedLearningPath> confirmPreview(int pathId) async {
    confirmCalls++;
    activePath = _testPath(summary: 'Lộ trình đã xác nhận', version: 2);
    return activePath!;
  }

  @override
  Future<RecommendedLearningPath> cancelPreview(int pathId) async {
    cancelCalls++;
    return _testPath(
      summary: 'Lộ trình đã hủy',
      version: 2,
      status: LearningPathStatus.cancelled,
    );
  }

  @override
  Future<RecommendedLearningPath> generate() async {
    generateCalls++;
    if (generationError case final error?) throw error;
    return RecommendedLearningPath(
      userId: 42,
      generatedAt: DateTime.utc(2026, 10, 26),
      summary: 'Ưu tiên phần kiến thức còn yếu.',
      strengths: const <String>['Từ vựng'],
      weaknesses: const <String>['Ngữ pháp'],
      feasibility: 'Khả thi nếu học đều.',
      isExamDateRealistic: true,
      recommendedStudyDays: 1,
      focusTopics: const <String>['Ngữ pháp'],
      dailySchedules: const <RecommendedLearningDay>[
        RecommendedLearningDay(
          day: 1,
          title: 'Củng cố kiến thức',
          focus: 'Hoàn thành bài được đề xuất.',
          lessons: <RecommendedLesson>[
            RecommendedLesson(lessonId: 709, title: 'Bài ngữ pháp thật'),
          ],
        ),
      ],
    );
  }
}

RecommendedLearningPath _testPath({
  required String summary,
  required int version,
  LearningPathStatus status = LearningPathStatus.active,
}) => RecommendedLearningPath(
  userId: 42,
  generatedAt: DateTime.utc(2026, 10, 29),
  summary: summary,
  strengths: const [],
  weaknesses: const [],
  feasibility: 'Khả thi',
  isExamDateRealistic: true,
  recommendedStudyDays: 10,
  focusTopics: const [],
  dailySchedules: const [],
  pathId: version + 10,
  version: version,
  status: status,
);

class _TestStandardRoadmapRepository implements StandardRoadmapRepository {
  _TestStandardRoadmapRepository({this.error, this.empty = false});

  final Object? error;
  final bool empty;
  int calls = 0;

  @override
  Future<StandardRoadmap> load() async {
    calls++;
    if (error != null) throw error!;
    final lessons = empty
        ? const <StandardRoadmapLesson>[]
        : const <StandardRoadmapLesson>[
            StandardRoadmapLesson(
              lessonId: 501,
              title: 'Bài đã hoàn thành',
              sortOrder: 1,
              progressPercent: 100,
              isCompleted: true,
            ),
            StandardRoadmapLesson(
              lessonId: 502,
              title: 'Bài tiếp theo',
              sortOrder: 2,
              progressPercent: 35,
              isCompleted: false,
            ),
          ];
    return StandardRoadmap(
      currentStudyLevelId: 101,
      currentStudyLevelName: 'N5',
      targetJlptLevelId: 204,
      targetJlptLevelName: 'N4',
      learningMode: LearningMode.standard,
      totalLessons: lessons.length,
      completedLessons: lessons.where((lesson) => lesson.isCompleted).length,
      nextLessonId: lessons
          .where((lesson) => !lesson.isCompleted)
          .firstOrNull
          ?.lessonId,
      lessons: lessons,
    );
  }
}

class _TestPlacementRepository
    implements PlacementTestRepository, PlacementSkipRepository {
  const _TestPlacementRepository(this.status);

  final PlacementTestStatus status;

  @override
  Future<PlacementTestStatus> loadStatus() async => status;

  @override
  Future<PlacementTestStatus> skip() async => status;

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async => null;

  @override
  Future<PlacementTestAttempt> start() => throw UnimplementedError();

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) => throw UnimplementedError();

  @override
  Future<PlacementTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();
}

void _expectLearnTabSelected(WidgetTester tester) {
  final navigation = tester.widget<RikiBottomNavigationBar>(
    find.byType(RikiBottomNavigationBar),
  );
  expect(navigation.selectedIndex, 1);
}
