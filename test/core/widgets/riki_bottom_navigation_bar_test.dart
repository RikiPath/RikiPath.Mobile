import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/navigation_configuration.dart';
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
    expect(LearnerNavigationConfiguration.tabCount, labels.length);
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
    // At frame 0 of the glide from 0 -> 2, the circle carries tab 0's active
    // icon while tab 2 keeps only its inactive icon — never duplicating either.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(find.byIcon(Icons.quiz), findsNothing);
    expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
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
    expect(find.byIcon(Icons.quiz), findsOneWidget);
    expect(find.byIcon(Icons.quiz_outlined), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
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

  testWidgets(
    'mentor destinations reuse SakuraBottomNavigation smoothly without overflow across viewports',
    (tester) async {
      for (final width in <double>[360, 393, 412]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpNavigation(
          tester,
          selectedIndex: 2,
          textScale: width == 360 ? 1.15 : 1.0,
          destinationsBuilder: (context) =>
              MentorNavigationConfiguration.buildDestinations(context.l10n),
        );

        for (final label in const <String>[
          'Trang chủ',
          'Lịch dạy',
          'Lớp nhóm',
          'Lịch trống',
          'Cá nhân',
        ]) {
          final itemFinder = find.byKey(
            ValueKey<String>('bottom_navigation_item_$label'),
          );
          expect(itemFinder, findsOneWidget);
          expect(tester.getSize(itemFinder).height, greaterThanOrEqualTo(48));
        }
        expect(find.byIcon(Icons.groups), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'indicator slides forward, reverses backward, and handles rapid switching cleanly',
    (tester) async {
      var selected = 0;
      late StateSetter updateState;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) {
              updateState = setState;
              return Scaffold(
                bottomNavigationBar: SakuraBottomNavigation(
                  destinations: MentorNavigationConfiguration.buildDestinations(
                    context.l10n,
                  ),
                  selectedIndex: selected,
                  onDestinationSelected: (idx) =>
                      setState(() => selected = idx),
                ),
              );
            },
          ),
        ),
      );

      final barWidth = tester.getSize(find.byType(SakuraBottomNavigation)).width;
      final startX = _notchPainter(
        tester,
      ).geometryFor(Size(barWidth, 64)).centerX;
      expect(startX, closeTo(barWidth * 0.1, 0.5));

      // Forward transition 0 -> 3
      updateState(() => selected = 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final midForwardX = _notchPainter(
        tester,
      ).geometryFor(Size(barWidth, 64)).centerX;
      expect(midForwardX, greaterThan(barWidth * 0.25));
      expect(midForwardX, lessThan(barWidth * 0.7));

      // Rapidly interrupt with 3 -> 1 -> 4 before completion
      updateState(() => selected = 1);
      await tester.pump(const Duration(milliseconds: 30));
      updateState(() => selected = 4);
      await tester.pumpAndSettle();

      final endForwardX = _notchPainter(
        tester,
      ).geometryFor(Size(barWidth, 64)).centerX;
      expect(endForwardX, closeTo(barWidth * 0.9, 0.5));

      // Reverse transition 4 -> 0
      updateState(() => selected = 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final midReverseX = _notchPainter(
        tester,
      ).geometryFor(Size(barWidth, 64)).centerX;
      expect(midReverseX, lessThan(barWidth * 0.85));
      expect(midReverseX, greaterThan(barWidth * 0.15));
      await tester.pumpAndSettle();
      expect(
        _notchPainter(tester).geometryFor(Size(barWidth, 64)).centerX,
        closeTo(barWidth * 0.1, 0.5),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'active circle and icon keep compact centered geometry without enlargement across 360dp, 393dp, 412dp',
    (tester) async {
      for (final width in <double>[360, 393, 412]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        for (final selectedIndex in <int>[0, 1, 2, 3, 4]) {
          await _pumpNavigation(tester, selectedIndex: selectedIndex);
          await tester.pumpAndSettle();
          final barRect = tester.getRect(find.byType(SakuraBottomNavigation));
          final indicatorFinder = find.byKey(
            const ValueKey<String>('sakura_floating_active_indicator'),
          );
          final indicatorRect = tester.getRect(indicatorFinder);
          expect(indicatorRect.width, closeTo(40, 0.01));
          expect(indicatorRect.height, closeTo(40, 0.01));
          expect(indicatorRect.top, greaterThanOrEqualTo(barRect.top));
          expect(indicatorRect.bottom, lessThanOrEqualTo(barRect.bottom));

          final activeIcon = tester.widget<Icon>(
            find.descendant(of: indicatorFinder, matching: find.byType(Icon)),
          );
          expect(activeIcon.size, 20);

          final activeTabItem = tester.getRect(
            find
                .byKey(
                  ValueKey<String>(
                    'bottom_navigation_item_${['Trang chủ', 'Học tập', 'Luyện tập', 'Sổ từ', 'Cá nhân'][selectedIndex]}',
                  ),
                ),
          );
          expect(
            indicatorRect.center.dx,
            closeTo(activeTabItem.center.dx, 0.1),
          );
        }
      }
    },
  );

  testWidgets(
    'never renders both active and inactive icons for any tab during forward, backward, and rapid switches',
    (tester) async {
      final destinations = <(IconData icon, IconData selectedIcon)>[
        (Icons.home_outlined, Icons.home),
        (Icons.menu_book_outlined, Icons.menu_book),
        (Icons.quiz_outlined, Icons.quiz),
        (Icons.style_outlined, Icons.style),
        (Icons.person_outline, Icons.person),
      ];

      void assertNoDuplicateIcons() {
        for (final entry in destinations) {
          final outlinedIcons = tester
              .widgetList<Icon>(find.byIcon(entry.$1))
              .where((icon) {
                final opacityFinder = find.ancestor(
                  of: find.byWidget(icon),
                  matching: find.byType(Opacity),
                );
                if (opacityFinder.evaluate().isEmpty) return true;
                return tester
                        .widget<Opacity>(opacityFinder.first)
                        .opacity >
                    0.01;
              })
              .toList();
          final selectedIcons = tester
              .widgetList<Icon>(find.byIcon(entry.$2))
              .where((icon) {
                final opacityFinder = find.ancestor(
                  of: find.byWidget(icon),
                  matching: find.byType(Opacity),
                );
                if (opacityFinder.evaluate().isEmpty) return true;
                return tester
                        .widget<Opacity>(opacityFinder.first)
                        .opacity >
                    0.01;
              })
              .toList();
          expect(outlinedIcons.length, lessThanOrEqualTo(1));
          expect(selectedIcons.length, lessThanOrEqualTo(1));
          expect(
            outlinedIcons.isNotEmpty && selectedIcons.isNotEmpty,
            isFalse,
            reason:
                'Both ${entry.$1} and ${entry.$2} were visible simultaneously',
          );
        }
      }

      var selected = 0;
      late StateSetter updateState;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) {
              updateState = setState;
              return Scaffold(
                bottomNavigationBar: SakuraBottomNavigation(
                  destinations: LearnerNavigationConfiguration.buildDestinations(
                    context.l10n,
                  ),
                  selectedIndex: selected,
                  onDestinationSelected: (idx) =>
                      setState(() => selected = idx),
                ),
              );
            },
          ),
        ),
      );

      // Jump 0 -> 2 (Luyện tập) and sample every 25ms through settle
      updateState(() => selected = 2);
      await tester.pump();
      assertNoDuplicateIcons();
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 25));
        assertNoDuplicateIcons();
      }
      await tester.pumpAndSettle();
      assertNoDuplicateIcons();

      // Rapid switches: 2 -> 4 -> 1 -> 3 -> 0
      for (final next in <int>[4, 1, 3, 0]) {
        updateState(() => selected = next);
        await tester.pump();
        assertNoDuplicateIcons();
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 35));
          assertNoDuplicateIcons();
        }
      }
      await tester.pumpAndSettle();
      assertNoDuplicateIcons();
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
    },
  );

  testWidgets(
    'mentor destinations share identical compact centered geometry and zero duplicate icons',
    (tester) async {
      tester.view.physicalSize = const Size(393, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var selected = 0;
      late StateSetter updateState;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) {
              updateState = setState;
              return Scaffold(
                bottomNavigationBar: SakuraBottomNavigation(
                  destinations: MentorNavigationConfiguration.buildDestinations(
                    context.l10n,
                  ),
                  selectedIndex: selected,
                  onDestinationSelected: (idx) =>
                      setState(() => selected = idx),
                ),
              );
            },
          ),
        ),
      );

      updateState(() => selected = 2);
      await tester.pump();
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
      expect(find.byIcon(Icons.groups), findsNothing);
      expect(find.byIcon(Icons.groups_outlined), findsOneWidget);

      await tester.pumpAndSettle();
      final indicatorFinder = find.byKey(
        const ValueKey<String>('sakura_floating_active_indicator'),
      );
      final indicatorRect = tester.getRect(indicatorFinder);
      final barRect = tester.getRect(find.byType(SakuraBottomNavigation));
      expect(indicatorRect.width, closeTo(40, 0.01));
      expect(indicatorRect.height, closeTo(40, 0.01));
      expect(indicatorRect.top, greaterThanOrEqualTo(barRect.top));
      expect(indicatorRect.center.dx, closeTo(barRect.center.dx, 0.1));
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: indicatorFinder, matching: find.byType(Icon)),
            )
            .size,
        20,
      );
      expect(find.byIcon(Icons.groups), findsOneWidget);
      expect(find.byIcon(Icons.groups_outlined), findsNothing);
    },
  );
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
  List<RikiNavigationDestination> Function(BuildContext context)?
  destinationsBuilder,
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
              destinations:
                  destinationsBuilder?.call(context) ??
                  LearnerNavigationConfiguration.buildDestinations(
                    context.l10n,
                  ),
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}
