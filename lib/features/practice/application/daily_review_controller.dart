import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/network/api_client.dart';
import 'package:rikipath_mobile/features/practice/data/api_daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review.dart';
import 'package:rikipath_mobile/features/practice/domain/daily_review_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/review_quality.dart';

final dailyReviewRepositoryProvider = Provider<DailyReviewRepository>((ref) {
  return ApiDailyReviewRepository(ref.watch(apiClientProvider));
});

final dailyReviewControllerProvider =
    AsyncNotifierProvider<DailyReviewController, DailyReviewState>(
      DailyReviewController.new,
      retry: (_, _) => null,
    );

class DailyReviewController extends AsyncNotifier<DailyReviewState> {
  bool _submitInFlight = false;

  DailyReviewRepository get _repository =>
      ref.read(dailyReviewRepositoryProvider);

  @override
  Future<DailyReviewState> build() async {
    final queue = await _repository.loadDailyQueue();
    return DailyReviewState(cards: queue.items);
  }

  Future<void> retry() async {
    state = const AsyncLoading<DailyReviewState>();
    state = await AsyncValue.guard(build);
  }

  void revealAnswer() {
    final current = state.value;
    if (current == null ||
        current.currentCard == null ||
        current.isSubmitting ||
        current.submitError != null) {
      return;
    }
    state = AsyncData(current.copyWith(isAnswerVisible: true));
  }

  Future<bool> submit(ReviewRating rating) async {
    final current = state.value;
    final card = current?.currentCard;
    if (_submitInFlight ||
        current == null ||
        card == null ||
        !current.isAnswerVisible ||
        current.submitError != null) {
      return false;
    }

    _submitInFlight = true;
    state = AsyncData(
      current.copyWith(isSubmitting: true, clearSubmitError: true),
    );
    try {
      final result = await _repository.submitResult(
        reviewCardId: card.reviewCardId,
        quality: rating.quality,
      );
      if (result.reviewCardId != card.reviewCardId ||
          result.qualitySubmitted != rating.quality) {
        throw const UnknownError(
          message: 'The review result identity did not match the request.',
        );
      }

      final cards = <DailyReviewCard>[...current.cards];
      if (result.shouldRepeatInSession) cards.add(card);
      state = AsyncData(
        current.copyWith(
          cards: cards,
          currentIndex: current.currentIndex + 1,
          isAnswerVisible: false,
          responses: <DailyReviewResponse>[
            ...current.responses,
            DailyReviewResponse(
              reviewCardId: card.reviewCardId,
              rating: rating,
            ),
          ],
          isSubmitting: false,
          clearSubmitError: true,
        ),
      );
      return true;
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          submitError: error is ApiError ? error : const UnknownError(),
        ),
      );
      return false;
    } finally {
      _submitInFlight = false;
    }
  }
}

class DailyReviewState {
  const DailyReviewState({
    required this.cards,
    this.currentIndex = 0,
    this.isAnswerVisible = false,
    this.responses = const <DailyReviewResponse>[],
    this.isSubmitting = false,
    this.submitError,
  });

  final List<DailyReviewCard> cards;
  final int currentIndex;
  final bool isAnswerVisible;
  final List<DailyReviewResponse> responses;
  final bool isSubmitting;
  final ApiError? submitError;

  DailyReviewCard? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;

  bool get isComplete => cards.isNotEmpty && currentIndex >= cards.length;

  int get reviewedCount => responses.length;

  int count(ReviewRating rating) =>
      responses.where((response) => response.rating == rating).length;

  DailyReviewState copyWith({
    List<DailyReviewCard>? cards,
    int? currentIndex,
    bool? isAnswerVisible,
    List<DailyReviewResponse>? responses,
    bool? isSubmitting,
    ApiError? submitError,
    bool clearSubmitError = false,
  }) {
    return DailyReviewState(
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isAnswerVisible: isAnswerVisible ?? this.isAnswerVisible,
      responses: responses ?? this.responses,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
    );
  }
}
