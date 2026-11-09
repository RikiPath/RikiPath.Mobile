import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_language_switcher.dart';
import 'package:rikipath_mobile/core/widgets/riki_learner_header.dart';
import 'package:rikipath_mobile/core/widgets/sakura_3d_icon.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/core/widgets/sakura_scroll_scaffold.dart';

void main() {
  Widget buildTestHost(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: child,
      ),
    );
  }

  group('SakuraAppHeader Structure & Components', () {
    testWidgets('renders all four primary elements: Logo, Streak, Notification, Calendar', (
      tester,
    ) async {
      var notificationsPressed = false;
      var calendarPressed = false;

      await tester.pumpWidget(
        buildTestHost(
          Scaffold(
            appBar: SakuraAppHeader(
              streakDays: 5,
              unreadNotificationCount: 3,
              onNotificationsPressed: () => notificationsPressed = true,
              onCalendarPressed: () => calendarPressed = true,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. RikiPath Brand Logo
      expect(find.byType(RikiBrandLockup), findsOneWidget);

      // 2. Streak with 3D flame icon and day count
      expect(find.text('5 ngày'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Sakura3DIcon && w.type == Sakura3DIconType.streak,
        ),
        findsOneWidget,
      );

      // 3. Notification icon with badge
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      final unreadBadge = find.byKey(
        const ValueKey<String>('home_notification_unread_badge'),
      );
      expect(unreadBadge, findsOneWidget);

      // 4. Calendar button
      final calendarButton = find.byKey(
        const ValueKey<String>('home_calendar_button'),
      );
      expect(calendarButton, findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Sakura3DIcon && w.type == Sakura3DIconType.calendar,
        ),
        findsOneWidget,
      );

      // 5. Verify tap callbacks
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      expect(notificationsPressed, isTrue);

      await tester.tap(calendarButton);
      expect(calendarPressed, isTrue);

      // 6. Confirm NO language switcher in authenticated header
      expect(find.byType(RikiLanguageSwitcher), findsNothing);
    });

    testWidgets('HomeHeader alias is identical to SakuraAppHeader', (tester) async {
      await tester.pumpWidget(
        buildTestHost(
          const Scaffold(
            appBar: HomeHeader(streakDays: 7, unreadNotificationCount: 0),
            body: SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.byType(SakuraAppHeader), findsOneWidget);
      expect(find.text('7 ngày'), findsOneWidget);
    });
  });

  group('SakuraAppHeader Scroll-Aware Elevation', () {
    testWidgets('unscrolled state is clean white without shadow or bottom border', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestHost(
          const Scaffold(
            appBar: SakuraAppHeader(
              isScrolled: false,
              streakDays: 3,
            ),
            body: SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(RikiLearnerHeader),
          matching: find.byType(AnimatedContainer),
        ),
      );

      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.boxShadow, isEmpty);
      expect(decoration.border, isNull);
    });

    testWidgets('scrolled state smoothly applies neutral shadow and subtle divider', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestHost(
          const Scaffold(
            appBar: SakuraAppHeader(
              isScrolled: true,
              streakDays: 3,
            ),
            body: SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(RikiLearnerHeader),
          matching: find.byType(AnimatedContainer),
        ),
      );

      final decoration = animatedContainer.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.boxShadow, isNotEmpty);
      expect(decoration.boxShadow!.first.color, const Color(0x121A1317));
      expect(decoration.boxShadow!.first.offset, const Offset(0, 3));
      expect(decoration.boxShadow!.first.blurRadius, 14);
      expect(decoration.border, isNotNull);
    });

    testWidgets('SakuraScrollScaffold toggles isScrolled when list scrolls past threshold', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestHost(
          SakuraScrollScaffold(
            appBarBuilder: (context, isScrolled) => SakuraAppHeader(
              key: ValueKey<bool>(isScrolled),
              isScrolled: isScrolled,
              streakDays: 4,
            ),
            body: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) => SizedBox(
                height: 60,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At top: unscrolled
      expect(find.byKey(const ValueKey<bool>(false)), findsOneWidget);
      expect(find.byKey(const ValueKey<bool>(true)), findsNothing);

      // Scroll down by 50px (past the 4px threshold)
      await tester.drag(find.text('Item 0'), const Offset(0, -50));
      await tester.pumpAndSettle();

      // Scrolled state activated
      expect(find.byKey(const ValueKey<bool>(true)), findsOneWidget);
      expect(find.byKey(const ValueKey<bool>(false)), findsNothing);

      // Scroll back to top
      await tester.drag(find.text('Item 5'), const Offset(0, 100));
      await tester.pumpAndSettle();

      // Returned to unscrolled
      expect(find.byKey(const ValueKey<bool>(false)), findsOneWidget);
    });
  });

  group('SakuraAppHeader Responsiveness & Geometry', () {
    testWidgets('maintains 64dp standard height across all screen widths', (
      tester,
    ) async {
      for (final width in [320.0, 360.0, 393.0, 412.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestHost(
            const Scaffold(
              appBar: SakuraAppHeader(
                streakDays: 12,
                unreadNotificationCount: 5,
              ),
              body: SizedBox.expand(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final headerSize = tester.getSize(find.byType(AppBar));
        expect(headerSize.height, 64.0);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
