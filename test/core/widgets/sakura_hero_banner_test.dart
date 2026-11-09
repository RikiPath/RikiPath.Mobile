import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/sakura_hero_banner.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

Widget _buildTestHost({
  required Widget child,
  Locale locale = const Locale('vi'),
}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('vi'), Locale('ja')],
    home: Scaffold(body: child),
  );
}

void main() {
  group('SakuraTimeSlot logic tests', () {
    test('derives morning correctly (05:00 - 10:59)', () {
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 5, 0)),
        SakuraTimeSlot.morning,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 8, 30)),
        SakuraTimeSlot.morning,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 10, 59)),
        SakuraTimeSlot.morning,
      );
    });

    test('derives noon correctly (11:00 - 13:59)', () {
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 11, 0)),
        SakuraTimeSlot.noon,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 12, 15)),
        SakuraTimeSlot.noon,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 13, 59)),
        SakuraTimeSlot.noon,
      );
    });

    test('derives afternoon correctly (14:00 - 17:59)', () {
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 14, 0)),
        SakuraTimeSlot.afternoon,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 16, 45)),
        SakuraTimeSlot.afternoon,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 17, 59)),
        SakuraTimeSlot.afternoon,
      );
    });

    test('derives evening correctly (18:00 - 21:59)', () {
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 18, 0)),
        SakuraTimeSlot.evening,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 20, 0)),
        SakuraTimeSlot.evening,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 21, 59)),
        SakuraTimeSlot.evening,
      );
    });

    test('derives lateNight correctly (22:00 - 04:59)', () {
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 22, 0)),
        SakuraTimeSlot.lateNight,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 23, 59)),
        SakuraTimeSlot.lateNight,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 0, 0)),
        SakuraTimeSlot.lateNight,
      );
      expect(
        SakuraTimeSlot.fromDateTime(DateTime(2026, 11, 9, 4, 59)),
        SakuraTimeSlot.lateNight,
      );
    });

    test('calculates next boundary correctly', () {
      expect(
        SakuraTimeSlot.nextBoundary(DateTime(2026, 11, 9, 2, 30)),
        DateTime(2026, 11, 9, 5, 0),
      );
      expect(
        SakuraTimeSlot.nextBoundary(DateTime(2026, 11, 9, 8, 0)),
        DateTime(2026, 11, 9, 11, 0),
      );
      expect(
        SakuraTimeSlot.nextBoundary(DateTime(2026, 11, 9, 12, 0)),
        DateTime(2026, 11, 9, 14, 0),
      );
      expect(
        SakuraTimeSlot.nextBoundary(DateTime(2026, 11, 9, 15, 0)),
        DateTime(2026, 11, 9, 18, 0),
      );
      expect(
        SakuraTimeSlot.nextBoundary(DateTime(2026, 11, 9, 20, 0)),
        DateTime(2026, 11, 9, 22, 0),
      );
      expect(
        SakuraTimeSlot.nextBoundary(DateTime(2026, 11, 9, 23, 0)),
        DateTime(2026, 11, 10, 5, 0),
      );
    });
  });

  group('SakuraHeroBanner Widget Rendering', () {
    testWidgets('renders Morning banner with Vietnamese copy and morning asset', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          child: SakuraHeroBanner(
            nowOverride: () => DateTime(2026, 11, 9, 8, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chào buổi sáng!'), findsOneWidget);
      expect(find.text('Khởi đầu một ngày học thật vui.'), findsOneWidget);
      expect(find.text('がんばろう！'), findsOneWidget);

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/time_banners/sakura_morning.webp',
      );
    });

    testWidgets('renders Noon banner with noon asset', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          child: SakuraHeroBanner(
            nowOverride: () => DateTime(2026, 11, 9, 12, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Học một chút nhé!'), findsOneWidget);
      expect(find.text('Nạp thêm kiến thức mới.'), findsOneWidget);

      final imageFinder = find.byType(Image);
      final image = tester.widget<Image>(imageFinder);
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/time_banners/sakura_noon.webp',
      );
    });

    testWidgets('renders Afternoon banner with afternoon asset', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          child: SakuraHeroBanner(
            nowOverride: () => DateTime(2026, 11, 9, 15, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tiếp tục cố gắng!'), findsOneWidget);
      expect(find.text('Mỗi bước nhỏ đều đáng giá.'), findsOneWidget);

      final imageFinder = find.byType(Image);
      final image = tester.widget<Image>(imageFinder);
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/time_banners/sakura_afternoon.webp',
      );
    });

    testWidgets('renders Evening banner with dark theme typography', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          child: SakuraHeroBanner(
            nowOverride: () => DateTime(2026, 11, 9, 19, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cùng ôn tập nào!'), findsOneWidget);
      expect(find.text('Củng cố những điều đã học.'), findsOneWidget);

      final titleWidget = tester.widget<Text>(find.text('Cùng ôn tập nào!'));
      expect(titleWidget.style?.color, Colors.white);

      final imageFinder = find.byType(Image);
      final image = tester.widget<Image>(imageFinder);
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/time_banners/sakura_evening.webp',
      );
    });

    testWidgets('renders Late Night banner with late night asset', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          child: SakuraHeroBanner(
            nowOverride: () => DateTime(2026, 11, 9, 23, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nghỉ ngơi thật tốt!'), findsOneWidget);
      expect(find.text('Ngày mai mình lại tiếp tục nhé.'), findsOneWidget);

      final imageFinder = find.byType(Image);
      final image = tester.widget<Image>(imageFinder);
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/time_banners/sakura_late_night.webp',
      );
    });

    testWidgets('renders Japanese copy when locale is ja', (tester) async {
      await tester.pumpWidget(
        _buildTestHost(
          locale: const Locale('ja'),
          child: SakuraHeroBanner(
            nowOverride: () => DateTime(2026, 11, 9, 8, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('おはようございます！'), findsOneWidget);
      expect(find.text('楽しい学習の始まりです。'), findsOneWidget);
      expect(find.text('がんばろう！'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when pressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildTestHost(
          child: SakuraHeroBanner(
            onTap: () => tapped = true,
            nowOverride: () => DateTime(2026, 11, 9, 9, 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SakuraHeroBanner));
      expect(tapped, isTrue);
    });

    testWidgets('captures all 5 time scenes for visual review', (tester) async {
      final scenes = <String, DateTime>{
        '01_morning_08_00': DateTime(2026, 11, 9, 8, 0),
        '02_noon_12_00': DateTime(2026, 11, 9, 12, 0),
        '03_afternoon_15_30': DateTime(2026, 11, 9, 15, 30),
        '04_evening_19_00': DateTime(2026, 11, 9, 19, 0),
        '05_late_night_23_30': DateTime(2026, 11, 9, 23, 30),
      };

      for (final entry in scenes.entries) {
        final key = GlobalKey();
        tester.view.physicalSize = const Size(393 * 2, 131 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildTestHost(
            child: RepaintBoundary(
              key: key,
              child: SakuraHeroBanner(
                nowOverride: () => entry.value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            if (byteData != null) {
              final file = File(
                'C:\\Users\\ADMIN\\.gemini\\antigravity\\brain\\e3992171-3ce2-4736-abc5-aba1234129ce\\visual_captures_banner\\time_slots\\${entry.key}.png',
              );
              await file.writeAsBytes(byteData.buffer.asUint8List());
            }
          });
        }
      }
    });
  });
}
