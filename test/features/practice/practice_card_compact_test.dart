import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/riki_feature_visuals.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    DailyReviewState? reviewState,
    double width = 393.0,
    double textScale = 1.0,
    Locale locale = const Locale('vi'),
  }) {
    return ProviderScope(
      overrides: [
        if (reviewState != null)
          dailyReviewControllerProvider.overrideWith(
            () => _FakeDailyReviewController(reviewState),
          ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 852.0),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: PracticeScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Practice daily review card renders title and badge inline on the same row',
    (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          reviewState: const DailyReviewState(
            cards: [],
            currentIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify card exists
      final cardFinder = find.byKey(
        const ValueKey<String>('practice_daily_review_card'),
      );
      expect(cardFinder, findsOneWidget);

      // Verify title and status pill exist inside the card
      final titleFinder = find.descendant(
        of: cardFinder,
        matching: find.text('Ôn tập hôm nay'),
      );
      final pillFinder = find.descendant(
        of: cardFinder,
        matching: find.byType(RikiStatusPill),
      );
      expect(titleFinder, findsOneWidget);
      expect(pillFinder, findsOneWidget);

      // Verify title and status pill share the same vertical Y position (inline row)
      final titleCenter = tester.getCenter(titleFinder);
      final pillCenter = tester.getCenter(pillFinder);
      expect((titleCenter.dy - pillCenter.dy).abs(), lessThan(8.0));
    },
  );

  testWidgets(
    'All practice cards have single-line descriptions with ellipsis',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find all Text widgets within the practice cards
      final cards = [
        'practice_mock_library_card',
        'practice_daily_review_card',
        'practice_essay_writing_card',
        'practice_writing_card',
        'practice_speech_card',
        'practice_text_scan_card',
      ];

      for (final cardKey in cards) {
        final cardFinder = find.byKey(ValueKey<String>(cardKey));
        expect(cardFinder, findsOneWidget);

        final texts = tester
            .widgetList<Text>(
              find.descendant(of: cardFinder, matching: find.byType(Text)),
            )
            .toList();

        // Second text is the description
        expect(texts.length, greaterThanOrEqualTo(2));
        final descriptionWidget = texts[1];
        expect(descriptionWidget.maxLines, 1);
        expect(descriptionWidget.overflow, TextOverflow.ellipsis);
      }
    },
  );

  for (final width in [360.0, 393.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'Practice cards do not overflow at ${width}dp and ${scale}x scale',
        (tester) async {
          await tester.pumpWidget(
            buildTestWidget(
              width: width,
              textScale: scale,
              reviewState: const DailyReviewState(
                cards: [],
                currentIndex: 0,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _FakeDailyReviewController extends DailyReviewController {
  _FakeDailyReviewController(this._initialState);
  final DailyReviewState _initialState;

  @override
  Future<DailyReviewState> build() async => _initialState;
}
