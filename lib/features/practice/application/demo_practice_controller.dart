import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/practice/data/fixture_demo_practice_repository.dart';
import 'package:rikipath_mobile/features/practice/data/persistent_practice_session_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice_repository.dart';
import 'package:rikipath_mobile/features/practice/domain/practice_session_repository.dart';

final demoPracticeRepositoryProvider = Provider<DemoPracticeRepository>(
  (ref) => const FixtureDemoPracticeRepository(),
);

final practiceSessionRepositoryProvider = Provider<PracticeSessionRepository>(
  (ref) => PersistentPracticeSessionRepository(
    ref.watch(jsonPreferenceStoreProvider),
  ),
);

final practiceNowProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final demoPracticeControllerProvider =
    AsyncNotifierProvider<DemoPracticeController, DemoPracticeState>(
      DemoPracticeController.new,
    );

class DemoPracticeController extends AsyncNotifier<DemoPracticeState> {
  int _attemptSequence = 0;

  DemoPracticeRepository get _repository =>
      ref.read(demoPracticeRepositoryProvider);

  PracticeSessionRepository get _sessionRepository =>
      ref.read(practiceSessionRepositoryProvider);

  DateTime get _now => ref.read(practiceNowProvider)().toUtc();

  @override
  Future<DemoPracticeState> build() async {
    final (reviewQueue, mockTest, plans, slots) = await (
      _repository.loadReviewQueue(),
      _repository.loadMockTest(),
      _repository.loadMentorPlans(),
      _repository.loadMentorSlots(),
    ).wait;

    var sessions = DemoPracticeSessions(
      reviewSession: DemoReviewSession(cards: reviewQueue),
    );
    var persistenceStatus = LocalPersistenceStatus.available;
    try {
      sessions =
          await _sessionRepository.load(
            reviewCards: reviewQueue,
            mockTest: mockTest,
          ) ??
          sessions;
    } on FormatException {
      try {
        await _sessionRepository.reset();
      } catch (_) {
        persistenceStatus = LocalPersistenceStatus.unavailable;
      }
    } catch (_) {
      persistenceStatus = LocalPersistenceStatus.unavailable;
    }

    var activeAttempt = sessions.activeMockAttempt;
    var recentAttempt = sessions.recentMockAttempt;
    var shouldPersistFinalization = false;
    if (activeAttempt?.isExpiredAt(_now) ?? false) {
      activeAttempt = _finishAttempt(activeAttempt!);
      recentAttempt = activeAttempt;
      shouldPersistFinalization = true;
    } else if (activeAttempt?.status == DemoMockSessionStatus.submitted) {
      recentAttempt = activeAttempt;
    }

    final restored = DemoPracticeState(
      reviewSession: sessions.reviewSession,
      mockTest: mockTest,
      mockAttempt: activeAttempt,
      recentMockAttempt: recentAttempt,
      mentorPlans: plans,
      mentorSlots: slots,
      persistenceStatus: persistenceStatus,
    );
    if (shouldPersistFinalization &&
        persistenceStatus == LocalPersistenceStatus.available) {
      try {
        await _sessionRepository.save(_sessionsFrom(restored));
      } catch (_) {
        return restored.copyWith(
          persistenceStatus: LocalPersistenceStatus.unavailable,
        );
      }
    }
    return restored;
  }

  Future<void> retry() async {
    state = const AsyncLoading<DemoPracticeState>();
    state = await AsyncValue.guard(build);
  }

  Future<void> revealReviewAnswer() async {
    final current = state.value;
    if (current == null || current.isReviewComplete) return;
    await _commit(
      current.copyWith(
        reviewSession: current.reviewSession.copyWith(isAnswerVisible: true),
      ),
    );
  }

  Future<void> answerReview(DemoReviewAnswer answer) async {
    final current = state.value;
    final card = current?.currentReviewCard;
    if (current == null || card == null || !current.isReviewAnswerVisible) {
      return;
    }
    await _commit(
      current.copyWith(
        reviewSession: current.reviewSession.copyWith(
          currentIndex: current.reviewIndex + 1,
          isAnswerVisible: false,
          responses: <DemoReviewResponse>[
            ...current.reviewSession.responses,
            DemoReviewResponse(cardKey: card.id, answer: answer),
          ],
        ),
      ),
    );
  }

  Future<void> restartReview() async {
    final current = state.value;
    if (current == null) return;
    await _commit(
      current.copyWith(
        reviewSession: DemoReviewSession(cards: current.reviewQueue),
      ),
    );
  }

