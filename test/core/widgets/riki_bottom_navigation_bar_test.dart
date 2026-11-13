import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_bottom_navigation_bar.dart';

void main() {
  testWidgets('renders all five approved learner destinations', (tester) async {
    await _pumpNavigation(tester, selectedIndex: 0);

    for (final label in <String>[
      'Trang chủ',
      'Học tập',
      'Luyện tập',
      'Sổ từ',
      'Cá nhân',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('selected destination has selected semantics and filled icon', (
    tester,
  ) async {
    await _pumpNavigation(tester, selectedIndex: 2);

    final semantics = tester.widget<Semantics>(
      find.byKey(const ValueKey<String>('bottom_navigation_item_Luyện tập')),
    );
    expect(semantics.properties.selected, isTrue);
    expect(find.byIcon(Icons.quiz), findsOneWidget);
    expect(find.byIcon(Icons.quiz_outlined), findsNothing);

    final indicator = tester.widget<Container>(
      find.byKey(const ValueKey<String>('sakura_floating_active_indicator')),
    );
    final decoration = indicator.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.gradient, isA<LinearGradient>());
    expect((decoration.gradient! as LinearGradient).colors, const [
      AppColors.sakura400,
      AppColors.brandPrimary,
    ]);
  });

  testWidgets('destinations keep equal width and can wrap for accessibility', (
    tester,
  ) async {
    await _pumpNavigation(tester, selectedIndex: 0);

    const labels = <String>[
      'Trang chủ',
      'Học tập',
      'Luyện tập',
      'Sổ từ',
      'Cá nhân',
    ];
    expect(RikiBottomNavigationBar.destinationCount, labels.length);
    for (final destinationLabel in labels) {
      final label = tester.widget<Text>(find.text(destinationLabel));
      expect(label.maxLines, 2);
    }

    final itemWidths = labels.map((destinationLabel) {
      return tester
          .getSize(
            find.byKey(
              ValueKey<String>('bottom_navigation_item_$destinationLabel'),
            ),
          )
          .width;
    }).toSet();
    expect(itemWidths, hasLength(1));
  });

  testWidgets('labels remain visible at 412px and 2x text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpNavigation(tester, selectedIndex: 0, textScale: 2);

    expect(tester.getSize(find.byType(RikiBottomNavigationBar)).height, 112);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation grows before labels overflow at 1.3x text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpNavigation(tester, selectedIndex: 3, textScale: 1.3);

    expect(
      tester.getSize(find.byType(RikiBottomNavigationBar)).height,
      greaterThan(64),
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in <double>[360, 393, 412]) {
    testWidgets('navigation stays bounded at ${width}dp with 2x labels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pumpNavigation(tester, selectedIndex: 4, textScale: 2);
      expect(tester.takeException(), isNull);
      final indicator = tester.getRect(
        find.byKey(const ValueKey<String>('sakura_floating_active_indicator')),
      );
      expect(indicator.right, lessThanOrEqualTo(width));
    });
  }

  testWidgets('bottom system inset remains part of the navigation surface', (
    tester,
  ) async {
    await _pumpNavigation(tester, selectedIndex: 0, bottomInset: 24);
    expect(tester.getSize(find.byType(RikiBottomNavigationBar)).height, 88);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination tap reports its index', (tester) async {
    int? selected;
    await _pumpNavigation(
      tester,
      selectedIndex: 0,
      onDestinationSelected: (index) => selected = index,
    );

    await tester.tap(find.text('Cá nhân'));
    expect(selected, 4);
  });

  testWidgets('renders concise Japanese destination labels', (tester) async {
    await _pumpNavigation(tester, selectedIndex: 0, locale: const Locale('ja'));

    for (final label in <String>['ホーム', '学習', '練習', '単語帳', 'マイページ']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('circle and elastic notch share one animated center', (
    tester,
  ) async {
    await _pumpNavigation(tester, selectedIndex: 0);
    await _pumpNavigation(tester, selectedIndex: 2);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.quiz), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 110));

    final painter = _notchPainter(tester);
    final barWidth = tester.getSize(find.byType(RikiBottomNavigationBar)).width;
    final geometry = painter.geometryFor(Size(barWidth, 64));
    final circleCenter = tester.getCenter(
      find.byKey(const ValueKey<String>('sakura_floating_active_indicator')),
    );
    expect(geometry.centerX, closeTo(circleCenter.dx, 0.01));
    expect(geometry.pull, greaterThan(0));
    expect(
      geometry.rightEnd - geometry.centerX,
      greaterThan(geometry.centerX - geometry.leftStart),
    );

    await tester.pumpAndSettle();
    final settled = _notchPainter(tester).geometryFor(Size(barWidth, 64));
    expect(settled.centerX, closeTo(barWidth / 2, 0.1));
    expect(settled.pull, 0);
    expect(
      settled.rightEnd - settled.centerX,
      closeTo(settled.centerX - settled.leftStart, 0.01),
    );
  });

  testWidgets('distant selection travels and settles without an instant snap', (
    tester,
  ) async {
    await _pumpNavigation(tester, selectedIndex: 0);
    final start = tester
        .getCenter(
          find.byKey(
            const ValueKey<String>('sakura_floating_active_indicator'),
          ),
        )
        .dx;
    await _pumpNavigation(tester, selectedIndex: 4);
    await tester.pump(const Duration(milliseconds: 150));
    final moving = tester
        .getCenter(
          find.byKey(
            const ValueKey<String>('sakura_floating_active_indicator'),
          ),
        )
        .dx;
    final width = tester.getSize(find.byType(RikiBottomNavigationBar)).width;
    final target = width * 0.9;
    expect(moving, greaterThan(start + 12));
    expect(moving, lessThan(target - 12));

    await tester.pump(const Duration(milliseconds: 300));
    final landing = tester
        .getCenter(
          find.byKey(
            const ValueKey<String>('sakura_floating_active_indicator'),
          ),
        )
        .dx;
    expect(landing, closeTo(target, 5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid reverse starts from the current visual position', (
    tester,
  ) async {
    await _pumpNavigation(tester, selectedIndex: 0);
    await _pumpNavigation(tester, selectedIndex: 4);
    await tester.pump(const Duration(milliseconds: 120));
    final beforeRetarget = tester.getCenter(
      find.byKey(const ValueKey<String>('sakura_floating_active_indicator')),
    );

    await _pumpNavigation(tester, selectedIndex: 2);
    final afterRetarget = tester.getCenter(
      find.byKey(const ValueKey<String>('sakura_floating_active_indicator')),
    );
    expect(afterRetarget.dx, closeTo(beforeRetarget.dx, 1));

    await tester.pumpAndSettle();
    final barWidth = tester.getSize(find.byType(RikiBottomNavigationBar)).width;
    final settled = tester.getCenter(
      find.byKey(const ValueKey<String>('sakura_floating_active_indicator')),
    );
    expect(settled.dx, closeTo(barWidth / 2, 0.5));
    expect(
      tester
          .widget<Semantics>(
            find.byKey(
              const ValueKey<String>('bottom_navigation_item_Luyện tập'),
            ),
          )
          .properties
          .selected,
      isTrue,
    );
  });

  testWidgets('reduced motion snaps indicator and removes deformation', (
    tester,
  ) async {
    await _pumpNavigation(tester, selectedIndex: 0, disableAnimations: true);
    await _pumpNavigation(tester, selectedIndex: 4, disableAnimations: true);
    final barWidth = tester.getSize(find.byType(RikiBottomNavigationBar)).width;
    final geometry = _notchPainter(tester).geometryFor(Size(barWidth, 64));
    expect(geometry.centerX, closeTo(barWidth * 0.9, 0.1));
    expect(geometry.pull, 0);
  });

  test('notch geometry stays within first and last tab edges', () {
    for (final position in <double>[0, 4]) {
      for (final velocity in <double>[-18, 0, 18]) {
        final painter = SakuraCurvedNavigationPainter(
          activePosition: position,
          velocity: velocity,
          itemCount: 5,
          backgroundColor: Colors.white,
          bumpHeight: 15,
          baselineOffset: 18,
          bumpHalfWidth: 36,
          shadowColor: Colors.black,
        );
        final geometry = painter.geometryFor(const Size(360, 64));
        expect(geometry.leftStart, greaterThanOrEqualTo(0));
        expect(geometry.rightEnd, lessThanOrEqualTo(360));
        expect(geometry.leftStart, lessThan(geometry.centerX));
        expect(geometry.rightEnd, greaterThan(geometry.centerX));
      }
    }
  });
}

SakuraCurvedNavigationPainter _notchPainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is SakuraCurvedNavigationPainter,
    ),
  );
  return paint.painter! as SakuraCurvedNavigationPainter;
}

Future<void> _pumpNavigation(
  WidgetTester tester, {
  required int selectedIndex,
  ValueChanged<int>? onDestinationSelected,
  Locale locale = const Locale('vi'),
  double textScale = 1,
  bool disableAnimations = false,
  double bottomInset = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
            padding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Scaffold(
            bottomNavigationBar: RikiBottomNavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}
