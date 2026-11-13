import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/widgets/sakura_3d_icon.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_library_home.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/sakura_library_hero_banner.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

Widget _wrap(
  Widget child, {
  Locale locale = const Locale('vi'),
  double textScale = 1.0,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi'), Locale('ja')],
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(393, 852),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('SakuraLibraryHeroBanner', () {
    testWidgets('renders title, subtitle, and Japanese tag badge', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const SakuraLibraryHeroBanner()));
      await tester.pumpAndSettle();

      expect(find.text('ライブラリ'), findsOneWidget);
      expect(find.text('Khám phá kho kiến thức Nhật Bản'), findsOneWidget);
      expect(find.text('Mỗi bài học, một bước tiến mới.'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(SakuraLibraryHeroBanner(onTap: () => tapped = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SakuraLibraryHeroBanner));
      expect(tapped, isTrue);
    });

    for (final width in <double>[360, 393, 412]) {
      for (final scale in <double>[1.0, 1.3, 2.0]) {
        testWidgets(
          'fits ${width.toInt()}dp width at ${scale}x text scale without overflow',
          (tester) async {
            tester.view.physicalSize = Size(width * 2, 800 * 2);
            tester.view.devicePixelRatio = 2.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            await tester.pumpWidget(
              _wrap(const SakuraLibraryHeroBanner(), textScale: scale),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            expect(
              find.text('Khám phá kho kiến thức Nhật Bản'),
              findsOneWidget,
            );
          },
        );
      }
    }
  });

  group('LearningLibraryHome', () {
    testWidgets(
      'renders hero banner and all 4 semantic menu cards with distinct icons',
      (tester) async {
        await tester.pumpWidget(_wrap(const LearningLibraryHome()));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('learning_library_hero_banner')),
          findsOneWidget,
        );

        final cards = [
          ('library_lessons_card', 'Bài học tiếng Nhật', Sakura3DIconType.lesson),
          ('library_vocabulary_card', 'Từ vựng', Sakura3DIconType.vocabulary),
          ('library_kanji_card', 'Kanji', Sakura3DIconType.kanji),
          ('library_grammar_card', 'Ngữ pháp', Sakura3DIconType.grammar),
        ];

        for (final (key, title, iconType) in cards) {
          final cardFinder = find.byKey(ValueKey(key));
          expect(cardFinder, findsOneWidget, reason: 'Missing card: $key');

          expect(
            find.descendant(of: cardFinder, matching: find.text(title)),
            findsOneWidget,
          );

          final iconFinder = find.descendant(
            of: cardFinder,
            matching: find.byWidgetPredicate(
              (widget) => widget is Sakura3DIcon && widget.type == iconType,
            ),
          );
          expect(
            iconFinder,
            findsOneWidget,
            reason: 'Card $key must use 3D icon $iconType',
          );
        }
      },
    );

    testWidgets(
      'all library cards have single-line descriptions with ellipsis',
      (tester) async {
        await tester.pumpWidget(_wrap(const LearningLibraryHome()));
        await tester.pumpAndSettle();

        final cards = [
          'library_lessons_card',
          'library_vocabulary_card',
          'library_kanji_card',
          'library_grammar_card',
        ];

        for (final key in cards) {
          final cardFinder = find.byKey(ValueKey(key));
          final texts = tester.widgetList<Text>(
            find.descendant(of: cardFinder, matching: find.byType(Text)),
          );

          expect(texts.length, greaterThanOrEqualTo(2));
          final descText = texts.elementAt(1);
          expect(descText.maxLines, 1);
          expect(descText.overflow, TextOverflow.ellipsis);
        }
      },
    );
  });
}
