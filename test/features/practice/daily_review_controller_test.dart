import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/review_quality.dart';

void main() {
  group('DailyReviewController', () {
    test('loads only cards returned by the live repository', () async {
      final harness = await _harness(_FakeDailyReviewRepository());

      expect(harness.value.cards.single.reviewCardId, 481);
      expect(harness.value.currentIndex, 0);
      expect(harness.repository.loadCount, 1);
    });

    test(
      'queue failure is exposed without substituting fixture data',
      () async {
        final repository = _FakeDailyReviewRepository(
          loadError: const NetworkError(),
        );
        final container = ProviderContainer(
          overrides: [
            dailyReviewRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        await expectLater(
          container.read(dailyReviewControllerProvider.future),
          throwsA(isA<NetworkError>()),
        );
        expect(repository.loadCount, 1);
      },
    );

    for (final entry in <(ReviewRating, int)>[
      (ReviewRating.again, 1),
      (ReviewRating.hard, 3),
      (ReviewRating.good, 4),
      (ReviewRating.easy, 5),
    ]) {
      test('${entry.$1.name} submits quality ${entry.$2}', () async {
        final harness = await _harness(_FakeDailyReviewRepository());
        harness.controller.revealAnswer();

        expect(await harness.controller.submit(entry.$1), isTrue);

        expect(harness.repository.submissions, <(int, int)>[(481, entry.$2)]);
        expect(harness.value.responses.single.rating, entry.$1);
        expect(harness.value.currentIndex, 1);
        expect(harness.value.isComplete, isTrue);
      });
    }

    test('does not advance before the server confirms the mutation', () async {
      final completer = Completer<DailyReviewSubmitResult>();
      final repository = _FakeDailyReviewRepository(completer: completer);
      final harness = await _harness(repository);
      harness.controller.revealAnswer();

      final first = harness.controller.submit(ReviewRating.good);
      final duplicate = harness.controller.submit(ReviewRating.easy);
      await Future<void>.delayed(Duration.zero);

      expect(harness.value.currentIndex, 0);
      expect(harness.value.isSubmitting, isTrue);
      expect(await duplicate, isFalse);
      expect(repository.submissions, <(int, int)>[(481, 4)]);

      completer.complete(_result(quality: 4));
      expect(await first, isTrue);
      expect(harness.value.currentIndex, 1);
    });

    test('Again appends the confirmed repeat to the current session', () async {
      final repository = _FakeDailyReviewRepository(
        result: _result(quality: 1, shouldRepeat: true),
      );
      final harness = await _harness(repository);
      harness.controller.revealAnswer();

      expect(await harness.controller.submit(ReviewRating.again), isTrue);

      expect(harness.value.cards, hasLength(2));
      expect(harness.value.currentCard?.reviewCardId, 481);
      expect(harness.value.isComplete, isFalse);
    });

    test('failure preserves the card and requires a queue refresh', () async {
      final repository = _FakeDailyReviewRepository(
        error: const NetworkError(),
      );
      final harness = await _harness(repository);
      harness.controller.revealAnswer();

      expect(await harness.controller.submit(ReviewRating.good), isFalse);
      expect(harness.value.currentIndex, 0);
      expect(harness.value.currentCard?.reviewCardId, 481);
      expect(harness.value.isAnswerVisible, isTrue);
      expect(harness.value.submitError, isA<NetworkError>());
      expect(await harness.controller.submit(ReviewRating.good), isFalse);
      expect(repository.submissions, hasLength(1));

      repository.error = null;
      await harness.controller.retry();
      expect(harness.repository.loadCount, 2);
      expect(harness.value.submitError, isNull);
      expect(harness.value.currentIndex, 0);
    });

    test('rejects a response for a different request identity', () async {
      final repository = _FakeDailyReviewRepository(
        result: _result(reviewCardId: 999, quality: 4),
      );
      final harness = await _harness(repository);
      harness.controller.revealAnswer();

      expect(await harness.controller.submit(ReviewRating.good), isFalse);
      expect(harness.value.currentIndex, 0);
      expect(harness.value.submitError, isA<UnknownError>());
    });

    test(
      'conflict remains controlled and never advances optimistically',
      () async {
        final repository = _FakeDailyReviewRepository(
          error: const ConflictError(),
        );
        final harness = await _harness(repository);
        harness.controller.revealAnswer();

        expect(await harness.controller.submit(ReviewRating.easy), isFalse);
        expect(harness.value.currentIndex, 0);
        expect(harness.value.submitError, isA<ConflictError>());
        expect(harness.value.responses, isEmpty);
      },
    );
  });
}

class _Harness {
  const _Harness(this.container, this.repository);

  final ProviderContainer container;
  final _FakeDailyReviewRepository repository;

  DailyReviewController get controller =>
      container.read(dailyReviewControllerProvider.notifier);

  DailyReviewState get value =>
      container.read(dailyReviewControllerProvider).requireValue;
}

Future<_Harness> _harness(_FakeDailyReviewRepository repository) async {
  final container = ProviderContainer(
    overrides: [dailyReviewRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  await container.read(dailyReviewControllerProvider.future);
  return _Harness(container, repository);
}

class _FakeDailyReviewRepository implements DailyReviewRepository {
  _FakeDailyReviewRepository({
    this.completer,
    this.result,
    this.error,
    this.loadError,
  });

  final Completer<DailyReviewSubmitResult>? completer;
  final DailyReviewSubmitResult? result;
  final Object? loadError;
  Object? error;
  int loadCount = 0;
  final List<(int, int)> submissions = <(int, int)>[];

  @override
  Future<DailyReviewQueue> loadDailyQueue() async {
    loadCount++;
    if (loadError case final value?) throw value;
    return DailyReviewQueue(totalDue: 1, items: <DailyReviewCard>[_card]);
  }

  @override
  Future<DailyReviewSubmitResult> submitResult({
    required int reviewCardId,
    required int quality,
  }) async {
    submissions.add((reviewCardId, quality));
    if (error case final value?) throw value;
    return completer?.future ?? result ?? _result(quality: quality);
  }
}

final DailyReviewCard _card = DailyReviewCard(
  reviewCardId: 481,
  contentType: DailyReviewContentType.vocabulary,
  term: '学ぶ',
  reading: 'まなぶ',
  meaning: 'học',
  note: null,
  repetitions: 0,
  nextReviewDate: DateTime.utc(2026, 10, 21),
);

DailyReviewSubmitResult _result({
  int reviewCardId = 481,
  required int quality,
  bool shouldRepeat = false,
}) {
  return DailyReviewSubmitResult(
    reviewCardId: reviewCardId,
    qualitySubmitted: quality,
    shouldRepeatInSession: shouldRepeat,
    newEaseFactor: 2.5,
    newIntervalDays: 1,
    repetitions: 1,
    nextReviewDate: DateTime.utc(2026, 10, 22),
  );
}
