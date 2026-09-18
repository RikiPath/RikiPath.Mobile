import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
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

    final indicator = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('bottom_navigation_item_Luyện tập'),
        ),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (indicator.decoration! as BoxDecoration).color,
      AppColors.surfaceContainer,
    );
  });

  testWidgets('destinations keep equal width and single-line labels', (
    tester,
  ) async {
    await _pumpNavigation(tester, selectedIndex: 0);

    expect(RikiBottomNavigationBar.destinations, hasLength(5));
    for (final destination in RikiBottomNavigationBar.destinations) {
      final label = tester.widget<Text>(find.text(destination.label));
      expect(label.maxLines, 1);
    }

    final itemWidths = RikiBottomNavigationBar.destinations.map((destination) {
      return tester
          .getSize(
            find.byKey(
              ValueKey<String>('bottom_navigation_item_${destination.label}'),
            ),
          )
          .width;
    }).toSet();
    expect(itemWidths, hasLength(1));
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
}

Future<void> _pumpNavigation(
  WidgetTester tester, {
  required int selectedIndex,
  ValueChanged<int>? onDestinationSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        bottomNavigationBar: RikiBottomNavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected ?? (_) {},
        ),
      ),
    ),
  );
}
