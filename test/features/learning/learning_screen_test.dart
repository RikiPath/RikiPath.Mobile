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
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/learning/application/learning_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';
import 'package:rikipath_mobile/features/learning/presentation/jlpt_progress_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learning_roadmap_screen.dart';

import '../../support/test_auth_session.dart';
import '../../support/test_jlpt_catalog.dart';

void main() {
  testWidgets('/learn renders the approved Learning Home hierarchy', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learn);
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    expect(find.text('Mục tiêu JLPT N4'), findsOneWidget);
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
    expect(find.text('TIẾN ĐỘ TỔNG THỂ'), findsOneWidget);
    _expectLearnTabSelected(tester);
  });

  testWidgets('roadmap renders completed, current, and locked states', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learnRoadmap);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('roadmap_chapter_completed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('roadmap_chapter_current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('roadmap_chapter_locked')),
      findsOneWidget,
    );
    expect(find.text('Hoàn thành'), findsOneWidget);
    expect(find.text('Đang học'), findsOneWidget);
    expect(find.text('Chưa bắt đầu'), findsOneWidget);
    _expectLearnTabSelected(tester);
  });

  testWidgets('completed roadmap chapter opens JLPT level progress', (
    tester,
  ) async {
    await _pumpLearning(tester, initialLocation: AppRoutes.learnRoadmap);
    await tester.pumpAndSettle();

    final progressButton = find.byKey(
      const ValueKey<String>('roadmap_open_progress_button'),
    );
    await tester.scrollUntilVisible(progressButton, 200);
    await tester.tap(progressButton);
    await tester.pumpAndSettle();

    expect(find.byType(JlptProgressScreen), findsOneWidget);
    expect(find.text('Chi tiết tiến độ kỹ năng'), findsOneWidget);
    _expectLearnTabSelected(tester);
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
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return router;
}

void _expectLearnTabSelected(WidgetTester tester) {
  final navigation = tester.widget<RikiBottomNavigationBar>(
    find.byType(RikiBottomNavigationBar),
  );
  expect(navigation.selectedIndex, 1);
}
