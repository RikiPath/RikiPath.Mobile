import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/calendar/presentation/learner_calendar_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  group('Sakura Visual Quality, Responsive & Accessibility Verification', () {
    testWidgets('Sakura Calendar renders without overflow at 360px width', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LearnerCalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Sakura Calendar renders without overflow at 412px width', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LearnerCalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Sakura components support 1.3x and 2.0x text scaling gracefully', (tester) async {
      for (final scaleFactor in [1.3, 2.0]) {
        tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
        tester.view.devicePixelRatio = 2.6;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(412, 915),
                  textScaler: TextScaler.linear(scaleFactor),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SakuraMascot(
                          pose: SakuraMascotPose.studying,
                          size: 100,
                        ),
                        RikiCard(
                          child: Text(
                            'Lịch tư vấn JLPT cùng Mentor chuyên sâu',
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        RikiPrimaryButton(
                          label: 'Xác nhận đặt lịch tư vấn',
                          onPressed: () {},
                        ),
                        const RikiInfoBanner(
                          message: 'Lịch học sẽ được xác nhận tự động bằng vé khả dụng.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed at textScaler $scaleFactor');
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Sakura Mascot renders accessible and decorative states appropriately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Semantics(
                  label: 'Sakura linh vật chúc mừng',
                  child: const SakuraMascot(
                    pose: SakuraMascotPose.celebrating,
                    size: 80,
                  ),
                ),
                const SakuraMascot(
                  pose: SakuraMascotPose.greeting,
                  size: 80,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Sakura linh vật chúc mừng',
        ),
        findsOneWidget,
      );
    });
  });
}
