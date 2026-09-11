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
import 'package:rikipath_mobile/features/home/application/home_controller.dart';
import 'package:rikipath_mobile/features/home/data/fixture_home_repository.dart';
import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';
import 'package:rikipath_mobile/features/home/domain/home_repository.dart';
import 'package:rikipath_mobile/features/home/presentation/home_screen.dart';
import 'package:rikipath_mobile/features/learning/presentation/learn_screen.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';

void main() {
  testWidgets('home route renders HomeScreen in the learner shell', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RikiBottomNavigationBar), findsOneWidget);
  });

  testWidgets('pending repository renders the approved skeleton-style state', (
    tester,
  ) async {
    await _pumpHome(tester, repository: _PendingHomeRepository());
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('home_loading_view')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fixture success renders major approved new-learner sections', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('Xin chào, Minh Anh! 👋'), findsOneWidget);
    expect(find.text('Ngày 1'), findsOneWidget);
    expect(find.text('Tổng quan JLPT N4 & Phương pháp học'), findsOneWidget);
    expect(find.text('Lộ trình học tập cá nhân hóa'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Thiết lập ban đầu'),
      300,
    );
    expect(find.text('Thiết lập ban đầu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Làm quen với công cụ học tập'),
      300,
    );
    expect(find.text('Làm quen với công cụ học tập'), findsOneWidget);
    expect(find.text('Sổ từ & SRS'), findsOneWidget);
    expect(find.text('Luyện thi thử'), findsOneWidget);
  });

  testWidgets('repository failure renders restrained error and retry state', (
    tester,
  ) async {
    await _pumpHome(tester, repository: const _FailingHomeRepository());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home_error_view')),
      findsOneWidget,
    );
    expect(find.text('Chưa thể tải Trang chủ'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  test('Home fixture keeps the learner JLPT target typed', () {
    expect(FixtureHomeRepository.dashboard.jlptTarget, JlptLevel.n4);
    expect(JlptLevel.values, <JlptLevel>[
      JlptLevel.n5,
      JlptLevel.n4,
      JlptLevel.n3,
    ]);
  });

  testWidgets('start-learning shortcut selects the Learn branch', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('home_start_learning_button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LearnScreen), findsOneWidget);
    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 1);
  });

  testWidgets('mock-test shortcut selects the Practice branch', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    final shortcut = find.byKey(
      const ValueKey<String>('home_practice_shortcut'),
    );
    await tester.scrollUntilVisible(shortcut, 300);
    await tester.tap(shortcut);
    await tester.pumpAndSettle();

    expect(find.byType(PracticeScreen), findsOneWidget);
    final navigation = tester.widget<RikiBottomNavigationBar>(
      find.byType(RikiBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 2);
  });

  testWidgets('current Home learner scope does not introduce N1 or N2', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('N1'), findsNothing);
    expect(find.text('N2'), findsNothing);
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
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = createAppRouter(initialLocation: AppRoutes.home);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  return router;
}
