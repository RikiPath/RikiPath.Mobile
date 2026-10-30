import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/lesson_content_view.dart';

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
}

Widget _app(Lesson lesson) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: LessonArticleOnlyView(
      lesson: lesson,
      onOpenVideo: () {},
      onToggleBookmark: (_) {},
      onToggleKanji: (_) {},
      onToggleGrammar: (_) {},
      onComplete: () {},
      isCompleting: false,
      completionErrorMessage: null,
    ),
  ),
);

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
