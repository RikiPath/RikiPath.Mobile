import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/presentation/daily_review_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'submit failure stays on the card and shows controlled recovery',
    (tester) async {
      final repository = _WidgetReviewRepository(error: const NetworkError());
      await _pump(tester, repository);

      await tester.tap(
        find.byKey(const ValueKey<String>('review_reveal_button')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('review_answer_good')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('daily_review_card_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('review_submit_error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('review_submit_refresh')),
        findsOneWidget,
      );
      expect(find.textContaining('NetworkError'), findsNothing);
    },
  );

  testWidgets('rating buttons are disabled while one submit is in flight', (
    tester,
  ) async {
    final completer = Completer<DailyReviewSubmitResult>();
    final repository = _WidgetReviewRepository(completer: completer);
    await _pump(tester, repository);

    await tester.tap(
      find.byKey(const ValueKey<String>('review_reveal_button')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('review_answer_good')));
    await tester.pump();

    expect(repository.submitCount, 1);
    expect(
      find.byKey(const ValueKey<String>('review_submit_loading')),
      findsOneWidget,
    );
    for (final name in <String>['again', 'hard', 'good', 'easy']) {
      final button = tester.widget<OutlinedButton>(
        find.byKey(ValueKey<String>('review_answer_$name')),
      );
      expect(button.onPressed, isNull);
    }

    completer.complete(_submitResult);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('daily_review_summary')),
      findsOneWidget,
    );
  });
}

Future<void> _pump(
  WidgetTester tester,
  DailyReviewRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dailyReviewRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: const DailyReviewScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _WidgetReviewRepository implements DailyReviewRepository {
  _WidgetReviewRepository({this.completer, this.error});

  final Completer<DailyReviewSubmitResult>? completer;
  final Object? error;
  int submitCount = 0;

  @override
  Future<DailyReviewQueue> loadDailyQueue() async => _queue;

  @override
  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  }) async {
    submitCount++;
    if (error case final value?) throw value;
    return completer?.future ?? _submitResult;
  }
}

final DailyReviewQueue _queue = DailyReviewQueue(
  totalDue: 1,
  items: <DailyReviewCard>[
    DailyReviewCard(
      reviewCardId: 481,
      contentType: DailyReviewContentType.vocabulary,
      term: '学ぶ',
      reading: 'まなぶ',
      meaning: 'học',
      note: null,
      repetitions: 0,
      nextReviewDate: DateTime.utc(2026, 10, 21),
    ),
  ],
);

final DailyReviewSubmitResult _submitResult = DailyReviewSubmitResult(
  reviewCardId: 481,
  qualitySubmitted: 4,
  shouldRepeatInSession: false,
  newEaseFactor: 2.5,
  newIntervalDays: 1,
  repetitions: 1,
  nextReviewDate: DateTime.utc(2026, 10, 22),
);
