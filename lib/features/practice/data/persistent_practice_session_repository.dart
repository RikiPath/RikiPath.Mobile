import 'dart:convert';

import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/practice/domain/demo_practice.dart';
import 'package:rikipath_mobile/features/practice/domain/practice_session_repository.dart';

class PersistentPracticeSessionRepository implements PracticeSessionRepository {
  PersistentPracticeSessionRepository(this._store);

  static const storageKey = 'r3_2_practice_sessions_v1';

  final JsonPreferenceStore _store;

  @override
  Future<DemoPracticeSessions?> load({
    required List<DemoReviewCard> reviewCards,
    required DemoMockTest mockTest,
  }) async {
    final encoded = await _store.read(storageKey);
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Practice sessions must be a JSON object.');
    }

    final reviewSession = _decodeReviewSession(
      decoded['reviewSession'],
      reviewCards,
    );
    final activeMockAttempt = _decodeMockAttempt(
      decoded['activeMockAttempt'],
      mockTest,
      allowInProgress: true,
    );
    final recentMockAttempt = _decodeMockAttempt(
      decoded['recentMockAttempt'],
      mockTest,
      allowInProgress: false,
    );
    return DemoPracticeSessions(
      reviewSession: reviewSession ?? DemoReviewSession(cards: reviewCards),
      activeMockAttempt: activeMockAttempt,
      recentMockAttempt: recentMockAttempt,
    );
  }

  @override
  Future<void> save(DemoPracticeSessions sessions) {
    final encoded = jsonEncode(<String, Object?>{
      'reviewSession': _encodeReviewSession(sessions.reviewSession),
      'activeMockAttempt': _encodeMockAttempt(sessions.activeMockAttempt),
      'recentMockAttempt': _encodeMockAttempt(sessions.recentMockAttempt),
    });
    return _store.write(storageKey, encoded);
  }

  @override
  Future<void> reset() => _store.remove(storageKey);

  DemoReviewSession? _decodeReviewSession(
    Object? encoded,
    List<DemoReviewCard> cards,
  ) {
    if (encoded == null) return null;
    if (encoded is! Map<String, dynamic>) {
      throw const FormatException('Review session must be an object.');
    }
    final cardKeys = encoded['cardKeys'];
    final currentIndex = encoded['currentIndex'];
    final isAnswerVisible = encoded['isAnswerVisible'];
    final encodedResponses = encoded['responses'];
    if (cardKeys is! List<dynamic> ||
        currentIndex is! int ||
        isAnswerVisible is! bool ||
        encodedResponses is! List<dynamic>) {
      throw const FormatException('Review session fields are invalid.');
    }
    final expectedKeys = cards.map((card) => card.id).toList(growable: false);
    final restoredKeys = cardKeys.whereType<String>().toList(growable: false);
    if (restoredKeys.length != cardKeys.length ||
        !_sameList(expectedKeys, restoredKeys) ||
        currentIndex < 0 ||
        currentIndex > cards.length ||
        (currentIndex >= cards.length && isAnswerVisible)) {
      throw const FormatException('Review session does not match the queue.');
    }

    final responses = <DemoReviewResponse>[];
    for (final item in encodedResponses) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Review response must be an object.');
      }
      final cardKey = item['cardKey'];
      final answerName = item['answer'];
      final answer = DemoReviewAnswer.values
          .where((value) => value.name == answerName)
          .firstOrNull;
      if (cardKey is! String ||
          !expectedKeys.contains(cardKey) ||
          answer == null) {
        throw const FormatException('Review response fields are invalid.');
      }
      responses.add(DemoReviewResponse(cardKey: cardKey, answer: answer));
    }
    if (responses.length != currentIndex ||
        responses.asMap().entries.any(
          (entry) => entry.value.cardKey != expectedKeys[entry.key],
        )) {
      throw const FormatException('Review responses are out of sequence.');
    }
    return DemoReviewSession(
      cards: cards,
      currentIndex: currentIndex,
      isAnswerVisible: isAnswerVisible,
      responses: responses,
    );
  }

  DemoMockAttempt? _decodeMockAttempt(
    Object? encoded,
    DemoMockTest test, {
    required bool allowInProgress,
  }) {
    if (encoded == null) return null;
    if (encoded is! Map<String, dynamic>) {
      throw const FormatException('Mock attempt must be an object.');
    }
    final testKey = encoded['testKey'];
    final localAttemptKey = encoded['localAttemptKey'];
    final startedAtValue = encoded['startedAt'];
    final timeLimitMinutes = encoded['timeLimitMinutes'];
    final statusName = encoded['status'];
    final currentQuestionIndex = encoded['currentQuestionIndex'];
    final submittedAtValue = encoded['submittedAt'];
    final encodedAnswers = encoded['answers'];
    final status = DemoMockSessionStatus.values
        .where((value) => value.name == statusName)
        .firstOrNull;
    final startedAt = startedAtValue is String
        ? DateTime.tryParse(startedAtValue)?.toUtc()
        : null;
    final submittedAt = submittedAtValue is String
        ? DateTime.tryParse(submittedAtValue)?.toUtc()
        : null;
    if (testKey != test.id ||
        localAttemptKey is! String ||
        !localAttemptKey.startsWith('local_') ||
        startedAt == null ||
        timeLimitMinutes != test.timeLimitMinutes ||
        status == null ||
        status == DemoMockSessionStatus.notStarted ||
        (!allowInProgress && status != DemoMockSessionStatus.submitted) ||
        currentQuestionIndex is! int ||
        currentQuestionIndex < 0 ||
        currentQuestionIndex >= test.questions.length ||
        encodedAnswers is! Map<String, dynamic> ||
        (status == DemoMockSessionStatus.submitted && submittedAt == null) ||
        (status == DemoMockSessionStatus.inProgress && submittedAt != null)) {
      throw const FormatException('Mock attempt fields are invalid.');
    }

    final questions = <String, DemoMockQuestion>{
      for (final question in test.questions) question.id: question,
    };
    final answers = <String, String>{};
    for (final entry in encodedAnswers.entries) {
      final optionId = entry.value;
      final question = questions[entry.key];
      if (optionId is! String ||
          question == null ||
          !question.options.any((option) => option.id == optionId)) {
        throw const FormatException('Mock answer fields are invalid.');
      }
      answers[entry.key] = optionId;
    }
    return DemoMockAttempt(
      testKey: testKey as String,
      localAttemptKey: localAttemptKey,
      startedAt: startedAt,
      timeLimitMinutes: timeLimitMinutes as int,
      status: status,
      answers: answers,
      currentQuestionIndex: currentQuestionIndex,
      submittedAt: submittedAt,
    );
  }

  Map<String, Object?> _encodeReviewSession(DemoReviewSession session) {
    return <String, Object?>{
      'cardKeys': session.cards.map((card) => card.id).toList(growable: false),
      'currentIndex': session.currentIndex,
      'isAnswerVisible': session.isAnswerVisible,
      'responses': session.responses
          .map(
            (response) => <String, Object>{
              'cardKey': response.cardKey,
              'answer': response.answer.name,
            },
          )
          .toList(growable: false),
    };
  }

  Map<String, Object?>? _encodeMockAttempt(DemoMockAttempt? attempt) {
    if (attempt == null) return null;
    return <String, Object?>{
      'testKey': attempt.testKey,
      'localAttemptKey': attempt.localAttemptKey,
      'startedAt': attempt.startedAt.toUtc().toIso8601String(),
      'timeLimitMinutes': attempt.timeLimitMinutes,
      'status': attempt.status.name,
      'answers': attempt.answers,
      'currentQuestionIndex': attempt.currentQuestionIndex,
      'submittedAt': attempt.submittedAt?.toUtc().toIso8601String(),
    };
  }

  bool _sameList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
