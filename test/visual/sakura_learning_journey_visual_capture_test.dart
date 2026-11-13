import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_learning_repository.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/domain/standard_roadmap.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_home_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_detail_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/sakura_learning_journey_map.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/standard_roadmap_view.dart';

void main() {
  final targetDir = Directory(
    r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce',
  );

  final mockLessons = <StandardRoadmapLesson>[
    const StandardRoadmapLesson(
      lessonId: 101,
      title: 'Chào hỏi & Giới thiệu bản thân',
      sortOrder: 1,
      progressPercent: 100,
      isCompleted: true,
    ),
    const StandardRoadmapLesson(
      lessonId: 102,
      title: 'Số đếm & Mua sắm tại Kombini',
      sortOrder: 2,
      progressPercent: 40,
      isCompleted: false,
    ),
    const StandardRoadmapLesson(
      lessonId: 103,
      title: 'Hỏi đường & Phương tiện giao thông',
      sortOrder: 3,
      progressPercent: 0,
      isCompleted: false,
    ),
    const StandardRoadmapLesson(
      lessonId: 104,
      title: 'Hẹn hò & Thời gian trong ngày',
      sortOrder: 4,
      progressPercent: 0,
      isCompleted: false,
    ),
  ];

  final mockRoadmap = StandardRoadmap(
    currentStudyLevelId: 101,
    currentStudyLevelName: 'N5',
    targetJlptLevelId: 204,
    targetJlptLevelName: 'N4',
    learningMode: LearningMode.standard,
    totalLessons: mockLessons.length,
    completedLessons: 1,
    nextLessonId: 102,
    lessons: mockLessons,
  );

  Future<void> captureScreen(
    WidgetTester tester, {
    required String fileName,
    required Widget child,
    Size size = const Size(390, 844),
  }) async {
    final boundaryKey = GlobalKey();

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            debugShowCheckedModeBanner: false,
            home: child,
          ),
        ),
      ),
    );

    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData!.buffer.asUint8List();

      final file = File('${targetDir.path}${Platform.pathSeparator}$fileName.png');
      file.writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('Saved reference capture: ${file.path} (${bytes.length} bytes)');
    });

    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('Capture 01: Learning Home with Journey Preview & N5-N2 Level Selector', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'sakura_journey_learning_home_preview',
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8F9),
        appBar: AppBar(
          title: const Text('Học tập'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF302B33),
          elevation: 0,
        ),
        body: LearningHomeView(
          snapshot: FixtureLearningRepository.snapshot,
          catalog: const AsyncData([
            JlptLevelCatalogItem(
              id: 101,
              code: 'N5',
              level: JlptLevel.n5,
              sortOrder: 1,
            ),
            JlptLevelCatalogItem(
              id: 102,
              code: 'N4',
              level: JlptLevel.n4,
              sortOrder: 2,
            ),
            JlptLevelCatalogItem(
              id: 103,
              code: 'N3',
              level: JlptLevel.n3,
              sortOrder: 3,
            ),
            JlptLevelCatalogItem(
              id: 104,
              code: 'N2',
              level: JlptLevel.n2,
              sortOrder: 4,
            ),
          ]),
          onSelectLevel: (_) {},
          onRetryCatalog: () {},
          onRefresh: () async {},
          onOpenRoadmap: () {},
          onOpenLibrary: () {},
          onOpenLesson: () {},
        ),
      ),
    );
  });

  testWidgets('Capture 02: Standard Roadmap Full S-Curve Gamified Journey Map', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'sakura_journey_standard_roadmap',
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8F9),
        appBar: AppBar(
          title: const Text('Lộ trình học chuẩn'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF302B33),
          elevation: 0,
        ),
        body: StandardRoadmapView(
          roadmap: mockRoadmap,
          onOpenLesson: (_) {},
          onRefresh: () async {},
          canGenerateAiPath: false,
          hasCompletedPlacement: false,
          isGeneratingAiPath: false,
          aiPathError: null,
          aiPath: null,
          onGenerateAiPath: () {},
        ),
      ),
    );
  });

  testWidgets('Capture 03: Current Active Hero Node with Mascot Companion', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'sakura_journey_current_node_mascot',
      size: const Size(390, 420),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8F9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SakuraLearningJourneyMap(
              lessons: mockLessons.take(2).toList(),
              currentStudyLevelName: 'N5',
              nextLessonId: 102,
              onOpenLesson: (_) {},
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('Capture 04: Japanese Cultural Milestone Headers (N5 to N2)', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'sakura_journey_milestone_headers',
      size: const Size(390, 520),
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8F9),
        appBar: AppBar(
          title: const Text('Các chặng văn hóa Nhật Bản (N5 - N2)'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF302B33),
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
            SakuraJourneyMilestoneHeader(
              levelName: 'N5',
              completedCount: 5,
              totalCount: 15,
            ),
            SizedBox(height: 12),
            SakuraJourneyMilestoneHeader(
              levelName: 'N4',
              completedCount: 0,
              totalCount: 20,
            ),
            SizedBox(height: 12),
            SakuraJourneyMilestoneHeader(
              levelName: 'N3',
              completedCount: 0,
              totalCount: 25,
            ),
            SizedBox(height: 12),
            SakuraJourneyMilestoneHeader(
              levelName: 'N2',
              completedCount: 0,
              totalCount: 30,
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('Capture 05: Real Lesson Detail View', (tester) async {
    final lesson = await const FixtureLessonRepository().loadLesson(
      FixtureLessonRepository.lesson19RouteId,
    );

    await captureScreen(
      tester,
      fileName: 'sakura_journey_lesson_detail',
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF8F9),
        appBar: AppBar(
          title: Text(lesson.title),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF302B33),
          elevation: 0,
        ),
        body: LessonDetailView(
          lesson: lesson,
          onStart: () {},
          onToggleBookmark: (_) {},
          onToggleKanji: (_) {},
          onToggleGrammar: (_) {},
        ),
      ),
    );
  });
}