  Future<void> startMockTest() async {
    final current = state.value;
    if (current == null || current.hasActiveMockAttempt) return;
    final startedAt = _now;
    var localAttemptKey =
        'local_${current.mockTest.id}_${startedAt.microsecondsSinceEpoch}_${_attemptSequence++}';
    while (localAttemptKey == current.recentMockAttempt?.localAttemptKey) {
      localAttemptKey =
          'local_${current.mockTest.id}_${startedAt.microsecondsSinceEpoch}_${_attemptSequence++}';
    }
    final attempt = DemoMockAttempt(
      testKey: current.mockTest.id,
      localAttemptKey: localAttemptKey,
      startedAt: startedAt,
      timeLimitMinutes: current.mockTest.timeLimitMinutes,
      status: DemoMockSessionStatus.inProgress,
    );
    await _commit(current.copyWith(mockAttempt: attempt));
  }

  Future<void> showMockQuestion(int index) async {
    final current = state.value;
    final attempt = current?.mockAttempt;
    if (current == null ||
        attempt == null ||
        attempt.status != DemoMockSessionStatus.inProgress) {
      return;
    }
    await _commit(
      current.copyWith(
        mockAttempt: attempt.copyWith(
          currentQuestionIndex: index.clamp(
            0,
            current.mockTest.questions.length - 1,
          ),
        ),
      ),
    );
  }

  Future<void> selectMockAnswer(String questionId, String optionId) async {
    final current = state.value;
    final attempt = current?.mockAttempt;
    if (current == null ||
        attempt == null ||
        attempt.status != DemoMockSessionStatus.inProgress) {
      return;
    }
    final question = current.mockTest.questions
        .where((candidate) => candidate.id == questionId)
        .firstOrNull;
    if (question == null ||
        !question.options.any((option) => option.id == optionId)) {
      return;
    }
    await _commit(
      current.copyWith(
        mockAttempt: attempt.copyWith(
          answers: <String, String>{...attempt.answers, questionId: optionId},
        ),
      ),
    );
  }

  Future<void> submitMockTest() async {
    final current = state.value;
    final attempt = current?.mockAttempt;
    if (current == null ||
        attempt == null ||
        attempt.status != DemoMockSessionStatus.inProgress) {
      return;
    }
    final submitted = _finishAttempt(attempt);
    await _commit(
      current.copyWith(mockAttempt: submitted, recentMockAttempt: submitted),
    );
  }

  Future<bool> finalizeExpiredMockTest() async {
    final current = state.value;
    final attempt = current?.mockAttempt;
    if (current == null || attempt == null || !attempt.isExpiredAt(_now)) {
      return false;
    }
    final submitted = _finishAttempt(attempt);
    await _commit(
      current.copyWith(mockAttempt: submitted, recentMockAttempt: submitted),
    );
    return true;
  }

  Future<void> prepareMockRetake() async {
    final current = state.value;
    if (current == null || current.mockResultAttempt == null) return;
    await _commit(current.copyWith(clearMockAttempt: true));
  }

  Future<void> resetMockTest() => prepareMockRetake();

  Future<void> submitAiGrading(String text) async {
    final current = state.value;
    if (current == null ||
        current.gradingStatus == DemoGradingStatus.processing) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        gradingStatus: DemoGradingStatus.processing,
        clearGradingResult: true,
      ),
    );
    try {
      final result = await _repository.gradeSubmission(text);
      state = AsyncData(
        state.requireValue.copyWith(
          gradingStatus: DemoGradingStatus.completed,
          gradingResult: result,
        ),
      );
    } catch (_) {
      state = AsyncData(
        state.requireValue.copyWith(gradingStatus: DemoGradingStatus.failed),
      );
    }
  }

  void beginDemoCheckout() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(bookingStatus: DemoBookingStatus.checkout),
    );
  }

  void confirmDemoBooking() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(bookingStatus: DemoBookingStatus.confirmed),
    );
  }

  DemoMockAttempt _finishAttempt(DemoMockAttempt attempt) {
    return attempt.copyWith(
      status: DemoMockSessionStatus.submitted,
      submittedAt: _now,
    );
  }

  Future<void> _commit(DemoPracticeState next) async {
    state = AsyncData(next);
    try {
      await _sessionRepository.save(_sessionsFrom(next));
    } catch (_) {
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(
          latest.copyWith(
            persistenceStatus: LocalPersistenceStatus.unavailable,
          ),
        );
      }
    }
  }

  DemoPracticeSessions _sessionsFrom(DemoPracticeState value) {
    return DemoPracticeSessions(
      reviewSession: value.reviewSession,
      activeMockAttempt: value.mockAttempt,
      recentMockAttempt: value.recentMockAttempt,
    );
  }
}

