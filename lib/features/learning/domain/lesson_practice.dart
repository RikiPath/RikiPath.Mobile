class LessonPracticeExercise {
  const LessonPracticeExercise({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.questionCount,
    this.description,
    this.bestScorePercent,
  });

  final int id;
  final int lessonId;
  final String title;
  final String? description;
  final int questionCount;
  final double? bestScorePercent;
}

class LessonPracticeOption {
  const LessonPracticeOption({required this.id, required this.text});

  final int id;
  final String text;
}

class LessonPracticeQuestion {
  const LessonPracticeQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  final int id;
  final String text;
  final List<LessonPracticeOption> options;
}

class LessonPracticeAttempt {
  const LessonPracticeAttempt({
    required this.attemptId,
    required this.exerciseId,
    required this.title,
    required this.questions,
    required this.savedOptionIds,
    required this.savedTextAnswers,
    this.resumed = false,
  });

  final int attemptId;
  final int exerciseId;
  final String title;
  final List<LessonPracticeQuestion> questions;
  final Map<int, int> savedOptionIds;
  final Map<int, String> savedTextAnswers;
  final bool resumed;
}

class LessonPracticeResult {
  const LessonPracticeResult({
    required this.attemptId,
    required this.scorePercent,
    required this.correctCount,
    required this.gradedQuestions,
    required this.totalQuestions,
  });

  final int attemptId;
  final double scorePercent;
  final int correctCount;
  final int gradedQuestions;
  final int totalQuestions;
}

abstract interface class LessonPracticeRepository {
  Future<List<LessonPracticeExercise>> loadForLesson(int lessonId);

  Future<LessonPracticeAttempt> start(int exerciseId);

  Future<LessonPracticeResult> submit({
    required int attemptId,
    required Map<int, int> selectedOptionIds,
    required Map<int, String> textAnswers,
  });
}
