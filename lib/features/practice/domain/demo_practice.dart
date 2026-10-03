enum DemoReviewAnswer { again, hard, good, easy }

enum DemoGradingStatus { idle, processing, completed, failed }

enum DemoBookingStatus { idle, checkout, confirmed }

enum DemoMockSessionStatus { notStarted, inProgress, submitted }

class DemoReviewResponse {
  const DemoReviewResponse({required this.cardKey, required this.answer});

  final String cardKey;
  final DemoReviewAnswer answer;
}

class DemoReviewSession {
  const DemoReviewSession({
    required this.cards,
    this.currentIndex = 0,
    this.isAnswerVisible = false,
    this.responses = const <DemoReviewResponse>[],
  });

  final List<DemoReviewCard> cards;
  final int currentIndex;
  final bool isAnswerVisible;
  final List<DemoReviewResponse> responses;

  DemoReviewCard? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;

  bool get isComplete => currentIndex >= cards.length;

  int get reviewedCount => responses.length;

  int get remainingCount =>
      (cards.length - currentIndex).clamp(0, cards.length);

  int count(DemoReviewAnswer answer) =>
      responses.where((response) => response.answer == answer).length;

  DemoReviewSession copyWith({
    int? currentIndex,
    bool? isAnswerVisible,
    List<DemoReviewResponse>? responses,
  }) {
    return DemoReviewSession(
      cards: cards,
      currentIndex: currentIndex ?? this.currentIndex,
      isAnswerVisible: isAnswerVisible ?? this.isAnswerVisible,
      responses: responses ?? this.responses,
    );
  }
}

class DemoReviewCard {
  const DemoReviewCard({
    required this.id,
    required this.term,
    required this.reading,
    required this.meaning,
    required this.contentType,
  });

  final String id;
  final String term;
  final String? reading;
  final String meaning;
  final String contentType;
}

class DemoMockQuestion {
  const DemoMockQuestion({
    required this.id,
    required this.section,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    required this.explanation,
  });

  final String id;
  final String section;
  final String prompt;
  final List<DemoMockOption> options;
  final String correctOptionId;
  final String explanation;
}

class DemoMockOption {
  const DemoMockOption({required this.id, required this.label});

  final String id;
  final String label;
}

class DemoMockTest {
  const DemoMockTest({
    required this.id,
    required this.title,
    required this.level,
    required this.timeLimitMinutes,
    required this.questions,
  });

  final String id;
  final String title;
  final String level;
  final int timeLimitMinutes;
  final List<DemoMockQuestion> questions;
}

class DemoMockAttempt {
  const DemoMockAttempt({
    required this.testKey,
    required this.localAttemptKey,
    required this.startedAt,
    required this.timeLimitMinutes,
    required this.status,
    this.answers = const <String, String>{},
    this.currentQuestionIndex = 0,
    this.submittedAt,
  });

  final String testKey;
  final String localAttemptKey;
  final DateTime startedAt;
  final int timeLimitMinutes;
  final Map<String, String> answers;
  final int currentQuestionIndex;
  final DateTime? submittedAt;
  final DemoMockSessionStatus status;

  DateTime get deadline => startedAt.add(Duration(minutes: timeLimitMinutes));

  Duration remainingAt(DateTime now) {
    final remaining = deadline.difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpiredAt(DateTime now) =>
      status == DemoMockSessionStatus.inProgress &&
      !deadline.isAfter(now.toUtc());

  DemoMockAttempt copyWith({
    Map<String, String>? answers,
    int? currentQuestionIndex,
    DateTime? submittedAt,
    DemoMockSessionStatus? status,
  }) {
    return DemoMockAttempt(
      testKey: testKey,
      localAttemptKey: localAttemptKey,
      startedAt: startedAt,
      timeLimitMinutes: timeLimitMinutes,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
    );
  }
}

class DemoMockResult {
  const DemoMockResult({
    required this.score,
    required this.total,
    required this.sectionScores,
    required this.sectionTotals,
  });

  final int score;
  final int total;
  final Map<String, int> sectionScores;
  final Map<String, int> sectionTotals;

  int get percentage => total == 0 ? 0 : (score * 100 / total).round();

  int sectionPercentage(String section) {
    final sectionTotal = sectionTotals[section] ?? 0;
    if (sectionTotal == 0) return 0;
    return ((sectionScores[section] ?? 0) * 100 / sectionTotal).round();
  }

  factory DemoMockResult.calculate(
    DemoMockTest test,
    Map<String, String> answers,
  ) {
    var score = 0;
    final sectionScores = <String, int>{};
    final sectionTotals = <String, int>{};
    for (final question in test.questions) {
      sectionTotals.update(
        question.section,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      final isCorrect = answers[question.id] == question.correctOptionId;
      if (isCorrect) score++;
      sectionScores.update(
        question.section,
        (value) => value + (isCorrect ? 1 : 0),
        ifAbsent: () => isCorrect ? 1 : 0,
      );
    }
    return DemoMockResult(
      score: score,
      total: test.questions.length,
      sectionScores: sectionScores,
      sectionTotals: sectionTotals,
    );
  }
}

class DemoPracticeSessions {
  const DemoPracticeSessions({
    required this.reviewSession,
    this.activeMockAttempt,
    this.recentMockAttempt,
  });

  final DemoReviewSession reviewSession;
  final DemoMockAttempt? activeMockAttempt;
  final DemoMockAttempt? recentMockAttempt;
}

class DemoAiGradingResult {
  const DemoAiGradingResult({required this.score, required this.feedback});

  final int score;
  final String feedback;
}

class DemoMentorPlan {
  const DemoMentorPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceLabel,
  });

  final String id;
  final String name;
  final String description;
  final String priceLabel;
}

class DemoMentorSlot {
  const DemoMentorSlot({
    required this.id,
    required this.mentorName,
    required this.timeLabel,
  });

  final String id;
  final String mentorName;
  final String timeLabel;
}
