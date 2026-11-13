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
import 'package:rikipath_mobile/features/learning/presentation/lesson_catalog_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_roadmap_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/lesson_screen.dart';
import 'package:rikipath_mobile/features/grammar/presentation/grammar_library_screen.dart';
import 'package:rikipath_mobile/features/kanji/presentation/kanji_library_screen.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';
import 'package:rikipath_mobile/features/vocabulary/presentation/vocabulary_library_screen.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';

void main() {
  testWidgets('/learn separates personalized roadmap from available lessons', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learn);
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    expect(find.text('Bạn chưa có lộ trình cá nhân hóa'), findsOneWidget);
    expect(find.text('Lộ trình'), findsOneWidget);
    expect(find.text('Bài học'), findsNothing);
    expect(find.text('Thư viện'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('learning_show_existing_lessons')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library_lessons_card')), findsOneWidget);
    expect(
      find.byKey(const PageStorageKey('learning_lesson_catalog')),
      findsNothing,
    );
    await _openCatalogFromLibrary(tester);
    expect(
      find.byKey(const PageStorageKey('learning_lesson_catalog')),
      findsOneWidget,
    );
    expect(
      find.text('Cấp độ này hiện chưa có bài học được công bố.'),
      findsOneWidget,
    );
  });

  testWidgets('lesson catalog opens real lesson IDs without Placement', (
    tester,
  ) async {
    final repository = _CatalogLearningRepository();
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      repository: repository,
    );
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có lộ trình cá nhân hóa'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('learning_show_existing_lessons')),
    );
    await tester.pumpAndSettle();
    await _openCatalogFromLibrary(tester);

    expect(find.text('Bài thật từ API'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(repository.requestedLevelIds, contains(204));
    await tester.tap(find.byKey(const ValueKey('catalog_lesson_501')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId,
      '501',
    );
  });

  for (final entry in <(String, Type)>[
    ('library_vocabulary_card', VocabularyLibraryScreen),
    ('library_kanji_card', KanjiLibraryScreen),
    ('library_grammar_card', GrammarLibraryScreen),
  ]) {
    testWidgets('Library card ${entry.$1} opens its existing resource route', (
      tester,
    ) async {
      final router = await _pumpLearning(
        tester,
        initialLocation: AppRoutes.learn,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thư viện'));
      await tester.pumpAndSettle();
      final card = find.byKey(ValueKey(entry.$1));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(entry.$2), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const PageStorageKey('learning_resource_library')),
        findsOneWidget,
      );
      expect(
        find.byKey(const PageStorageKey('learning_lesson_catalog')),
        findsNothing,
      );
    });
  }

  testWidgets('library keeps the selected JLPT filter after tab switching', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learn);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('learning_section_tabs')), findsOneWidget);
    await _openCatalogFromLibrary(tester);
    await tester.tap(find.byKey(const ValueKey('learning_level_n5')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('learning_level_n5')))
          .selected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('learning_detail_back_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey('learning_resource_library')),
      findsOneWidget,
    );
    await tester.tap(find.text('Lộ trình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thư viện'));
    await tester.pumpAndSettle();
    await _openCatalogFromLibrary(tester);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('learning_level_n5')))
          .selected,
      isTrue,
    );
  });

  testWidgets(
    'AI tab uses confirmed recommendations and real lesson progress',
    (tester) async {
      final path = _testPath(
        summary: 'Lộ trình cá nhân hóa đã xác nhận',
        version: 1,
        startingLevelId: 204,
        schedules: const [
          RecommendedLearningDay(
            day: 1,
            title: 'Ngày học đầu tiên',
            focus: 'Ôn tập',
            lessons: [
              RecommendedLesson(lessonId: 501, title: 'Bài thật từ API'),
            ],
          ),
        ],
      );
      await _pumpLearning(
        tester,
        initialLocation: AppRoutes.learn,
        repository: _CatalogLearningRepository(),
        placementStatus: const PlacementTestStatus(
          hasCompletedPlacementTest: true,
          isReadyForLearningPath: true,
        ),
        pathRepository: _TestLearningPathRepository(activePath: path),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const PageStorageKey('learning_personalized_roadmap')),
        findsOneWidget,
      );
      expect(find.text('Lộ trình cá nhân hóa đã xác nhận'), findsOneWidget);
      expect(find.byKey(const ValueKey('standard_lesson_501')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('standard_roadmap_summary')),
        findsNothing,
      );
    },
  );

  testWidgets('AI journey loads progress across starting and target levels', (
    tester,
  ) async {
    final repository = _CatalogLearningRepository();
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      repository: repository,
      pathRepository: _TestLearningPathRepository(
        activePath: _testPath(
          summary: 'Lộ trình qua nhiều cấp độ',
          version: 1,
          startingLevelId: 101,
          targetLevelId: 204,
          schedules: const [
            RecommendedLearningDay(
              day: 1,
              title: 'Ôn tập nhiều cấp độ',
              focus: 'Bài học tiếp theo',
              lessons: [
                RecommendedLesson(lessonId: 501, title: 'Bài thật từ API'),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedLevelIds, containsAll([101, 204]));
    expect(find.byKey(const ValueKey('standard_lesson_501')), findsOneWidget);
    expect(find.text('Đã hoàn thành 0/1 bài học'), findsOneWidget);
  });

  testWidgets(
    'mismatched level response is not shown under a different filter',
    (tester) async {
      final profile = _DatePreservingProfileRepository();
      await _pumpLearning(
        tester,
        initialLocation: AppRoutes.learn,
        repository: _CatalogLearningRepository(),
        profileRepository: profile,
      );
      await tester.pumpAndSettle();
      await _openCatalogFromLibrary(tester);
      await tester.tap(find.byKey(const ValueKey('learning_level_n5')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Dữ liệu bài học không khớp cấp độ đã chọn. Vui lòng tải lại.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('catalog_lesson_501')), findsNothing);
      expect(profile.currentStudyLevelId, 204);
    },
  );

  testWidgets(
    'AI home does not guess the next lesson if progress is unavailable',
    (tester) async {
      final path = _testPath(
        summary: 'Lộ trình có dữ liệu đề xuất',
        version: 1,
        startingLevelId: 204,
        schedules: const [
          RecommendedLearningDay(
            day: 1,
            title: 'Ngày một',
            focus: 'Ôn tập',
            lessons: [
              RecommendedLesson(lessonId: 501, title: 'Bài được đề xuất'),
            ],
          ),
        ],
      );
      await _pumpLearning(
        tester,
        initialLocation: AppRoutes.learn,
        repository: const _FailingLearningRepository(),
        placementStatus: const PlacementTestStatus(
          hasCompletedPlacementTest: true,
          isReadyForLearningPath: true,
        ),
        pathRepository: _TestLearningPathRepository(activePath: path),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bài học tiếp theo'), findsNothing);
      expect(find.text('Bài được đề xuất'), findsOneWidget);
      expect(find.text('Thử tải lại tiến độ bài học'), findsOneWidget);
    },
  );

  testWidgets('draft path is not presented as active AI roadmap', (
    tester,
  ) async {
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      placementStatus: const PlacementTestStatus(
        hasCompletedPlacementTest: true,
        isReadyForLearningPath: true,
      ),
      pathRepository: _TestLearningPathRepository(
        activePath: _testPath(
          summary: 'Bản xem trước chưa xác nhận',
          version: 2,
          status: LearningPathStatus.draft,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bản xem trước chưa xác nhận'), findsNothing);
    expect(find.text('Bản xem trước đang chờ xác nhận'), findsOneWidget);
  });

  for (final width in <double>[360, 393, 412]) {
    for (final scale in <double>[1.3, 2.0]) {
      testWidgets(
        'Learning tabs remain usable at ${width}dp and ${scale}x text',
        (tester) async {
          await _pumpLearning(
            tester,
            initialLocation: AppRoutes.learn,
            viewportSize: Size(width, 780),
            textScale: scale,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Thư viện'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const PageStorageKey('learning_lesson_catalog')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('library_lessons_card')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Lộ trình'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const PageStorageKey('learning_lesson_catalog')),
            findsNothing,
          );
          await tester.tap(find.text('Thư viện'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const PageStorageKey('learning_resource_library')),
            findsOneWidget,
          );
          await _openCatalogFromLibrary(tester);
          expect(find.byType(LessonCatalogScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

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

    await _openCatalogFromLibrary(tester);
    final level = find.byKey(const ValueKey<String>('learning_level_n5'));
    await tester.ensureVisible(level);
    await tester.tap(level);
    await tester.pumpAndSettle();
    expect(repository.currentStudyLevelId, 204);
    await tester.tap(find.byKey(const ValueKey('learning_set_study_level')));
    await tester.pumpAndSettle();
    expect(find.text('Đổi cấp độ đang học?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('confirm_current_study_level_change')),
    );
    await tester.pumpAndSettle();

    expect(repository.loadedProfileCount, greaterThan(0));
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
    await _openCatalogFromLibrary(tester);
    final level = find.byKey(const ValueKey<String>('learning_level_n5'));
    await tester.ensureVisible(level);
    await tester.tap(level);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('learning_set_study_level')));
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

  testWidgets('Learn offers study levels N5 to N2 and restricts N1', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learn);
    await tester.pumpAndSettle();
    await _openCatalogFromLibrary(tester);

    expect(
      find.byKey(const ValueKey<String>('learning_level_n5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('learning_level_n4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('learning_level_n3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('learning_level_n2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('learning_level_n1')),
      findsNothing,
    );
  });

  testWidgets('eligible learner can open roadmap creation inside Learn', (
    tester,
  ) async {
    await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      placementStatus: const PlacementTestStatus(
        hasCompletedPlacementTest: true,
        isReadyForLearningPath: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('learning_roadmap_primary_action')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LearningRoadmapScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('standard_roadmap_summary')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('ai_personalized_path_section')),
      findsOneWidget,
    );
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
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('ai_learning_path_generate_button')),
      );
      await tester.pumpAndSettle();
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

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('ai_learning_path_generate_button')),
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

  testWidgets('confirmed replacement stays active after returning to Learn', (
    tester,
  ) async {
    final repository = _TestLearningPathRepository(
      activePath: _testPath(summary: 'Lộ trình đang học', version: 1),
    );
    final router = await _pumpLearning(
      tester,
      initialLocation: AppRoutes.learn,
      repository: _CatalogLearningRepository(),
      placementStatus: const PlacementTestStatus(
        hasCompletedPlacementTest: true,
        isReadyForLearningPath: true,
      ),
      pathRepository: repository,
    );
    await tester.pumpAndSettle();
    expect(find.text('Lộ trình đang học'), findsOneWidget);
    expect(find.text('Tạo lộ trình cá nhân hóa'), findsNothing);

    final manage = find.text('Quản lý lộ trình');
    await tester.ensureVisible(manage);
    await tester.pumpAndSettle();
    await tester.tap(manage);
    await tester.pumpAndSettle();
    expect(find.byType(LearningRoadmapScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('standard_roadmap_summary')),
      findsNothing,
    );
    final regenerate = find.byKey(
      const ValueKey<String>('ai_learning_path_generate_button'),
    );
    await tester.tap(regenerate);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('ai_learning_path_confirm_preview')),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.learn);
    await tester.pumpAndSettle();
    expect(find.text('Lộ trình đã xác nhận'), findsOneWidget);
    expect(
      find.byKey(const PageStorageKey('learning_personalized_roadmap')),
      findsOneWidget,
    );
    expect(find.text('Tạo lộ trình cá nhân hóa'), findsNothing);
  });

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

  testWidgets(
    'existing AI path remains visible when regeneration is unavailable',
    (tester) async {
      final pathRepository = _TestLearningPathRepository(
        activePath: _testPath(
          summary: 'Lộ trình đã lưu từ Backend',
          version: 1,
        ),
      );
      await _pumpLearning(
        tester,
        initialLocation: AppRoutes.learnRoadmap,
        pathRepository: pathRepository,
      );
      await tester.pumpAndSettle();

      expect(find.text('Lộ trình đã lưu từ Backend'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('standard_lesson_501')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('ai_learning_path_generate_button')),
        findsNothing,
      );
    },
  );

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
    await tester.pumpAndSettle();
    await _openCatalogFromLibrary(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey<String>('learning_catalog_loading')),
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
      await _openCatalogFromLibrary(tester);

      expect(
        find.byKey(const ValueKey<String>('learning_catalog_state')),
        findsOneWidget,
      );
      expect(
        find.text('Không thể tải bài học. Vui lòng kiểm tra kết nối.'),
        findsOneWidget,
      );
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

class _CatalogLearningRepository implements LearningRepository {
  final List<int> requestedLevelIds = [];

  @override
  Future<LearningSnapshot> loadLearningSnapshot({
    required int certificateLevelId,
  }) async {
    requestedLevelIds.add(certificateLevelId);
    return const LearningSnapshot(
      initials: '',
      jlptTarget: JlptLevel.n4,
      streakDays: 0,
      hasUnreadNotifications: false,
      examDateLabel: '',
      overallProgress: 0.25,
      completedLessons: 0,
      totalLessons: 1,
      completedChapters: 0,
      totalChapters: 0,
      metrics: [],
      currentLesson: CurrentLessonSummary(
        routeId: '501',
        chapterNumber: 1,
        lessonNumber: 1,
        title: 'Bài thật từ API',
        category: 'Từ vựng',
        pattern: '',
        durationMinutes: 10,
        progress: 0.25,
      ),
      sections: [],
      chapters: [],
      skillProgress: [],
      certificateLevelId: 204,
      lessons: [
        LearningLessonSummary(
          lessonId: 501,
          title: 'Bài thật từ API',
          description: 'Nội dung trả về từ repository kiểm thử',
          sortOrder: 1,
          languageSkillId: 1,
          languageSkillName: 'Từ vựng',
          progressPercent: 25,
          resumePositionSeconds: 12,
          isCompleted: false,
        ),
      ],
    );
  }
}

Future<void> _openCatalogFromLibrary(
  WidgetTester tester, {
  bool settle = true,
}) async {
  if (find
      .byKey(const PageStorageKey('learning_resource_library'))
      .evaluate()
      .isEmpty) {
    await tester.tap(find.text('Thư viện'));
    await tester.pumpAndSettle();
  }
  final card = find.byKey(const ValueKey('library_lessons_card'));
  await tester.ensureVisible(card);
  await tester.tap(card);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
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
  double textScale = 1,
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
        userProfileRepositoryProvider.overrideWithValue(
          profileRepository ?? _DatePreservingProfileRepository(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
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
  int? startingLevelId,
  int? targetLevelId,
  List<RecommendedLearningDay> schedules = const [],
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
  dailySchedules: schedules,
  startingJlptLevelId: startingLevelId,
  targetJlptLevelId: targetLevelId,
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
