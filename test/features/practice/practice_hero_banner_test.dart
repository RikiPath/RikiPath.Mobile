import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/practice/presentation/widgets/practice_hero_banner.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('vi'), double textScale = 1.0}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('ja'),
      ],
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('PracticeHeroBanner', () {
    testWidgets('renders Vietnamese localized copy by default', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeHeroBanner()));
      await tester.pumpAndSettle();

      expect(find.text('がんばろう！'), findsOneWidget);
      expect(find.text('Sẵn sàng luyện tập?'), findsOneWidget);
      expect(find.text('Mỗi bài tập, thêm một bước tiến.'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders Japanese localized copy when locale is ja', (tester) async {
      await tester.pumpWidget(
        _wrap(const PracticeHeroBanner(), locale: const Locale('ja')),
      );
      await tester.pumpAndSettle();

      expect(find.text('がんばろう！'), findsOneWidget);
      expect(find.text('練習の準備はいい？'), findsOneWidget);
      expect(find.text('毎日の練習で、一歩ずつ前進。'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(PracticeHeroBanner(onTap: () => tapped = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PracticeHeroBanner));
      expect(tapped, isTrue);
    });

    for (final width in <double>[360, 393, 412]) {
      for (final scale in <double>[1.0, 1.3, 2.0]) {
        testWidgets('fits ${width.toInt()}dp width at ${scale}x text scale without overflow', (tester) async {
          tester.view.physicalSize = Size(width * 2, 800 * 2);
          tester.view.devicePixelRatio = 2.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            _wrap(const PracticeHeroBanner(), textScale: scale),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Sẵn sàng luyện tập?'), findsOneWidget);
        });
      }
    }
  });

  group('PracticeScreen with PracticeHeroBanner', () {
    testWidgets('renders PracticeHeroBanner immediately above mock library card', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeScreen()));
      await tester.pumpAndSettle();

      final bannerFinder = find.byKey(const ValueKey<String>('practice_hero_banner'));
      final mockCardFinder = find.byKey(const ValueKey<String>('practice_mock_library_card'));

      expect(bannerFinder, findsOneWidget);
      expect(mockCardFinder, findsOneWidget);

      final bannerBottom = tester.getBottomLeft(bannerFinder).dy;
      final cardTop = tester.getTopLeft(mockCardFinder).dy;

      // Card is below banner with spacing
      expect(cardTop, greaterThan(bannerBottom));
    });
  });
}