class DemoPracticeState {
  const DemoPracticeState({
    required this.reviewSession,
    required this.mockTest,
    required this.mentorPlans,
    required this.mentorSlots,
    this.mockAttempt,
    this.recentMockAttempt,
    this.gradingStatus = DemoGradingStatus.idle,
    this.gradingResult,
    this.bookingStatus = DemoBookingStatus.idle,
    this.persistenceStatus = LocalPersistenceStatus.available,
  });

  final DemoReviewSession reviewSession;
  final DemoMockTest mockTest;
  final DemoMockAttempt? mockAttempt;
  final DemoMockAttempt? recentMockAttempt;
  final DemoGradingStatus gradingStatus;
  final DemoAiGradingResult? gradingResult;
  final List<DemoMentorPlan> mentorPlans;
  final List<DemoMentorSlot> mentorSlots;
  final DemoBookingStatus bookingStatus;
  final LocalPersistenceStatus persistenceStatus;

  List<DemoReviewCard> get reviewQueue => reviewSession.cards;

  int get reviewIndex => reviewSession.currentIndex;

  bool get isReviewAnswerVisible => reviewSession.isAnswerVisible;

  List<DemoReviewAnswer> get reviewAnswers => reviewSession.responses
      .map((response) => response.answer)
      .toList(growable: false);

  DemoReviewCard? get currentReviewCard => reviewSession.currentCard;

  bool get isReviewComplete => reviewSession.isComplete;

  bool get hasActiveMockAttempt =>
      mockAttempt?.status == DemoMockSessionStatus.inProgress;

  bool get hasRecentMockResult => mockResultAttempt != null;

  DemoMockAttempt? get mockResultAttempt {
    if (mockAttempt?.status == DemoMockSessionStatus.submitted) {
      return mockAttempt;
    }
    return recentMockAttempt?.status == DemoMockSessionStatus.submitted
        ? recentMockAttempt
        : null;
  }

  DemoMockSessionStatus get mockSessionStatus {
    if (mockAttempt != null) return mockAttempt!.status;
    return hasRecentMockResult
        ? DemoMockSessionStatus.submitted
        : DemoMockSessionStatus.notStarted;
  }

  Map<String, String> get mockAnswers =>
      (mockAttempt ?? mockResultAttempt)?.answers ?? const <String, String>{};

  DemoMockResult? get mockResult {
    final attempt = mockResultAttempt;
    if (attempt == null) return null;
    return DemoMockResult.calculate(mockTest, attempt.answers);
  }

  int get currentMockQuestionIndex => mockAttempt?.currentQuestionIndex ?? 0;

  DateTime? get mockDeadline =>
      hasActiveMockAttempt ? mockAttempt!.deadline : null;

  DemoMockQuestion get currentMockQuestion =>
      mockTest.questions[currentMockQuestionIndex];

  int get answeredQuestionCount =>
      hasActiveMockAttempt ? mockAttempt!.answers.length : 0;

  Duration remainingMockTime(DateTime now) =>
      hasActiveMockAttempt ? mockAttempt!.remainingAt(now) : Duration.zero;

  DemoPracticeState copyWith({
    DemoReviewSession? reviewSession,
    DemoMockAttempt? mockAttempt,
    bool clearMockAttempt = false,
    DemoMockAttempt? recentMockAttempt,
    bool clearRecentMockAttempt = false,
    DemoGradingStatus? gradingStatus,
    DemoAiGradingResult? gradingResult,
    bool clearGradingResult = false,
    DemoBookingStatus? bookingStatus,
    LocalPersistenceStatus? persistenceStatus,
  }) {
    return DemoPracticeState(
      reviewSession: reviewSession ?? this.reviewSession,
      mockTest: mockTest,
      mockAttempt: clearMockAttempt ? null : mockAttempt ?? this.mockAttempt,
      recentMockAttempt: clearRecentMockAttempt
          ? null
          : recentMockAttempt ?? this.recentMockAttempt,
      mentorPlans: mentorPlans,
      mentorSlots: mentorSlots,
      gradingStatus: gradingStatus ?? this.gradingStatus,
      gradingResult: clearGradingResult
          ? null
          : gradingResult ?? this.gradingResult,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      persistenceStatus: persistenceStatus ?? this.persistenceStatus,
    );
  }
}
