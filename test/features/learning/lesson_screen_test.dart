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
import 'package:rikipath_mobile/features/learning/application/lesson_controller.dart';
import 'package:rikipath_mobile/features/learning/data/fixture_lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/data/lesson_media_driver.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_repository.dart';
import 'package:rikipath_mobile/features/learning/presentation/lesson_screen.dart';

import '../../support/test_auth_session.dart';
import 'package:video_player/video_player.dart';

void main() {
  test('lesson route uses the supported nested Learn path', () {
    expect(
      AppRoutes.lesson(FixtureLessonRepository.lesson19RouteId),
      '/learn/lesson/fixture-n4-grammar-lesson-19',
    );
  });

  test('lesson fixtures remain within the N5, N4, and N3 scope', () async {
    const repository = FixtureLessonRepository();
    final current = await repository.loadLesson(
      FixtureLessonRepository.lesson19RouteId,
    );
    final locked = await repository.loadLesson(
      FixtureLessonRepository.lesson20RouteId,
    );

    expect(JlptLevel.values, <JlptLevel>[
      JlptLevel.n5,
      JlptLevel.n4,
      JlptLevel.n3,
    ]);
    expect(<JlptLevel>{current.level, locked.level}, {JlptLevel.n4});
  });

  test('fixture lesson IDs are not presented as backend lesson IDs', () async {
    const repository = FixtureLessonRepository();

    final current = await repository.loadLesson(
      FixtureLessonRepository.lesson19RouteId,
    );
    final locked = await repository.loadLesson(
      FixtureLessonRepository.lesson20RouteId,
    );

    expect(current.remoteLessonId, isNull);
    expect(locked.remoteLessonId, isNull);
  });

  testWidgets('lesson detail renders the approved major sections', (
    tester,
  ) async {
    await _pumpLesson(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('lesson_detail_view')),
      findsOneWidget,
    );
    expect(find.text('Thể quá khứ & Liệt kê hành động'), findsOneWidget);
    expect(find.text('Mục tiêu bài học'), findsOneWidget);
    expect(find.text('40% • Đang học'), findsOneWidget);

    await _scrollWithin(
      tester,
      viewKey: 'lesson_detail_view',
      target: find.text('Nội dung bài học (4 phần)'),
    );
    expect(find.text('Nội dung bài học (4 phần)'), findsOneWidget);
    await _scrollWithin(
      tester,
      viewKey: 'lesson_detail_view',
      target: find.text('Từ vựng trọng tâm trong bài'),
    );
    expect(find.text('Từ vựng trọng tâm trong bài'), findsOneWidget);
    await _scrollWithin(
      tester,
      viewKey: 'lesson_detail_view',
      target: find.text('Ngữ pháp liên quan'),
    );
    expect(find.text('Ngữ pháp liên quan'), findsOneWidget);
  });

  testWidgets('Learning Home continue action opens lesson detail', (
    tester,
  ) async {
    await _pumpLesson(tester, initialLocation: AppRoutes.learn);
    await tester.pumpAndSettle();

    final continueButton = find.byKey(
      const ValueKey<String>('learning_continue_lesson_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'learning_home_success_view',
      target: continueButton,
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('lesson_detail_view')),
      findsOneWidget,
    );
  });

  testWidgets('roadmap current lesson action opens lesson detail', (
    tester,
  ) async {
    await _pumpLesson(tester, initialLocation: AppRoutes.learnRoadmap);
    await tester.pumpAndSettle();

    final continueButton = find.byKey(
      const ValueKey<String>('roadmap_continue_lesson_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'learning_roadmap_success_view',
      target: continueButton,
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('Bài 19'), findsOneWidget);
  });

  testWidgets('lesson route remains inside the selected Learn tab', (
    tester,
  ) async {
    await _pumpLesson(tester);
    await tester.pumpAndSettle();

    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 1);
  });

  testWidgets('pending lesson repository renders the loading state', (
    tester,
  ) async {
    await _pumpLesson(tester, repository: _PendingLessonRepository());
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('lesson_loading_view')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed lesson repository renders the retry state', (
    tester,
  ) async {
    await _pumpLesson(tester, repository: const _FailingLessonRepository());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('lesson_load_error_view')),
      findsOneWidget,
    );
    expect(find.text('Chưa thể tải bài học'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('lesson_load_retry_button')),
      findsOneWidget,
    );
  });

  testWidgets('video resumes at the fixture position and can be paused', (
    tester,
  ) async {
    final mediaDriver = _RecordingMediaDriver();
    await _pumpLesson(tester, mediaDriver: mediaDriver);
    await tester.pumpAndSettle();

    final startButton = find.byKey(
      const ValueKey<String>('lesson_start_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'lesson_detail_view',
      target: startButton,
    );
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(
      mediaDriver.resumePosition,
      const Duration(minutes: 12, seconds: 30),
    );
    expect(
      find.byKey(const ValueKey<String>('lesson_video_status_playing')),
      findsOneWidget,
    );
    expect(find.text('12:30'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('lesson_video_toggle_button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('lesson_video_status_paused')),
      findsOneWidget,
    );
    expect(mediaDriver.pauseCalls, 1);
  });

  testWidgets('video exposes loading, ready, and playing states', (
    tester,
  ) async {
    final mediaDriver = _ControlledMediaDriver();
    await _pumpLesson(tester, mediaDriver: mediaDriver);
    await tester.pumpAndSettle();

    final startButton = find.byKey(
      const ValueKey<String>('lesson_start_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'lesson_detail_view',
      target: startButton,
    );
    await tester.tap(startButton);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('lesson_video_status_loading')),
      findsOneWidget,
    );

    mediaDriver.initializeCompleter.complete();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('lesson_video_status_ready')),
      findsOneWidget,
    );

    mediaDriver.playCompleter.complete();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('lesson_video_status_playing')),
      findsOneWidget,
    );
  });

  testWidgets('media failure offers retry and article fallback', (
    tester,
  ) async {
    await _pumpLesson(tester, mediaDriver: const _FailingMediaDriver());
    await tester.pumpAndSettle();

    final startButton = find.byKey(
      const ValueKey<String>('lesson_start_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'lesson_detail_view',
      target: startButton,
    );
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('lesson_video_status_error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('lesson_video_retry_button')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('lesson_show_article_button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('lesson_article_view')),
      findsOneWidget,
    );
  });

  testWidgets('completing video shows mastery, XP, and next lesson actions', (
    tester,
  ) async {
    await _pumpLesson(tester);
    await tester.pumpAndSettle();

    final startButton = find.byKey(
      const ValueKey<String>('lesson_start_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'lesson_detail_view',
      target: startButton,
    );
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    final completeButton = find.byKey(
      const ValueKey<String>('lesson_complete_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'lesson_video_view',
      target: completeButton,
    );
    await tester.tap(completeButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('lesson_completion_view')),
      findsOneWidget,
    );
    expect(find.text('100% HOÀN THÀNH'), findsOneWidget);
    expect(find.text('+30 XP'), findsOneWidget);
    await _scrollWithin(
      tester,
      viewKey: 'lesson_completion_view',
      target: find.byKey(const ValueKey<String>('lesson_next_button')),
    );
    expect(find.text('Học bài tiếp theo (Bài 20)'), findsOneWidget);
  });

  testWidgets('lesson progress is rendered from repository data', (
    tester,
  ) async {
    await _pumpLesson(
      tester,
      repository: const _ProgressLessonRepository(progressPercent: 63),
    );
    await tester.pumpAndSettle();

    expect(find.text('63% • Đang học'), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.63);
  });

  testWidgets('lesson states do not overflow on a 320px portrait phone', (
    tester,
  ) async {
    final router = await _pumpLesson(
      tester,
      viewportSize: const Size(320, 700),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final startButton = find.byKey(
      const ValueKey<String>('lesson_start_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'lesson_detail_view',
      target: startButton,
    );
    await tester.tap(startButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final completeButton = find.byKey(
      const ValueKey<String>('lesson_complete_button'),
    );
    await _scrollWithin(
      tester,
      viewKey: 'lesson_video_view',
      target: completeButton,
    );
    await tester.tap(completeButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    router.go(AppRoutes.lesson(FixtureLessonRepository.lesson20RouteId));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('lesson_locked_view')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('learning presentation contains no direct Dio usage', () {
    final dartFiles = Directory('lib/features/learning/presentation')
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

class _PendingLessonRepository implements LessonRepository {
  final Completer<Lesson> _completer = Completer<Lesson>();

  @override
  Future<Lesson> loadLesson(String routeId) => _completer.future;

  @override
  Future<LessonProgress> updatePlaybackPosition({
    required String routeId,
    required int positionSeconds,
    required int durationSeconds,
  }) {
    throw UnsupportedError('No lesson is loaded.');
  }
}

class _FailingLessonRepository implements LessonRepository {
  const _FailingLessonRepository();

  @override
  Future<Lesson> loadLesson(String routeId) {
    return Future<Lesson>.error(StateError('fixture failure'));
  }

  @override
  Future<LessonProgress> updatePlaybackPosition({
    required String routeId,
    required int positionSeconds,
    required int durationSeconds,
  }) {
    throw UnsupportedError('No lesson is loaded.');
  }
}

class _ProgressLessonRepository implements LessonRepository {
  const _ProgressLessonRepository({required this.progressPercent});

  final int progressPercent;

  @override
  Future<Lesson> loadLesson(String routeId) async {
    final lesson = await const FixtureLessonRepository().loadLesson(routeId);
    return lesson.copyWith(
      progress: LessonProgress(
        progressPercent: progressPercent,
        resumePositionSeconds: lesson.progress.resumePositionSeconds,
        isCompleted: false,
      ),
    );
  }

  @override
  Future<LessonProgress> updatePlaybackPosition({
    required String routeId,
    required int positionSeconds,
    required int durationSeconds,
  }) {
    return const FixtureLessonRepository().updatePlaybackPosition(
      routeId: routeId,
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
    );
  }
}

class _RecordingMediaDriver implements LessonMediaDriver {
  Duration? resumePosition;
  int pauseCalls = 0;

  @override
  VideoPlayerController? get videoController => null;

  @override
  Future<void> initialize({
    required LessonMediaSource source,
    required Duration resumePosition,
  }) async {
    this.resumePosition = resumePosition;
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  void dispose() {}
}

class _ControlledMediaDriver implements LessonMediaDriver {
  final Completer<void> initializeCompleter = Completer<void>();
  final Completer<void> playCompleter = Completer<void>();

  @override
  VideoPlayerController? get videoController => null;

  @override
  Future<void> initialize({
    required LessonMediaSource source,
    required Duration resumePosition,
  }) => initializeCompleter.future;

  @override
  Future<void> play() => playCompleter.future;

  @override
  Future<void> pause() async {}

  @override
  void dispose() {}
}

class _FailingMediaDriver implements LessonMediaDriver {
  const _FailingMediaDriver();

  @override
  VideoPlayerController? get videoController => null;

  @override
  Future<void> initialize({
    required LessonMediaSource source,
    required Duration resumePosition,
  }) {
    return Future<void>.error(StateError('fixture media failure'));
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  void dispose() {}
}

Future<GoRouter> _pumpLesson(
  WidgetTester tester, {
  String initialLocation =
      '/learn/lesson/${FixtureLessonRepository.lesson19RouteId}',
  LessonRepository repository = const FixtureLessonRepository(),
  LessonMediaDriver mediaDriver = const FixtureLessonMediaDriver(),
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
        lessonRepositoryProvider.overrideWithValue(repository),
        lessonMediaDriverFactoryProvider.overrideWithValue(() => mediaDriver),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return router;
}

Future<void> _scrollWithin(
  WidgetTester tester, {
  required String viewKey,
  required Finder target,
}) async {
  final view = find.byKey(ValueKey<String>(viewKey));
  final scrollable = find
      .descendant(of: view, matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(target, 240, scrollable: scrollable);
  await tester.pumpAndSettle();
}
