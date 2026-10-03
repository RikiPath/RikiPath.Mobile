import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/analytics/domain/analytics_repository.dart';
import 'package:rikipath_mobile/features/analytics/domain/learner_analytics.dart';
import 'package:rikipath_mobile/features/analytics/presentation/learner_analytics_screen.dart';
import 'package:rikipath_mobile/features/home/application/home_controller.dart';
import 'package:rikipath_mobile/features/home/data/fixture_home_repository.dart';
import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';
import 'package:rikipath_mobile/features/home/domain/home_repository.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/notifications/application/notification_controller.dart';
import 'package:rikipath_mobile/features/notifications/domain/app_notification.dart';
import 'package:rikipath_mobile/features/notifications/domain/notification_repository.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';
import 'package:rikipath_mobile/features/practice/domain/practice_session_repository.dart';

import '../../support/test_auth_session.dart';

void main() {
  testWidgets('home route renders HomeScreen in the learner shell', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
  });

  testWidgets('pending greeting fixture does not block section-level Home', (
    tester,
  ) async {
    await _pumpHome(tester, repository: _PendingHomeRepository());
    await tester.pump();
    await tester.pump();

    expect(find.byType(RikiSkeleton), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('home_choose_jlpt_card')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fixture success renders the composed learner dashboard', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('Xin chào, Minh Anh! 👋'), findsOneWidget);
    expect(find.text('Chọn mục tiêu JLPT để bắt đầu'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Thống kê học tập'), 300);
    expect(find.text('Thống kê học tập'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ôn tập hôm nay'), 300);
    expect(find.text('Ôn tập hôm nay'), findsOneWidget);
  });

  testWidgets('greeting repository failure remains isolated and retryable', (
    tester,
  ) async {
    await _pumpHome(tester, repository: const _FailingHomeRepository());
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải Trang chủ'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('home_choose_jlpt_card')),
      findsOneWidget,
    );
  });

  test('Home fixture keeps the learner JLPT scope typed', () {
    expect(FixtureHomeRepository.dashboard.jlptTarget, JlptLevel.n4);
    expect(JlptLevel.values, <JlptLevel>[
      JlptLevel.n5,
      JlptLevel.n4,
      JlptLevel.n3,
    ]);
  });

  testWidgets('level-selection shortcut selects the Learn branch', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chọn mục tiêu'));
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 1);
  });

  testWidgets('progress action opens the shared Analytics screen', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    final label = find.text('Xem tiến độ');
    await tester.scrollUntilVisible(label, 260);
    tester
        .widget<TextButton>(
          find.ancestor(of: label, matching: find.byType(TextButton)),
        )
        .onPressed!();
    await tester.pumpAndSettle();

    expect(find.byType(LearnerAnalyticsScreen), findsOneWidget);
  });

  testWidgets('current Home learner scope does not introduce N1 or N2', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('N1'), findsNothing);
    expect(find.text('N2'), findsNothing);
  });

  testWidgets('composed Home remains usable at 320px portrait width', (
    tester,
  ) async {
    await _pumpHome(tester, width: 320);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('home_notebook_shortcut')),
      300,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('home_notebook_shortcut')),
      findsOneWidget,
    );
  });
}

class _PendingHomeRepository implements HomeRepository {
  final Completer<HomeDashboard> _completer = Completer<HomeDashboard>();

  @override
  Future<HomeDashboard> loadDashboard() => _completer.future;
}

class _FailingHomeRepository implements HomeRepository {
  const _FailingHomeRepository();

  @override
  Future<HomeDashboard> loadDashboard() {
    return Future<HomeDashboard>.error(StateError('fixture failure'));
  }
}

Future<GoRouter> _pumpHome(
  WidgetTester tester, {
  HomeRepository repository = const FixtureHomeRepository(),
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = createTestAuthSession();
  final router = createAppRouter(
    authSession: session,
    initialLocation: AppRoutes.home,
  );
  addTearDown(session.dispose);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repository),
        analyticsRepositoryProvider.overrideWithValue(
          const _AnalyticsRepository(),
        ),
        notificationRepositoryProvider.overrideWithValue(
          const _NotificationRepository(),
        ),
        practiceSessionRepositoryProvider.overrideWithValue(
          _PracticeSessionRepository(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  return router;
}

class _AnalyticsRepository implements AnalyticsRepository {
  const _AnalyticsRepository();

  @override
  Future<LearnerAnalytics> loadLearnerAnalytics() async {
    return const LearnerAnalytics(
      streakDays: 4,
      completedLessons: 7,
      totalLessons: 20,
      skills: <SkillBreakdown>[
        SkillBreakdown(skill: 'Kanji', averageScore: 30, attemptCount: 10),
      ],
    );
  }
}

class _NotificationRepository implements NotificationRepository {
  const _NotificationRepository();

  @override
  Future<List<AppNotification>> loadNotifications({
    bool unreadOnly = false,
  }) async => const <AppNotification>[];

  @override
  Future<int> loadUnreadCount() async => 0;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> markRead(int notificationId) async {}
}

class _PracticeSessionRepository implements PracticeSessionRepository {
  DemoPracticeSessions? _sessions;

  @override
  Future<DemoPracticeSessions?> load({
    required List<DemoReviewCard> reviewCards,
    required DemoMockTest mockTest,
  }) async {
    return _sessions ??
        DemoPracticeSessions(
          reviewSession: DemoReviewSession(cards: reviewCards),
        );
  }

  @override
  Future<void> reset() async {
    _sessions = null;
  }

  @override
  Future<void> save(DemoPracticeSessions sessions) async {
    _sessions = sessions;
  }
}
