import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/practice/application/demo_practice_controller.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';

void main() {
  test(
    'SRS demo reveal and answer progress locally without live submit',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = await container.read(
        demoPracticeControllerProvider.future,
      );
      expect(initial.currentReviewCard?.id, startsWith('fixture-review-'));
      expect(initial.isReviewAnswerVisible, isFalse);

      final controller = container.read(
        demoPracticeControllerProvider.notifier,
      );
      controller.revealReviewAnswer();
      expect(
        container
            .read(demoPracticeControllerProvider)
            .requireValue
            .isReviewAnswerVisible,
        isTrue,
      );

      controller.answerReview(DemoReviewAnswer.again);
      final updated = container
          .read(demoPracticeControllerProvider)
          .requireValue;
      expect(updated.reviewIndex, 1);
      expect(updated.reviewAnswers, [DemoReviewAnswer.again]);
      expect(updated.isReviewAnswerVisible, isFalse);
    },
  );

  test('mock test fixture scores answers locally', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(demoPracticeControllerProvider.future);
    final controller = container.read(demoPracticeControllerProvider.notifier);
    controller.startMockTest();
    for (final question in state.mockTest.questions) {
      controller.selectMockAnswer(question.id, question.correctOptionId);
    }
    final answered = container
        .read(demoPracticeControllerProvider)
        .requireValue;
    expect(answered.mockAnswers, hasLength(state.mockTest.questions.length));
    controller.submitMockTest();

    final result = container
        .read(demoPracticeControllerProvider)
        .requireValue
        .mockResult;
    expect(result?.score, state.mockTest.questions.length);
    expect(result?.total, state.mockTest.questions.length);
    expect(state.mockTest.id, startsWith('fixture-'));
  });

  test('demo checkout never needs a backend purchase id', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(demoPracticeControllerProvider.future);
    final controller = container.read(demoPracticeControllerProvider.notifier);
    controller.beginDemoCheckout();
    expect(
      container.read(demoPracticeControllerProvider).requireValue.bookingStatus,
      DemoBookingStatus.checkout,
    );

    controller.confirmDemoBooking();
    final state = container.read(demoPracticeControllerProvider).requireValue;
    expect(state.bookingStatus, DemoBookingStatus.confirmed);
    expect(state.mentorPlans.single.id, startsWith('fixture-'));
    expect(state.mentorSlots.single.id, startsWith('fixture-'));
  });
}
