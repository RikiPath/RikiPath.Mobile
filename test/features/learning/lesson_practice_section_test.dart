import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_practice_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_practice.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_practice_section.dart';

void main() {
  testWidgets('learner can answer a real-ID Practice Exercise once', (
    tester,
  ) async {
    final repository = _PracticeRepository();
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey<String>('practice_start_801')));
    await tester.pumpAndSettle();
    expect(repository.startedIds, <int>[801]);
    expect(
      find.byKey(const ValueKey<String>('lesson_practice_attempt_sheet')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('practice_option_1001_1102')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('practice_submit_button')),
    );
    await tester.pumpAndSettle();

    expect(repository.submittedAttemptIds, <int>[901]);
    expect(repository.submittedAnswers.single, <int, int>{1001: 1102});
    expect(find.textContaining('Kết quả: 100%'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('practice_submit_button')),
      findsNothing,
    );
  });

  testWidgets('lesson with no exercises shows truthful empty state', (
    tester,
  ) async {
    final repository = _PracticeRepository(exercises: const []);
    await _pump(tester, repository);

    expect(find.text('Bài học này chưa có bài luyện tập.'), findsOneWidget);
    expect(find.text('Làm bài luyện tập'), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester, _PracticeRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lessonPracticeRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonPracticeSection(lessonId: 709),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PracticeRepository implements LessonPracticeRepository {
  _PracticeRepository({
    this.exercises = const [
      LessonPracticeExercise(
        id: 801,
        lessonId: 709,
        title: 'Ôn ngữ pháp',
        questionCount: 1,
      ),
    ],
  });

  final List<LessonPracticeExercise> exercises;
  final List<int> startedIds = [];
  final List<int> submittedAttemptIds = [];
  final List<Map<int, int>> submittedAnswers = [];

  @override
  Future<List<LessonPracticeExercise>> loadForLesson(int lessonId) async {
    expect(lessonId, 709);
    return exercises;
  }

  @override
  Future<LessonPracticeAttempt> start(int exerciseId) async {
    startedIds.add(exerciseId);
    return const LessonPracticeAttempt(
      attemptId: 901,
      exerciseId: 801,
      title: 'Ôn ngữ pháp',
      questions: [
        LessonPracticeQuestion(
          id: 1001,
          text: 'Chọn đáp án',
          options: [
            LessonPracticeOption(id: 1101, text: 'A'),
            LessonPracticeOption(id: 1102, text: 'B'),
          ],
        ),
      ],
      savedOptionIds: {},
      savedTextAnswers: {},
    );
  }

  @override
  Future<LessonPracticeResult> submit({
    required int attemptId,
    required Map<int, int> selectedOptionIds,
    required Map<int, String> textAnswers,
  }) async {
    submittedAttemptIds.add(attemptId);
    submittedAnswers.add(selectedOptionIds);
    return const LessonPracticeResult(
      attemptId: 901,
      scorePercent: 100,
      correctCount: 1,
      gradedQuestions: 1,
      totalQuestions: 1,
    );
  }
}
