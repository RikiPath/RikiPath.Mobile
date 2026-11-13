import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/application/lesson_practice_controller.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson_practice.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_content_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_completion_view.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_detail_view.dart';

void main() {
  testWidgets(
    'live study screen renders returned vocabulary and kanji without fabricated duration or parts',
    (tester) async {
      await tester.pumpWidget(_app(_liveLesson()));

      expect(find.text('山'), findsNWidgets(2));
      expect(find.text('mountain'), findsNWidgets(2));
      expect(find.text('やま'), findsOneWidget);
      expect(find.text('Phần 1 / 0'), findsNothing);
      expect(find.textContaining('0 phút'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('lesson_materials_unavailable')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'live study screen states when Backend returned no learning materials',
    (tester) async {
      await tester.pumpWidget(_app(_liveLesson(withMaterials: false)));

      expect(
        find.byKey(const ValueKey<String>('lesson_materials_unavailable')),
        findsOneWidget,
      );
    },
  );

  testWidgets('live lesson does not display unverified XP or streak', (
    tester,
  ) async {
    final lesson = _liveLesson();
    await tester.pumpWidget(
      _host(
        LessonDetailView(
          lesson: lesson,
          onStart: () {},
          onToggleBookmark: (_) {},
          onToggleKanji: (_) {},
          onToggleGrammar: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+0 XP'), findsNothing);

    await tester.pumpWidget(
      _host(
        LessonCompletionView(
          lesson: lesson,
          onNextLesson: null,
          onBackToRoadmap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+0 XP'), findsNothing);
  });
}

Widget _app(Lesson lesson) => _host(
  LessonArticleOnlyView(
    lesson: lesson,
    onOpenVideo: () {},
    onToggleBookmark: (_) {},
    onToggleKanji: (_) {},
    onToggleGrammar: (_) {},
    onComplete: () {},
    isCompleting: false,
    completionErrorMessage: null,
  ),
);

Widget _host(Widget body) => ProviderScope(
  overrides: [
    lessonPracticeRepositoryProvider.overrideWithValue(
      _EmptyPracticeRepository(),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: body),
  ),
);

class _EmptyPracticeRepository implements LessonPracticeRepository {
  @override
  Future<List<LessonPracticeExercise>> loadForLesson(int lessonId) async => [];

  @override
  Future<LessonPracticeAttempt> start(int exerciseId) =>
      throw UnimplementedError();

  @override
  Future<LessonPracticeResult> submit({
    required int attemptId,
    required Map<int, int> selectedOptionIds,
    required Map<int, String> textAnswers,
  }) => throw UnimplementedError();
}

Lesson _liveLesson({bool withMaterials = true}) => Lesson(
  routeId: '1',
  remoteLessonId: 1,
  title: 'Bài 1: Chào hỏi & Hán tự',
  focus: 'Vocabulary',
  level: JlptLevel.n5,
  category: 'Vocabulary',
  curriculum: 'JLPT N5',
  chapterNumber: 0,
  lessonNumber: 1,
  durationSeconds: 0,
  objective: 'Bài học mở đầu về các câu chào hỏi cơ bản',
  parts: const <LessonPart>[],
  vocabulary: withMaterials
      ? const <LessonVocabularyItem>[
          LessonVocabularyItem(
            vocabularyId: 1,
            word: '山',
            reading: 'やま',
            meaning: 'mountain',
            isSaved: false,
          ),
        ]
      : const <LessonVocabularyItem>[],
  kanji: withMaterials
      ? const <LessonKanjiItem>[
          LessonKanjiItem(
            kanjiId: 910001,
            character: '山',
            meaning: 'mountain',
            isSaved: false,
          ),
        ]
      : const <LessonKanjiItem>[],
  detailVocabularyCount: withMaterials ? 1 : 0,
  videoVocabularyCount: 0,
  relatedGrammar: const <LessonRelatedGrammar>[],
  article: const LessonArticle(
    formulas: <String>[],
    meaning: '',
    usageSteps: <String>[],
    examples: <LessonExample>[],
    importantNotes: <String>[],
  ),
  progress: const LessonProgress(
    progressPercent: 0,
    resumePositionSeconds: 0,
    isCompleted: false,
  ),
  availability: LessonAvailability.available,
  noteCount: 0,
  streakDays: 0,
  detailXp: 0,
  completionXp: 0,
  masteryItems: const <LessonMasteryItem>[],
  mediaSource: const LessonMediaSource.none(),
);
